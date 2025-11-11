
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:myapp/widgets/detailed_walking_painter.dart';

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

  void _onAnimationUpdate() {
    if (!_isSimulationMode || !_animationController.isAnimating) return;
    final currentValue = _animationController.value;
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
      duration: const Duration(milliseconds: 1020),
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

      if (value) {
        _stepCountSubscription?.cancel();
        _updateAnimationDuration();
      } else {
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                _isSimulationMode ? 'Simulation Mode' : 'Live Mode',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _isSimulationMode ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                width: 200,
                child: CustomPaint(
                  size: const Size(200, 250),
                  painter: DetailedWalkingPainter(animation: _animationController),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Steps Taken',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
              Text(
                '$_steps',
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              if (_isSimulationMode)
                _buildSimulationControls(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
