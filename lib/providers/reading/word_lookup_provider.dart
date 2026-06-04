import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/learning_item.dart';
import '../../models/word_analysis.dart';
import '../../models/word_context_example.dart';
import '../../services/language/language_module.dart';
import '../../services/dictionary/word_repository.dart';
import '../../services/user_vocabulary_service.dart';
import '../../services/word_level_service.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class WordLookupController {
  const WordLookupController(this._reader);

  final ReadingProvider _reader;

  String? get selectedWord => _reader.selectedWord;
  String? get selectedWordTranslation => _reader.selectedWordTranslation;
  String? get selectedWordContext => _reader.selectedWordContext;
  int? get selectedWordContextStart => _reader.selectedWordContextStart;
  int? get selectedWordContextEnd => _reader.selectedWordContextEnd;
  DictionaryEntry? get selectedWordEntry => _reader.selectedWordEntry;
  DictionaryLookupResult? get selectedWordLookupResult =>
      _reader.selectedWordLookupResult;
  bool get isLoadingWord => _reader.isLoadingWord;
  bool get canGoBackWordLookup => _reader.canGoBackWordLookup;
  WordAnalysis? get aiWordAnalysis => _reader.aiWordAnalysis;
  bool get isAnalyzingWord => _reader.isAnalyzingWord;
  bool get aiFeaturesEnabled => _reader.aiFeaturesEnabled;
  String get aiFeatureDisabledReason => _reader.aiFeatureDisabledReason;
  bool get canCreateLearningItems => _reader.canCreateLearningItems;
  bool get canPronounceWords => _reader.canPronounceWords;
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

  Future<void> lookupRelatedWord(String word) {
    return _reader.lookupRelatedWord(word);
  }

  void goBackWordLookup() {
    _reader.goBackWordLookup();
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _reader.importedExamplesFor(word);
  }

  Future<void> speakWord(String word) {
    return _reader.speakWord(word);
  }

  Future<LearningItemSaveResult?> addSelectedWordLearningItem() {
    return _reader.addSelectedWordLearningItem();
  }

  Future<void> analyzeWordAI(String word, String sentence) {
    return _reader.analyzeWordAI(word, sentence);
  }
}

final wordLookupProvider = Provider<WordLookupController>((ref) {
  return WordLookupController(ref.watch(readingProvider));
});
