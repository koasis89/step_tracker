import 'package:hive/hive.dart';

part 'fitness_record.g.dart'; // Hive가 자동으로 생성할 파일

@HiveType(typeId: 0)
class FitnessRecord extends HiveObject {
  // YYYY-MM-DD 형식의 날짜를 고유 ID로 사용
  @HiveField(0)
  late String date;

  @HiveField(1)
  late int steps;

  @HiveField(2)
  late double distance; // 미터(meters) 단위

  @HiveField(3)
  late int duration; // 초(seconds) 단위

  @HiveField(4)
  late double calories;

  @HiveField(6)
  double? latitude;

  @HiveField(7)
  double? longitude;

  // 클라우드 동기화 여부를 추적하는 필드
  @HiveField(5)
  bool isSynced = false;

  FitnessRecord() {
    isSynced = false; // 기본값은 동기화 안됨
  }

  // Firestore에 업로드하기 위해 객체를 Map으로 변환하는 메소드
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'steps': steps,
      'distance': distance,
      'duration': duration,
      'calories': calories,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}