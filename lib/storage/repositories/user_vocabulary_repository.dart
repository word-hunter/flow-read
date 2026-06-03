import 'package:hive/hive.dart';

import '../../models/user_vocabulary.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class UserVocabularyRepository {
  Future<void> init();
  UserWordStatus? getStatus(String word);
  Set<String> wordsWithStatus(UserWordStatus status);
  Map<String, UserWordStatus> get allWords;
  Future<void> setStatus(String word, UserWordStatus status);
  Future<void> remove(String word);
  Future<void> close();
}

class HiveUserVocabularyRepository implements UserVocabularyRepository {
  HiveUserVocabularyRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      requireOpenHiveBox<String>(HiveBoxNames.userVocabularyFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(
      HiveBoxNames.userVocabularyFor(_languageCode),
    );
  }

  @override
  UserWordStatus? getStatus(String word) {
    final value = _storage.get(_normalize(word));
    if (value == null) return null;
    return value == 'learning' ? UserWordStatus.learning : UserWordStatus.known;
  }

  @override
  Set<String> wordsWithStatus(UserWordStatus status) {
    final storedValue = _encodeStatus(status);
    final result = <String>{};
    for (final key in _storage.keys) {
      if (_storage.get(key) == storedValue) result.add(key.toString());
    }
    return result;
  }

  @override
  Map<String, UserWordStatus> get allWords {
    return _storage.keys.fold<Map<String, UserWordStatus>>({}, (map, key) {
      map[key.toString()] = _storage.get(key) == 'learning'
          ? UserWordStatus.learning
          : UserWordStatus.known;
      return map;
    });
  }

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    await _storage.put(_normalize(word), _encodeStatus(status));
  }

  @override
  Future<void> remove(String word) async {
    await _storage.delete(_normalize(word));
  }

  @override
  Future<void> close() async {}

  String _encodeStatus(UserWordStatus status) {
    return status == UserWordStatus.learning ? 'learning' : 'known';
  }

  String _normalize(String word) => word.toLowerCase().trim();
}
