import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/widgets/detailed_walking_painter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/fitness_record.dart';
import 'package:lottie/lottie.dart';


class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  int _steps = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _dbSaveTimer; // DB 저장을 위한 타이머
  bool _isTimerActive = false;

  late AnimationController _animationController;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  Timer? _movementStopTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // 1. 데이터 로딩 함수 호출
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1020),
    )..repeat(reverse: true);
    _startTimer();
    _setupLiveMode();
    _startDbSaveTimer(); // DB 저장 타이머 시작
  }

  // 2. Hive에서 오늘 날짜의 데이터를 불러오는 함수
  void _loadInitialData() {
    final box = Hive.box<FitnessRecord>('fitness_records');
    final now = DateTime.now();
    final minuteBlock = (now.minute ~/ 10) * 10;
    final dateKey = DateFormat('yyyy-MM-dd-HH-').format(now) + minuteBlock.toString().padLeft(2, '0');
    final todayRecord = box.get(dateKey);

    if (todayRecord != null) {
      _steps = todayRecord.steps;
      _distance = todayRecord.distance;
      _calories = todayRecord.calories;
      _elapsedSeconds = todayRecord.duration;
      print('Loaded data for $dateKey: Steps: $_steps');
    }
  }

  void _setupLiveMode() {
      initPedometer();
      _startPositionTracking();
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

  // 1. 1초마다 Hive에 데이터를 저장하는 타이머 설정
  void _startDbSaveTimer() { 
    _dbSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _isTimerActive) {
        _saveRecordToHive();
      }
    });
  }

  void _saveRecordToHive() {
    final box = Hive.box<FitnessRecord>('fitness_records');
    final now = DateTime.now();

    // 2. 10분 단위로 키를 생성 (예: 14:00 ~ 14:09 -> ...-14-00, 14:10 ~ 14:19 -> ...-14-10)
    final currentMinuteBlock = (now.minute ~/ 10) * 10;
    final currentKey = DateFormat('yyyy-MM-dd-HH-').format(now) + currentMinuteBlock.toString().padLeft(2, '0');

    // 3. 이전 10분 블록의 키를 계산
    final tenMinutesAgo = now.subtract(const Duration(minutes: 10));
    final previousMinuteBlock = (tenMinutesAgo.minute ~/ 10) * 10;
    final previousKey = DateFormat('yyyy-MM-dd-HH-').format(tenMinutesAgo) + previousMinuteBlock.toString().padLeft(2, '0');

    // 4. 이전 블록의 데이터를 가져옴
    final previousRecord = box.get(previousKey);

    // 5. 현재 블록의 순수 활동량 계산 (델타 값)
    final currentSteps = _steps - (previousRecord?.steps ?? 0);
    final currentDistance = _distance - (previousRecord?.distance ?? 0.0);
    final currentDuration = _elapsedSeconds - (previousRecord?.duration ?? 0);
    final currentCalories = _calories - (previousRecord?.calories ?? 0.0);

    // 6. 순수 활동량(델타)을 저장할 레코드 생성
    final deltaRecord = FitnessRecord()
      ..date = currentKey
      ..steps = currentSteps > 0 ? currentSteps : 0
      ..distance = currentDistance > 0 ? currentDistance : 0.0
      ..duration = currentDuration > 0 ? currentDuration : 0
      ..calories = currentCalories > 0 ? currentCalories : 0.0;

    // 7. 현재 누적 데이터를 저장할 레코드 생성 (다음 계산을 위해)
    final totalRecord = FitnessRecord()
      ..date = currentKey
      ..steps = _steps
      ..distance = _distance
      ..duration = _elapsedSeconds
      ..calories = _calories;
    
    // 8. 두 종류의 데이터를 별개의 키로 저장
    box.put(currentKey + "_total", totalRecord); // 계산용 누적 데이터
    box.put(currentKey, deltaRecord); // 분석용 순수 활동량 데이터
    print('Saved delta data for key: $currentKey. Steps: ${deltaRecord.steps}');
  }

  void _updateMetrics(int steps) {
    _steps = steps;
    _distance = steps * 0.762; // Average stride length
    _calories = steps * 0.04; // Average calories per step
  }

  void initPedometer() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  void _onStepCount(StepCount event) {
    _handleMovement();
    if (!_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
    setState(() {
      _updateMetrics(event.steps);
    });
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
    // In a real device scenario, we might want to show a user-friendly error.
  }

  void _startPositionTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      // Optionally, show a dialog to the user to enable it.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    _positionSubscription = Geolocator.getPositionStream().listen((Position position) {
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude
        );
        if (distance > 1) { // More than 1 meter is movement
          _handleMovement();
        }
      }
      _lastPosition = position;
    });
  }

  void _stopPositionTracking() {
    _positionSubscription?.cancel();
    _movementStopTimer?.cancel();
  }

  void _handleMovement() {
    if (mounted && !_isTimerActive) {
      setState(() { _isTimerActive = true; });
    }
    _movementStopTimer?.cancel();
    _movementStopTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() { _isTimerActive = false; });
        _saveRecordToHive(); // 5초간 움직임이 없어 타이머가 멈출 때 저장
      }
    });
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _animationController.dispose();
    _timer?.cancel();
    _dbSaveTimer?.cancel(); // DB 저장 타이머 취소
    _saveRecordToHive(); // 화면을 나가기 직전에 마지막으로 한 번 더 저장
    _stopPositionTracking();
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
        title: const Text('Pedometer'),
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
                child: Lottie.asset(
                  'assets/lottie/walking.json',
                  controller: _animationController,
                  onLoaded: (composition) {
                    _animationController.duration = composition.duration;
                  },
                  frameRate: FrameRate.max,
                  repeat: true,
                  reverse: true,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildStatItem(Icons.location_on, (_distance / 1000).toStringAsFixed(2), 'km')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.timer, _formatDuration(_elapsedSeconds), 'Time')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(Icons.local_fire_department, _calories.toStringAsFixed(1), 'kcal')),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(unit, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
