// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_config.dart';

class ReadingConfigAdapter extends TypeAdapter<ReadingConfig> {
  @override
  final int typeId = 3;

  @override
  ReadingConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingConfig(
      fontSize: fields[0] as double,
      fontFamily: fields[1] as String,
      lineHeight: fields[2] as double,
      theme: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fontSize)
      ..writeByte(1)
      ..write(obj.fontFamily)
      ..writeByte(2)
      ..write(obj.lineHeight)
      ..writeByte(3)
      ..write(obj.theme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
