
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedometer App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<StepCount> _stepCountStream;
  late StreamSubscription<StepCount> _stepCountSubscription;
  int _initialSteps = 0;
  int _sessionSteps = 0;
  double _distance = 0.0;
  int _calories = 0;
  String _duration = "00:00:00";
  String? _error;
  late Stopwatch _stopwatch;
  late Timer _durationTimer;
  bool _isSimulationMode = false;
  bool _isSimulating = false;
  double _simulationSpeed = 5.0;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _duration = _formatDuration(_stopwatch.elapsed);
        });
      }
    });
    initPedometer();
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen(_onStepCount, onError: _onStepCountError);
    setState(() {
       _error = null;
    });
  }

  void _onStepCount(StepCount event) {
    if (_initialSteps == 0) {
      _initialSteps = event.steps;
      if (!_stopwatch.isRunning) _stopwatch.start();
    }
    
    setState(() {
      _sessionSteps = event.steps - _initialSteps;
      _updateStats();
    });
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
    if (!_isSimulationMode) {
      setState(() {
        _error = 'Pedometer not available or permission denied.';
      });
    }
  }

  void _toggleSimulationMode(bool value) {
    setState(() {
      _isSimulationMode = value;
      // Reset all stats when mode changes
      _initialSteps = 0;
      _sessionSteps = 0;
      _distance = 0.0;
      _calories = 0;
      _duration = "00:00:00";
      _stopwatch.reset();
      _error = null;
      _isSimulating = false;

      if (_isSimulationMode) {
        _stepCountSubscription.cancel();
      } else {
        _simulationTimer?.cancel();
        initPedometer();
      }
    });
  }

  void _startSimulation() {
    if (_isSimulating) return;
    setState(() {
      _isSimulating = true;
      if (!_stopwatch.isRunning) _stopwatch.start();
    });

    _simulationTimer = Timer.periodic(Duration(milliseconds: 200 - (_simulationSpeed.toInt() * 15)), (timer) {
      setState(() {
        _sessionSteps += 1;
        _updateStats();
      });
    });
  }

  void _stopSimulation() {
    if (!_isSimulating) return;
    setState(() {
      _isSimulating = false;
    });
    _simulationTimer?.cancel();
    _stopwatch.stop();
  }

  void _changeSimulationSpeed(double newSpeed) {
    setState(() {
      _simulationSpeed = newSpeed;
    });
    if (_isSimulating) {
      _simulationTimer?.cancel();
      _startSimulation();
    }
  }

  void _updateStats() {
    _distance = _calculateDistance(_sessionSteps);
    _calories = _calculateCalories(_sessionSteps);
  }

  double _calculateDistance(int steps) {
    return (steps * 0.762) / 1000; // in kilometers
  }

  int _calculateCalories(int steps) {
    return (steps * 0.04).round();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _stepCountSubscription.cancel();
    _durationTimer.cancel();
    _stopwatch.stop();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer App'),
        actions: [
          Row(
            children: [
              const Text('Simulation'),
              Switch(
                value: _isSimulationMode,
                onChanged: _toggleSimulationMode,
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: _error != null && !_isSimulationMode
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                   if (_isSimulationMode)
                    _buildSimulationControls(),
                  Text(_isSimulationMode ? "(Simulation Mode)" : "(Live Mode)", style: TextStyle(color: _isSimulationMode ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(Icons.directions_walk, _distance.toStringAsFixed(2), "km"),
                        _buildStatColumn(Icons.timer, _duration, "Time"),
                        _buildStatColumn(Icons.local_fire_department, _calories.toString(), "kcal"),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                       const Text(
                        'Steps Taken:',
                        style: TextStyle(fontSize: 30),
                      ),
                      Text(
                        '$_sessionSteps',
                        style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: WalkingManPainter(steps: _sessionSteps),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSimulationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isSimulating ? null : _startSimulation,
                child: const Text('Start'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: !_isSimulating ? null : _stopSimulation,
                child: const Text('Stop'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Text('Speed'),
                Slider(
                    value: _simulationSpeed,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _simulationSpeed.round().toString(),
                    onChanged: _changeSimulationSpeed,
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}

class WalkingManPainter extends CustomPainter {
  final int steps;

  WalkingManPainter({required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Body
    canvas.drawLine(Offset(size.width / 2, size.height * 0.2), Offset(size.width / 2, size.height * 0.6), paint);

    // Head
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.1), 20, paint);

    // Animation logic based on steps
    final animationFrame = (steps ~/ 5) % 4;

    // Legs
    if (animationFrame == 0) {
      canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.4, size.height * 0.9), paint); // Left leg back
      canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.6, size.height * 0.9), paint); // Right leg forward
    } else if (animationFrame == 2) {
        canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.6, size.height * 0.9), paint); // Left leg forward
        canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.4, size.height * 0.9), paint); // Right leg back
    } else {
        canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.5, size.height * 0.9), paint); // Mid-stride
        canvas.drawLine(Offset(size.width / 2, size.height * 0.6), Offset(size.width * 0.5, size.height * 0.9), paint);
    }

    // Arms
    if (animationFrame == 0) {
      canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.5), paint); // Right arm forward
      canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.3, size.height * 0.5), paint); // Left arm back
    } else if (animationFrame == 2) {
      canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.3, size.height * 0.5), paint); // Right arm back
      canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.5), paint); // Left arm forward
    } else {
       canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.5, size.height * 0.5), paint);
       canvas.drawLine(Offset(size.width / 2, size.height * 0.3), Offset(size.width * 0.5, size.height * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WalkingManPainter oldDelegate) {
    return oldDelegate.steps != steps;
  }
}
