import '../models/user_vocabulary.dart';
import '../storage/repositories/user_vocabulary_repository.dart';

class UserVocabularyService {
  UserVocabularyService({UserVocabularyRepository? repository})
    : _repository = repository ?? HiveUserVocabularyRepository();

  final UserVocabularyRepository _repository;

  Future<void> init() async {
    await _repository.init();
  }

  UserWordStatus? getStatus(String word) {
    return _repository.getStatus(word);
  }

  bool isKnown(String word) {
    return getStatus(word) == UserWordStatus.known;
  }

  bool isLearning(String word) {
    return getStatus(word) == UserWordStatus.learning;
  }

  Set<String> get knownWords {
    return _repository.wordsWithStatus(UserWordStatus.known);
  }

  Set<String> get learningWords {
    return _repository.wordsWithStatus(UserWordStatus.learning);
  }

  Map<String, UserWordStatus> get allWords {
    return _repository.allWords;
  }

  Future<void> setKnown(String word) async {
    await _repository.setStatus(word, UserWordStatus.known);
  }

  Future<void> setLearning(String word) async {
    await _repository.setStatus(word, UserWordStatus.learning);
  }

  Future<void> setUnknown(String word) async {
    await _repository.remove(word);
  }

  Future<void> close() async {
    await _repository.close();
  }
}
