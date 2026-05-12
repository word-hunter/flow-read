// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_bookmark.dart';

class ReadingBookmarkAdapter extends TypeAdapter<ReadingBookmark> {
  @override
  final int typeId = 2;

  @override
  ReadingBookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingBookmark(
      chapterIndex: fields[0] as int,
      progress: fields[1] as double,
      chapterTitle: fields[2] as String,
      excerpt: fields[3] as String,
      createdAt: fields[4] as DateTime,
      bookId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingBookmark obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.chapterIndex)
      ..writeByte(1)
      ..write(obj.progress)
      ..writeByte(2)
      ..write(obj.chapterTitle)
      ..writeByte(3)
      ..write(obj.excerpt)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.bookId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingBookmarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
