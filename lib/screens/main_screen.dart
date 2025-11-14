
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // kDebugMode를 사용하기 위해 임포트
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/fitness_record.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/live_screen.dart';
import 'package:myapp/screens/simulation_screen.dart';
import 'package:myapp/screens/hive_viewer_screen.dart'; // 1. 뷰어 화면 임포트

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Firestore와 동기화하는 함수
  Future<void> _syncDataToFirestore() async {
    // SnackBar를 표시하기 위해 context가 사용 가능할 때까지 기다립니다.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('동기화를 시작합니다...')),
    );

    final box = Hive.box<FitnessRecord>('fitness_records');
    final firestore = FirebaseFirestore.instance;

    // 1. 동기화되지 않은 기록만 필터링
    final unsyncedRecords = box.values.where((record) => !record.isSynced).toList();

    if (unsyncedRecords.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 데이터가 최신 상태입니다.')),
      );
      return;
    }

    try {
      for (final record in unsyncedRecords) {
        // 2. Firestore에 업로드 (컬렉션: fitness_records, 문서 ID: 날짜)
        await firestore.collection('fitness_records').doc(record.date).set(record.toMap());

        // 3. 업로드 성공 시, 로컬 DB에 동기화 완료 표시 후 저장
        record.isSynced = true;
        await record.save();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${unsyncedRecords.length}개의 기록을 성공적으로 동기화했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('동기화 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appMode = context.watch<AppModeProvider>();
    final isSimulation = appMode.isSimulationMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('step_tracker'),
        actions: [
          // 디버그 모드일 때만 Hive 뷰어 버튼을 보여줌
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.storage),
              tooltip: 'View Local Storage',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HiveViewerScreen()),
                );
              },
            ),
          // 동기화 버튼 추가
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync to Cloud',
            onPressed: _syncDataToFirestore,
          ),
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
