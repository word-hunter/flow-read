import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';

class FakeUserVocabularyRepository implements UserVocabularyRepository {
  final Map<String, UserWordStatus> _data;

  FakeUserVocabularyRepository(this._data);

  @override
  Future<void> init() async {}

  @override
  UserWordStatus? getStatus(String word) {
    return _data[word.toLowerCase().trim()];
  }

  @override
  Set<String> wordsWithStatus(UserWordStatus status) {
    return _data.entries
        .where((e) => e.value == status)
        .map((e) => e.key)
        .toSet();
  }

  @override
  Map<String, UserWordStatus> get allWords => Map.unmodifiable(_data);

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    _data[word.toLowerCase().trim()] = status;
  }

  @override
  Future<void> remove(String word) async {
    _data.remove(word.toLowerCase().trim());
  }

  @override
  Future<void> close() async {}
}

UserVocabularyService createFakeVocab({
  required Set<String> knownWords,
  Set<String> learningWords = const {},
}) {
  final data = <String, UserWordStatus>{};
  for (final word in knownWords) {
    data[word.toLowerCase().trim()] = UserWordStatus.known;
  }
  for (final word in learningWords) {
    data[word.toLowerCase().trim()] = UserWordStatus.learning;
  }
  return UserVocabularyService(
    repository: FakeUserVocabularyRepository(data),
    languageCode: 'en',
  );
}
