import '../../models/user_vocabulary.dart';

abstract class UserVocabularyRepository {
  Future<void> init();
  UserWordStatus? getStatus(String word);
  Set<String> wordsWithStatus(UserWordStatus status);
  Map<String, UserWordStatus> get allWords;
  Future<void> setStatus(String word, UserWordStatus status);
  Future<void> remove(String word);
  Future<void> close();
}
