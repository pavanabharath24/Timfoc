// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timfoc_badge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimfocBadgeAdapter extends TypeAdapter<TimfocBadge> {
  @override
  final int typeId = 2;

  @override
  TimfocBadge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimfocBadge(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      iconAsset: fields[3] as String,
      unlockedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimfocBadge obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconAsset)
      ..writeByte(4)
      ..write(obj.unlockedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimfocBadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
