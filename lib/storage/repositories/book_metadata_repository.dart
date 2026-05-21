import 'package:hive/hive.dart';

import '../../models/book_metadata.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class BookMetadataRepository {
  Future<void> init();
  Iterable<BookMetadata> get values;
  BookMetadata? get(String id);
  Future<void> put(String id, BookMetadata metadata);
  Future<void> delete(String id);
  Future<void> close();
}

class HiveBookMetadataRepository implements BookMetadataRepository {
  HiveBookMetadataRepository({Box<BookMetadata>? box}) : _box = box;

  Box<BookMetadata>? _box;

  Box<BookMetadata> get _storage {
    return _box ?? Hive.box<BookMetadata>(HiveBoxNames.books);
  }

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<BookMetadata>(HiveBoxNames.books);
  }

  @override
  Iterable<BookMetadata> get values => _storage.values;

  @override
  BookMetadata? get(String id) => _storage.get(id);

  @override
  Future<void> put(String id, BookMetadata metadata) async {
    await _storage.put(id, metadata);
  }

  @override
  Future<void> delete(String id) async {
    await _storage.delete(id);
  }

  @override
  Future<void> close() async {}
}
