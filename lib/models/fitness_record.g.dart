// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FitnessRecordAdapter extends TypeAdapter<FitnessRecord> {
  @override
  final int typeId = 0;

  @override
  FitnessRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FitnessRecord()
      ..date = fields[0] as String
      ..steps = fields[1] as int
      ..distance = fields[2] as double
      ..duration = fields[3] as int
      ..calories = fields[4] as double
      ..latitude = fields[6] as double?
      ..longitude = fields[7] as double?
      ..isSynced = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, FitnessRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FitnessRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
