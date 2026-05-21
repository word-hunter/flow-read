import 'package:hive/hive.dart';

import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class WordContextRepository {
  Future<void> init();
  String? getEncodedExamples(String word);
  Future<void> putEncodedExamples(String word, String encodedExamples);
  Future<void> close();
}

class HiveWordContextRepository implements WordContextRepository {
  HiveWordContextRepository({Box<String>? box}) : _box = box;

  Box<String>? _box;

  Box<String> get _storage =>
      _box ?? requireOpenHiveBox<String>(HiveBoxNames.wordContexts);

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(HiveBoxNames.wordContexts);
  }

  @override
  String? getEncodedExamples(String word) {
    return _storage.get(word);
  }

  @override
  Future<void> putEncodedExamples(String word, String encodedExamples) async {
    await _storage.put(word, encodedExamples);
  }

  @override
  Future<void> close() async {}
}
