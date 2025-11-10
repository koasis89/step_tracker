
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabs/step_tab_page.dart';
import '../tabs/profile_tab_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = 0;
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _steps = 0;

  bool _isSimulationMode = false;
  double _simulationSpeed = 3.0;
  Timer? _simulationTimer;

  late AnimationController _animationController;
  StreamSubscription<DocumentSnapshot>? _stepDataSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Default duration
    )..addStatusListener((status) {
      // Make the animation loop back and forth for a natural walk cycle
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _setupPedometer();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _stepDataSubscription?.cancel();
    _simulationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _setupPedometer() {
    if (_isSimulationMode) {
      _stepCountSubscription?.cancel();
      _stepDataSubscription?.cancel();
      _startSimulation();
    } else {
      _stopSimulation();
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountSubscription = _stepCountStream.listen(_onStepCount, onError: _onStepCountError);
      _listenToStepData();
    }
  }

  void _listenToStepData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final today = DateUtils.dateOnly(DateTime.now()).toIso8601String().substring(0, 10);

    _stepDataSubscription?.cancel();
    _stepDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_steps')
        .doc(today)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists && !_isSimulationMode) {
        final serverSteps = snapshot.data()?['steps'] ?? 0;
        if (serverSteps != _steps) {
            setState(() {
                _steps = serverSteps;
            });
        }
      }
    });
  }

  Future<void> _updateSteps(int newSteps) async {
    if (!mounted) return;

    setState(() {
      _steps = newSteps;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final today = DateUtils.dateOnly(DateTime.now()).toIso8601String().substring(0, 10);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_steps')
        .doc(today)
        .set({'steps': newSteps, 'date': Timestamp.now()});
  }

  void _onStepCount(StepCount event) {
      _updateSteps(event.steps);
      if (!_animationController.isAnimating) {
          _animationController.forward();
      }
  }

  void _onStepCountError(error) {
    if (mounted && !_isSimulationMode) {
      _toggleSimulationMode(true);
    }
  }

  void _toggleSimulationMode(bool value) {
    setState(() {
      _isSimulationMode = value;
      _steps = 0; 
      _updateSteps(0);
      _setupPedometer();
    });
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    
    _simulationTimer = Timer.periodic(_getDurationPerStep(), (timer) {
        _updateSteps(_steps + 1);
    });

    _animationController.duration = _getDurationPerStep();
    if (!_animationController.isAnimating) {
      _animationController.forward(); // Start the forward-reverse loop
    }
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }

  void _onSpeedChanged(double newSpeed) {
    setState(() {
      _simulationSpeed = newSpeed;
    });
    if (_isSimulationMode && (_simulationTimer?.isActive ?? false)) {
        _startSimulation();
    }
  }

  Duration _getDurationPerStep() {
    final maxDuration = 1200;
    final minDuration = 250;
    final durationRange = maxDuration - minDuration;
    final normalizedSpeed = (_simulationSpeed - 1) / 9;
    final invertedDuration = maxDuration - (normalizedSpeed * durationRange);
    return Duration(milliseconds: invertedDuration.toInt());
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentIndex == 0)
            Row(
              children: [
                const Text('Sim Mode', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _isSimulationMode,
                  onChanged: _toggleSimulationMode,
                  activeColor: Colors.orangeAccent,
                ),
              ],
            ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => FirebaseAuth.instance.signOut(),
            )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          StepTabPage(
            steps: _steps,
            isSimulationMode: _isSimulationMode,
            simulationSpeed: _simulationSpeed,
            animationController: _animationController,
            onStart: _startSimulation,
            onStop: _stopSimulation,
            onSpeedChanged: _onSpeedChanged,
          ),
          const Center(child: Text('Statistics Page')),
          const Center(child: Text('Events Page')),
          const ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            label: 'Step',
            icon: Icon(Icons.directions_walk),
          ),
          BottomNavigationBarItem(
            label: 'Stats',
            icon: Icon(Icons.bar_chart),
          ),
          BottomNavigationBarItem(
            label: 'Events',
            icon: Icon(Icons.event),
          ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  late Stream<StepCount> _stepCountStream;
}
