
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/live_screen.dart';
import 'package:myapp/screens/simulation_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/main.dart';

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
        //title: Text(isSimulation ? 'Simulation Mode' : 'Live Mode'),
        title: Text('step_tracker'),
        actions: [
          // 1. 테마 변경 버튼
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          // 2. 시뮬레이션/라이브 모드 아이콘
          Icon(isSimulation ? Icons.smart_toy_outlined : Icons.sensors),
          // 3. 모드 변경 스위치
          Switch(
            value: isSimulation,
            onChanged: (value) {
              context.read<AppModeProvider>().toggleMode();
            },
          ),
          // 4. 오른쪽 끝에 약간의 여백 추가
          const SizedBox(width: 8),
        ],
      ),
      body: isSimulation ? const SimulationScreen() : const LiveScreen(),
    );
  }
}
