// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyProgressAdapter extends TypeAdapter<DailyProgress> {
  @override
  final int typeId = 1;

  @override
  DailyProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyProgress(
      date: fields[0] as DateTime,
      totalFocusMinutes: fields[1] as int,
      completedSessions: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalFocusMinutes)
      ..writeByte(2)
      ..write(obj.completedSessions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
