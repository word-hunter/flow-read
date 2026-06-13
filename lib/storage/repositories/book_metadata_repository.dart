import '../../models/book_metadata.dart';

abstract class BookMetadataRepository {
  Future<void> init();
  Iterable<BookMetadata> get values;
  BookMetadata? get(String id);
  Future<void> put(String id, BookMetadata metadata);
  Future<void> delete(String id);
  Future<void> close();
}
