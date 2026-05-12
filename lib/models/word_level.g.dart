// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_level.dart';

class WordLevelInfoAdapter extends TypeAdapter<WordLevelInfo> {
  @override
  final int typeId = 4;

  @override
  WordLevelInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordLevelInfo(
      word: fields[0] as String,
      originForm: fields[1] as String,
      levelIndex: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WordLevelInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.originForm)
      ..writeByte(2)
      ..write(obj.levelIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordLevelInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
