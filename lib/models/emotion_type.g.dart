// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionTypeAdapter extends TypeAdapter<EmotionType> {
  @override
  final int typeId = 1;

  @override
  EmotionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EmotionType.angry;
      case 1:
        return EmotionType.sad;
      case 2:
        return EmotionType.tired;
      case 3:
        return EmotionType.anxious;
      case 4:
        return EmotionType.frustrated;
      case 5:
        return EmotionType.mixed;
      default:
        return EmotionType.angry;
    }
  }

  @override
  void write(BinaryWriter writer, EmotionType obj) {
    switch (obj) {
      case EmotionType.angry:
        writer.writeByte(0);
        break;
      case EmotionType.sad:
        writer.writeByte(1);
        break;
      case EmotionType.tired:
        writer.writeByte(2);
        break;
      case EmotionType.anxious:
        writer.writeByte(3);
        break;
      case EmotionType.frustrated:
        writer.writeByte(4);
        break;
      case EmotionType.mixed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
