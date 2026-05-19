// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_item.dart';

class LearningItemAdapter extends TypeAdapter<LearningItem> {
  @override
  final int typeId = 11;

  @override
  LearningItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningItem(
      id: fields[0] as String,
      type: learningItemTypeFromName(fields[1] as String?),
      canonicalKey: fields[2] as String? ?? '',
      title: fields[3] as String? ?? '',
      content: fields[4] as String? ?? '',
      answer: fields[5] as String? ?? '',
      note: fields[6] as String? ?? '',
      sourceText: fields[7] as String? ?? '',
      bookId: fields[8] as String? ?? '',
      chapterIndex: fields[9] as int? ?? -1,
      chapterTitle: fields[10] as String? ?? '',
      createdAt:
          fields[11] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          fields[12] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0),
      tags:
          (fields[13] as List?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      metadata:
          (fields[14] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString()))
              .cast<String, String>() ??
          const {},
    );
  }

  @override
  void write(BinaryWriter writer, LearningItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.name)
      ..writeByte(2)
      ..write(obj.canonicalKey)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.answer)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.sourceText)
      ..writeByte(8)
      ..write(obj.bookId)
      ..writeByte(9)
      ..write(obj.chapterIndex)
      ..writeByte(10)
      ..write(obj.chapterTitle)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
