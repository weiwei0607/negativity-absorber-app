// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoryProfileAdapter extends TypeAdapter<MemoryProfile> {
  @override
  final int typeId = 5;

  @override
  MemoryProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryProfile(
      summary: fields[0] as String,
      lastUpdated: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MemoryProfile obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.summary)
      ..writeByte(1)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
