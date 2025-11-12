
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
    final dateKey = DateTime.now().toIso8601String().substring(0, 10);
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
    final dateKey = DateTime.now().toIso8601String().substring(0, 10); // 'YYYY-MM-DD'
    final random = Random();

    // 시뮬레이션 모드에서 GPS 데이터 랜덤 이동
    final latOffset = random.nextDouble() * 0.00005 - 0.000025; // -2.5m ~ 2.5m
    final lngOffset = random.nextDouble() * 0.00005 - 0.000025;
    _currentLatitude += latOffset;
    _currentLongitude += lngOffset;

    final record = FitnessRecord()
      ..date = dateKey
      ..steps = _steps
      ..distance = _distance
      ..duration = _elapsedSeconds
      ..latitude = _currentLatitude
      ..longitude = _currentLongitude
      ..calories = _calories;

    box.put(dateKey, record);
    print('$dateKey: Simulation data saved to Hive. Steps: $_steps');
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
        _updateMetrics(_steps + 1);
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
    });
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
      ],
    );
  }
}
