import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/fitness_record.dart';

class HiveViewerScreen extends StatefulWidget {
  const HiveViewerScreen({super.key});

  @override
  State<HiveViewerScreen> createState() => _HiveViewerScreenState();
}

class _HiveViewerScreenState extends State<HiveViewerScreen> {
  late Box<FitnessRecord> _fitnessBox;

  @override
  void initState() {
    super.initState();
    _fitnessBox = Hive.box<FitnessRecord>('fitness_records');
  }

  // 모든 데이터를 삭제하는 함수
  Future<void> _clearAllData() async {
    // 사용자에게 재확인 받기
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모든 데이터 삭제'),
          content: const Text('정말로 모든 운동 기록을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // 사용자가 '삭제'를 선택했을 때만 실행
    if (confirmed == true) {
      await _fitnessBox.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 데이터가 삭제되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로컬 데이터베이스 뷰어'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: '모든 데이터 삭제',
            onPressed: _clearAllData,
          ),
        ],
      ),
      // ValueListenableBuilder를 사용하여 Hive Box의 변경사항을 실시간으로 감지
      body: ValueListenableBuilder(
        valueListenable: _fitnessBox.listenable(),
        builder: (context, Box<FitnessRecord> box, _) {
          // 모든 데이터를 가져옵니다.
          final records = box.keys.map((key) => box.get(key)!).toList();

          if (records.isEmpty) {
            return const Center(
              child: Text('저장된 데이터가 없습니다.'),
            );
          }

          // 최신 날짜 순으로 정렬
          records.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              // 'yyyy-MM-dd-HH-mm' 형식의 키를 분리하여 표시

              String displayDate = record.date;
              try {
                final parts = record.date.split('-');
                if (parts.length >= 4) {
                  displayDate = '날짜: ${parts[0]}-${parts[1]}-${parts[2]}  시간: ${parts[3]}:${parts.length > 4 ? parts[4] : '00'}';
                }
              } catch (e) {
                // 포맷이 다른 경우 원본 데이터 표시
                displayDate = '키: ${record.date}';
              }

              // total이 붙은 키인지 확인
              final isTotal = record.date.endsWith("_total");
              final displayType = isTotal ? "(총 누적)" : "(순수 활동)";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: record.isSynced ? Colors.green : Colors.orange,
                    child: Icon(
                      record.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    "$displayDate $displayType",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '걸음: ${record.steps} | 거리: ${(record.distance / 1000).toStringAsFixed(2)}km | 시간: ${record.duration}초 \n'
                    '칼로리: ${record.calories.toStringAsFixed(1)}kcal\n'
                    '위치: ${record.latitude?.toStringAsFixed(4)}, ${record.longitude?.toStringAsFixed(4)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}