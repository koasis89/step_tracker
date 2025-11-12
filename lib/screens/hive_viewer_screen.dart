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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로컬 데이터베이스 뷰어'),
      ),
      // ValueListenableBuilder를 사용하여 Hive Box의 변경사항을 실시간으로 감지
      body: ValueListenableBuilder(
        valueListenable: _fitnessBox.listenable(),
        builder: (context, Box<FitnessRecord> box, _) {
          final records = box.values.toList().cast<FitnessRecord>();

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
                    displayDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '걸음: ${record.steps} | 거리: ${(record.distance / 1000).toStringAsFixed(2)}km | 시간: ${record.duration}초\n'
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