
import 'package:flutter/material.dart';
import '../widgets/smooth_walking_painter.dart'; // Use the new file

class StepTabPage extends StatelessWidget {
  final int steps;
  final bool isSimulationMode;
  final double simulationSpeed;
  final AnimationController animationController;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final ValueChanged<double> onSpeedChanged;

  const StepTabPage({
    super.key,
    required this.steps,
    required this.isSimulationMode,
    required this.simulationSpeed,
    required this.animationController,
    required this.onStart,
    required this.onStop,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              isSimulationMode ? 'Simulation Mode' : 'Live Mode',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: isSimulationMode ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Steps Taken:',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '$steps',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            CustomPaint(
              size: const Size(200, 250),
              // The painter class name is still WalkingManPainter, but it's from the new file
              painter: WalkingManPainter(animation: animationController),
            ),
            const SizedBox(height: 40),
            if (isSimulationMode)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          onPressed: onStart,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          onPressed: onStop,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Slow'),
                        Expanded(
                          child: Slider(
                            value: simulationSpeed,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: simulationSpeed.round().toString(),
                            onChanged: onSpeedChanged,
                          ),
                        ),
                        const Text('Fast'),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
