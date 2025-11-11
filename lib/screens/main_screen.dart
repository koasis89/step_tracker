
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/live_screen.dart';
import 'package:myapp/screens/simulation_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeProvider>();
    final isSimulation = appMode.isSimulationMode;

    return Scaffold(
      appBar: AppBar(
        // AppBar의 스타일은 이제 main.dart의 테마를 따르므로
        // backgroundColor와 elevation 속성을 여기서 지정할 필요가 없습니다.
        title: Text(isSimulation ? 'Simulation Mode' : 'Live Mode'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(isSimulation ? Icons.smart_toy_outlined : Icons.sensors, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Switch(
                  value: isSimulation,
                  onChanged: (value) {
                    context.read<AppModeProvider>().toggleMode();
                  },
                  // Switch의 스타일 관련 코드(thumbColor, trackColor)는
                  // 이제 main.dart의 테마에서 중앙 관리되므로 여기서 모두 삭제합니다.
                ),
              ],
            ),
          ),
        ],
      ),
      body: isSimulation ? const SimulationScreen() : const LiveScreen(),
    );
  }
}
