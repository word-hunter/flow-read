// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_glossary_entry.dart';

class BookGlossaryEntryAdapter extends TypeAdapter<BookGlossaryEntry> {
  @override
  final int typeId = HiveTypeIds.bookGlossaryEntry;

  @override
  BookGlossaryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookGlossaryEntry(
      id: fields[0] as String,
      bookId: fields[1] as String,
      word: fields[2] as String,
      canonicalForm: fields[3] as String?,
      explanation: fields[4] as String,
      sourceContext: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      lastAccessedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BookGlossaryEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.word)
      ..writeByte(3)
      ..write(obj.canonicalForm)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.sourceContext)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastAccessedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookGlossaryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
