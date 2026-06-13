import '../../models/word_level.dart';

abstract class WordLevelRepository {
  Future<void> init();
  Iterable<WordLevelInfo> get values;
  bool get isNotEmpty;
  bool get imported;
  Future<void> addAll(Iterable<WordLevelInfo> entries);
  Future<void> markImported();
  Future<void> close();
}
