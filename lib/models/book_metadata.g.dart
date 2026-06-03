// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_metadata.dart';

class BookMetadataAdapter extends TypeAdapter<BookMetadata> {
  @override
  final int typeId = 0;

  @override
  BookMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookMetadata(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      sourcePath: fields[3] as String,
      coverPath: fields[4] as String?,
      totalChapters: fields[5] as int,
      globalProgress: fields[6] as double,
      currentChapter: fields[7] as int,
      chapterProgress: fields[8] as double,
      lastReadAt: fields[9] as DateTime?,
      difficultyStudyWords: (fields[10] as List?)
          ?.map((word) => word.toString())
          .toList(),
      difficultyRatingJson: (fields[11] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      difficultyVocabularySignature: fields[12] as String?,
      difficultyComputedAt: fields[13] as DateTime?,
      chapterScrollOffset: (fields[14] as num?)?.toDouble(),
      sourceLanguage: fields[15] as String?,
      sourceLanguageOverride: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BookMetadata obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.sourcePath)
      ..writeByte(4)
      ..write(obj.coverPath)
      ..writeByte(5)
      ..write(obj.totalChapters)
      ..writeByte(6)
      ..write(obj.globalProgress)
      ..writeByte(7)
      ..write(obj.currentChapter)
      ..writeByte(8)
      ..write(obj.chapterProgress)
      ..writeByte(9)
      ..write(obj.lastReadAt)
      ..writeByte(10)
      ..write(obj.difficultyStudyWords)
      ..writeByte(11)
      ..write(obj.difficultyRatingJson)
      ..writeByte(12)
      ..write(obj.difficultyVocabularySignature)
      ..writeByte(13)
      ..write(obj.difficultyComputedAt)
      ..writeByte(14)
      ..write(obj.chapterScrollOffset)
      ..writeByte(15)
      ..write(obj.sourceLanguage)
      ..writeByte(16)
      ..write(obj.sourceLanguageOverride);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
