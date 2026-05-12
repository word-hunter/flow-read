// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarked_word.dart';

class BookmarkedWordAdapter extends TypeAdapter<BookmarkedWord> {
  @override
  final int typeId = 1;

  @override
  BookmarkedWord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkedWord(
      word: fields[0] as String,
      translation: fields[1] as String,
      context: fields[2] as String,
      addedAt: fields[3] as DateTime,
      bookId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkedWord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.translation)
      ..writeByte(2)
      ..write(obj.context)
      ..writeByte(3)
      ..write(obj.addedAt)
      ..writeByte(4)
      ..write(obj.bookId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkedWordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
