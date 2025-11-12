
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/fitness_record.dart';
import 'package:myapp/widgets/detailed_walking_painter.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> with TickerProviderStateMixin {
  int _steps = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _dbSaveTimer; // DB 저장을 위한 타이머
  double _currentLatitude = 37.7749; // 기본 위도
  double _currentLongitude = -122.4194; // 기본 경도
  bool _isTimerActive = false;
  DateTime _simulationDateTime = DateTime.now(); // 1. 시뮬레이션 날짜/시간 상태 변수
  int _acceleration = 1; // 2. 가속(배율) 상태 변수

  double _simulationSpeed = 5.0;
  
  late AnimationController _animationController;
  double _previousAnimationValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // 1. 데이터 로딩 함수 호출
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1020),
    );
    _animationController.addListener(_onAnimationUpdate);
    _startTimer();
    _startDbSaveTimer(); // DB 저장 타이머 시작
    _updateAnimationDuration(); 
  }

  // 2. Hive에서 오늘 날짜의 데이터를 불러오는 함수
  void _loadInitialData() {
    final box = Hive.box<FitnessRecord>('fitness_records');
    // 10분 단위로 키를 생성하여 로드
    final minuteBlock = (_simulationDateTime.minute ~/ 10) * 10;
    final dateKey = DateFormat('yyyy-MM-dd-HH-').format(_simulationDateTime) + minuteBlock.toString().padLeft(2, '0');
    final todayRecord = box.get(dateKey);

    if (todayRecord != null) {
      _steps = todayRecord.steps;
      _distance = todayRecord.distance;
      _calories = todayRecord.calories;
      _elapsedSeconds = todayRecord.duration;
      print('Loaded data for $dateKey: Steps: $_steps');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTimerActive) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  // 15초마다 Hive에 데이터를 저장하는 타이머 설정
  void _startDbSaveTimer() { 
    _dbSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _isTimerActive) {
        _saveRecordToHive();
      }
    });
  }

  void _saveRecordToHive() {
    final box = Hive.box<FitnessRecord>('fitness_records');
    // 10분 단위로 키를 생성 (예: 14:00 ~ 14:09 -> ...-14-00, 14:10 ~ 14:19 -> ...-14-10)
    final currentMinuteBlock = (_simulationDateTime.minute ~/ 10) * 10;
    final currentKey = DateFormat('yyyy-MM-dd-HH-').format(_simulationDateTime) + currentMinuteBlock.toString().padLeft(2, '0');

    // 이전 10분 블록의 키를 계산
    final tenMinutesAgo = _simulationDateTime.subtract(const Duration(minutes: 10));
    final previousMinuteBlock = (tenMinutesAgo.minute ~/ 10) * 10;
    final previousKey = DateFormat('yyyy-MM-dd-HH-').format(tenMinutesAgo) + previousMinuteBlock.toString().padLeft(2, '0');

    // 이전 블록의 데이터를 가져옴
    final previousRecord = box.get(previousKey);

    // 현재 블록의 순수 활동량 계산 (델타 값)
    final currentSteps = _steps - (previousRecord?.steps ?? 0);
    final currentDistance = _distance - (previousRecord?.distance ?? 0.0);
    final currentDuration = _elapsedSeconds - (previousRecord?.duration ?? 0);
    final currentCalories = _calories - (previousRecord?.calories ?? 0.0);

    final random = Random();
    // 시뮬레이션 모드에서 GPS 데이터 랜덤 이동
    final latOffset = random.nextDouble() * 0.00005 - 0.000025; // -2.5m ~ 2.5m
    final lngOffset = random.nextDouble() * 0.00005 - 0.000025;
    _currentLatitude += latOffset;
    _currentLongitude += lngOffset;
    
    final record = FitnessRecord()
      ..date = currentKey
      ..steps = currentSteps > 0 ? currentSteps : 0
      ..distance = currentDistance > 0 ? currentDistance : 0.0
      ..duration = currentDuration > 0 ? currentDuration : 0
      ..latitude = _currentLatitude
      ..longitude = _currentLongitude
      ..calories = currentCalories > 0 ? currentCalories : 0.0;

    // 현재 누적 데이터를 저장 (다음 계산을 위해)
    final totalRecord = FitnessRecord()
      ..date = currentKey
      ..steps = _steps
      ..distance = _distance
      ..duration = _elapsedSeconds
      ..calories = _calories;
    box.put(currentKey, totalRecord);
    print('Saved total data for key: $currentKey. Steps: $_steps');
  }

  void _updateMetrics(int steps) {
    _steps = steps;
    _distance = steps * 0.762; // Average stride length: 0.762 meters
    _calories = steps * 0.04; // Average calories burned per step: 0.04
  }

  void _onAnimationUpdate() {
    if (!_animationController.isAnimating) return;
    final currentValue = _animationController.value;
    if ((_previousAnimationValue < 0.5 && currentValue >= 0.5) ||
        (_previousAnimationValue > 0.5 && currentValue < 0.5)) {
      setState(() { 
        _updateMetrics(_steps + (1 * _acceleration)); // 3. 걸음 수에 배율 적용
      });
    }
    _previousAnimationValue = currentValue;
  }

  void _startSimulation() {
    if (!_animationController.isAnimating) {
      setState(() { _isTimerActive = true; });
      _animationController.repeat(reverse: true);
    }
  }

  void _stopSimulation() {
    if (_animationController.isAnimating) {
      setState(() { _isTimerActive = false; });
      _animationController.stop();
      _saveRecordToHive(); // 시뮬레이션 중지 시 최종 저장
    }
  }
  
  void _updateAnimationDuration() {
      final durationMs = (1620 - (_simulationSpeed * 120)) / 2;
      _animationController.duration = Duration(milliseconds: durationMs.toInt());
      
      if(_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
  }

  void _resetSimulation() {
    setState(() {
      _steps = 0;
      _distance = 0.0;
      _calories = 0.0;
      _elapsedSeconds = 0;
      _isTimerActive = false;
      _previousAnimationValue = 0.0;
      _animationController.stop();
      _animationController.reset();
      _simulationDateTime = DateTime.now(); // 날짜/시간 초기화
      _acceleration = 1; // 배율 초기화
    });
  }

  // 4. 날짜 및 시간 선택기를 표시하는 함수
  Future<void> _selectDateTime(BuildContext context) async {
    // 현재 시뮬레이션 시간보다 이전 날짜는 선택할 수 없도록 제한
    final DateTime now = DateTime.now();
    final DateTime initialDatePickerDate = _simulationDateTime.isBefore(now) ? _simulationDateTime : now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDatePickerDate,
      firstDate: _simulationDateTime, // 현재 시뮬레이션 시간보다 이전 날짜는 선택 불가
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && context.mounted) {
      // 현재 시뮬레이션 시간보다 이전 시간은 선택할 수 없도록 제한
      final TimeOfDay initialTimePickerTime = TimeOfDay.fromDateTime(_simulationDateTime);

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTimePickerTime,
      );

      if (pickedTime != null) {
        final newSimulationDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _simulationDateTime = newSimulationDateTime);
        _loadInitialData(); // 날짜/시간 변경 후 데이터 다시 로드
      }
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationUpdate);
    _animationController.dispose();
    _timer?.cancel();
    _dbSaveTimer?.cancel(); // DB 저장 타이머 취소
    _saveRecordToHive(); // 화면을 나가기 직전에 마지막으로 한 번 더 저장
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer Simulation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSimulation,
            tooltip: 'Reset Simulation',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                width: 200,
                child: CustomPaint(
                  size: const Size(200, 250),
                  painter: DetailedWalkingPainter(
                    animation: _animationController,
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Steps Taken',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              Text(
                '$_steps',
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildStatsRow(),
              const SizedBox(height: 40),
              _buildSimulationControls(),
              const SizedBox(height: 20),
              _buildTestControls(), // 5. 테스트용 컨트롤 UI 추가
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.location_on, (_distance / 1000).toStringAsFixed(2), 'km'),
        _buildStatItem(Icons.timer, _formatDuration(_elapsedSeconds), 'Time'),
        _buildStatItem(Icons.local_fire_department, _calories.toStringAsFixed(1), 'kcal'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSimulationControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
              onPressed: _startSimulation,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              onPressed: _stopSimulation,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Slow'),
              Expanded(
                child: Slider(
                  value: _simulationSpeed,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _simulationSpeed.round().toString(),
                  onChanged: (newSpeed) {
                    setState(() {
                      _simulationSpeed = newSpeed;
                      _updateAnimationDuration();
                    });
                  },
                ),
              ),
              const Text('Fast'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 걸음 배율 슬라이더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('걸음 배율:'),
              Expanded(
                child: Slider(
                  value: _acceleration.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: 'x$_acceleration',
                  onChanged: (newAcceleration) => setState(() => _acceleration = newAcceleration.toInt()),
                ),
              ),
              Text('x$_acceleration', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // 6. 날짜/시간 및 가속도 조절을 위한 위젯
  Widget _buildTestControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 현재 시뮬레이션 시간 표시
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(_simulationDateTime),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            // 시간 조정 버튼들
            _buildTimeAdjusterRow('분 (Minute)', 1),
            _buildTimeAdjusterRow('시 (Hour)', 60),
            _buildTimeAdjusterRow('일 (Day)', 60 * 24),
          ],
        ),
      ),
    );
  }

  // 시간 단위를 조정하는 버튼 행을 만드는 헬퍼 위젯
  Widget _buildTimeAdjusterRow(String label, int minutesToAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() => _simulationDateTime = _simulationDateTime.subtract(Duration(minutes: minutesToAdd)));
                _loadInitialData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() => _simulationDateTime = _simulationDateTime.add(Duration(minutes: minutesToAdd)));
                _loadInitialData();
              },
            ),
          ],
        ),
      ],
    );
  }
}
