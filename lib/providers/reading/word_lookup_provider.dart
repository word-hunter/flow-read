import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/language/language_module.dart';
import '../../services/user_vocabulary_service.dart';
import '../../services/word_level_service.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class WordLookupController {
  const WordLookupController(this._reader);

  final ReadingProvider _reader;

  String? get selectedWord => _reader.selectedWord;
  UserVocabularyService? get userVocabulary => _reader.userVocabulary;
  WordLevelService? get wordLevelService => _reader.wordLevelService;
  LanguageModule get activeLanguageModule => _reader.activeLanguageModule;

  Future<void> lookupWord(
    String word, {
    String? contextText,
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    return _reader.lookupWord(
      word,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );
  }

  void clearWordLookup() {
    _reader.clearWordLookup();
  }
}

final wordLookupProvider = Provider<WordLookupController>((ref) {
  return WordLookupController(ref.watch(readingProvider));
});
