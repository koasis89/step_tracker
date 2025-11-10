
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:myapp/tabs/step_tab_page.dart';
import 'package:myapp/widgets/detailed_walking_painter.dart';

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
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _steps = 0;
  bool _isSimulationMode = false;
  double _simulationSpeed = 5.0;
  
  late AnimationController _animationController;
  double _previousAnimationValue = 0.0;

  StreamSubscription<StepCount>? _stepCountSubscription;

  // This listener increments steps during simulation based on animation cycles
  void _onAnimationUpdate() {
    if (!_isSimulationMode || !_animationController.isAnimating) return;
    final currentValue = _animationController.value;
    // Count a step every time the animation passes the halfway point (forward or backward)
    if ((_previousAnimationValue < 0.5 && currentValue >= 0.5) ||
        (_previousAnimationValue > 0.5 && currentValue < 0.5)) {
      setState(() { _steps++; });
    }
    _previousAnimationValue = currentValue;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1020), // Initial duration
    );
    _animationController.addListener(_onAnimationUpdate);
    initPedometer();
  }

  void initPedometer() {
    if (_isSimulationMode) return;
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount, 
      onError: _onStepCountError
    );
  }
  
  void _onStepCount(StepCount event) {
    if (!_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
    setState(() {
      _steps = event.steps;
    });
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
    if (mounted && !_isSimulationMode) {
      setState(() {
        print("Sensor not found, switching to simulation mode");
        _toggleSimulationMode(true);
      });
    }
  }

  void _toggleSimulationMode(bool value) {
    setState(() {
      _isSimulationMode = value;
      _steps = 0;
      _previousAnimationValue = 0.0;
      _animationController.stop();
      _animationController.reset();

      if (value) { // Switched TO simulation
        _stepCountSubscription?.cancel();
        _updateAnimationDuration(); // Set initial speed
      } else { // Switched TO live mode
        initPedometer();
      }
    });
  }

  void _startSimulation() {
    if (_isSimulationMode && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
  }

  void _stopSimulation() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }
  
  void _updateAnimationDuration() {
      // Duration is now halved to make the animation twice as fast.
      final durationMs = (1620 - (_simulationSpeed * 120)) / 2;
      _animationController.duration = Duration(milliseconds: durationMs.toInt());
      
      if(_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _animationController.removeListener(_onAnimationUpdate);
    _animationController.dispose();
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
              const Text('Simulate'),
              Switch(
                value: _isSimulationMode,
                onChanged: _toggleSimulationMode,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: StepTabPage(
        steps: _steps,
        isSimulationMode: _isSimulationMode,
        simulationSpeed: _simulationSpeed,
        animationController: _animationController,
        onStart: _startSimulation,
        onStop: _stopSimulation,
        onSpeedChanged: (newSpeed) {
          setState(() {
            _simulationSpeed = newSpeed;
            _updateAnimationDuration();
          });
        },
      ),
    );
  }
}
