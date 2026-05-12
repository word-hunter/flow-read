import 'package:hive/hive.dart';

import '../models/user_vocabulary.dart';

class UserVocabularyService {
  late Box<String> _box;

  Future<void> init() async {
    _box = Hive.box<String>('user_vocabulary');
  }

  UserWordStatus? getStatus(String word) {
    final value = _box.get(word.toLowerCase().trim());
    if (value == null) return null;
    return value == 'learning' ? UserWordStatus.learning : UserWordStatus.known;
  }

  bool isKnown(String word) {
    return getStatus(word) == UserWordStatus.known;
  }

  bool isLearning(String word) {
    return getStatus(word) == UserWordStatus.learning;
  }

  Set<String> get knownWords {
    final result = <String>{};
    for (final key in _box.keys) {
      if (_box.get(key) == 'known') result.add(key);
    }
    return result;
  }

  Set<String> get learningWords {
    final result = <String>{};
    for (final key in _box.keys) {
      if (_box.get(key) == 'learning') result.add(key);
    }
    return result;
  }

  Map<String, UserWordStatus> get allWords {
    return _box.keys.fold<Map<String, UserWordStatus>>({}, (map, key) {
      map[key] = _box.get(key) == 'learning'
          ? UserWordStatus.learning
          : UserWordStatus.known;
      return map;
    });
  }

  Future<void> setKnown(String word) async {
    await _box.put(word.toLowerCase().trim(), 'known');
  }

  Future<void> setLearning(String word) async {
    await _box.put(word.toLowerCase().trim(), 'learning');
  }

  Future<void> setUnknown(String word) async {
    await _box.delete(word.toLowerCase().trim());
  }

  Future<void> close() async {
    await _box.close();
  }
}
