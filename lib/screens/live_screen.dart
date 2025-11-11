
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/widgets/detailed_walking_painter.dart';

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
  bool _isTimerActive = false;

  late AnimationController _animationController;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  Timer? _movementStopTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1020),
    )..repeat(reverse: true);
    _startTimer();
    _setupLiveMode();
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
      }
    });
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _animationController.dispose();
    _timer?.cancel();
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
}
