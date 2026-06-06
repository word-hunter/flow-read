import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_analysis.dart';
import '../../models/word_context_example.dart';
import '../../services/compound_word_analyzer.dart';
import '../../services/dictionary/word_repository.dart';
import '../../services/reading_search_service.dart';
import '../../services/pronunciation_service.dart';
import '../../services/word_level_service.dart';
import '../../services/word_context_service.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';
import 'services_provider.dart';

@immutable
class WordLookupState {
  const WordLookupState({
    this.selectedWord,
    this.selectedWordTranslation,
    this.selectedWordContext,
    this.selectedWordContextStart,
    this.selectedWordContextEnd,
    this.selectedWordEntry,
    this.selectedWordLookupResult,
    this.wordLookupHistory = const [],
    this.isLoadingWord = false,
    this.aiWordAnalysis,
    this.isAnalyzingWord = false,
  });

  final String? selectedWord;
  final String? selectedWordTranslation;
  final String? selectedWordContext;
  final int? selectedWordContextStart;
  final int? selectedWordContextEnd;
  final DictionaryEntry? selectedWordEntry;
  final DictionaryLookupResult? selectedWordLookupResult;
  final List<DictionaryLookupResult> wordLookupHistory;
  final bool isLoadingWord;
  final WordAnalysis? aiWordAnalysis;
  final bool isAnalyzingWord;

  bool get canGoBackWordLookup => wordLookupHistory.isNotEmpty;

  WordLookupState copyWith({
    String? selectedWord,
    String? selectedWordTranslation,
    String? selectedWordContext,
    int? selectedWordContextStart,
    int? selectedWordContextEnd,
    DictionaryEntry? selectedWordEntry,
    DictionaryLookupResult? selectedWordLookupResult,
    List<DictionaryLookupResult>? wordLookupHistory,
    bool? isLoadingWord,
    WordAnalysis? aiWordAnalysis,
    bool? isAnalyzingWord,
    bool clearWordLookup = false,
    bool clearAIAnalysis = false,
  }) {
    return WordLookupState(
      selectedWord: clearWordLookup ? null : (selectedWord ?? this.selectedWord),
      selectedWordTranslation: clearWordLookup
          ? null
          : (selectedWordTranslation ?? this.selectedWordTranslation),
      selectedWordContext: clearWordLookup
          ? null
          : (selectedWordContext ?? this.selectedWordContext),
      selectedWordContextStart: clearWordLookup
          ? null
          : (selectedWordContextStart ?? this.selectedWordContextStart),
      selectedWordContextEnd: clearWordLookup
          ? null
          : (selectedWordContextEnd ?? this.selectedWordContextEnd),
      selectedWordEntry:
          clearWordLookup ? null : (selectedWordEntry ?? this.selectedWordEntry),
      selectedWordLookupResult: clearWordLookup
          ? null
          : (selectedWordLookupResult ?? this.selectedWordLookupResult),
      wordLookupHistory: wordLookupHistory ?? this.wordLookupHistory,
      isLoadingWord: isLoadingWord ?? this.isLoadingWord,
      aiWordAnalysis:
          clearAIAnalysis ? null : (aiWordAnalysis ?? this.aiWordAnalysis),
      isAnalyzingWord: isAnalyzingWord ?? this.isAnalyzingWord,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WordLookupState &&
        other.selectedWord == selectedWord &&
        other.selectedWordTranslation == selectedWordTranslation &&
        other.isLoadingWord == isLoadingWord &&
        other.isAnalyzingWord == isAnalyzingWord;
  }

  @override
  int get hashCode => Object.hash(
        selectedWord,
        selectedWordTranslation,
        isLoadingWord,
        isAnalyzingWord,
      );
}

class WordLookupNotifier extends Notifier<WordLookupState> {
  int _requestVersion = 0;

  WordRepository get _wordRepo => ref.read(wordRepositoryProvider);
  PronunciationService get _pronunciation =>
      ref.read(pronunciationServiceProvider);
  WordLevelService get _wordLevelService =>
      ref.read(wordLevelServiceProvider);
  WordContextService get _wordContextService =>
      ref.read(wordContextServiceProvider);

  @override
  WordLookupState build() {
    return const WordLookupState();
  }

  Future<void> lookupWord(
    String word, {
    String? canonicalForm,
    String? languageCode,
    String? reading,
    String? contextText,
    int? contextWordStart,
    int? contextWordEnd,
    bool trackReadingLookup = false,
  }) async {
    final reader = ref.read(readingProvider);
    final activeModule = reader.activeLanguageModule;
    final normalizedContext = _normalizeLookupContext(
      contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );

    state = state.copyWith(wordLookupHistory: []);
    await _lookupWord(
      DictionaryLookupRequest(
        word: word,
        languageCode:
            _nonEmptyOrNull(languageCode) ?? activeModule.languageCode,
        canonicalForm:
            _nonEmptyOrNull(canonicalForm) ?? activeModule.canonicalize(word),
        reading: _nonEmptyOrNull(reading),
        contextText: normalizedContext.text,
        contextWordStart: normalizedContext.wordStart,
        contextWordEnd: normalizedContext.wordEnd,
      ),
      trackReadingLookup: trackReadingLookup,
    );
  }

  Future<void> lookupRelatedWord(String word) async {
    final reader = ref.read(readingProvider);
    final current = state.selectedWordLookupResult;
    if (current != null) {
      state = state.copyWith(
        wordLookupHistory: [...state.wordLookupHistory, current],
      );
    }
    await _lookupWord(
      DictionaryLookupRequest(
        word: word,
        languageCode: reader.activeLanguageModule.languageCode,
        canonicalForm: reader.activeLanguageModule.canonicalize(word),
      ),
    );
  }

  Future<void> _lookupWord(
    DictionaryLookupRequest request, {
    bool trackReadingLookup = false,
  }) async {
    final requestVersion = ++_requestVersion;
    state = state.copyWith(
      selectedWord: request.displayWord,
      selectedWordTranslation: null,
      selectedWordContext: request.contextText,
      selectedWordContextStart: request.contextWordStart,
      selectedWordContextEnd: request.contextWordEnd,
      selectedWordEntry: null,
      selectedWordLookupResult: null,
      isLoadingWord: true,
    );

    final reader = ref.read(readingProvider);
    final activeBookId = reader.activeBookId;
    if (trackReadingLookup && activeBookId != null && reader.book != null) {
      await ref.read(learningAnalyticsServiceProvider).recordLookup(
            bookId: activeBookId,
            chapterIndex: reader.currentChapter,
            word: request.displayWord,
          );
    }
    if (requestVersion != _requestVersion) return;

    var result = await _wordRepo.lookupRequest(request);
    if (requestVersion != _requestVersion) return;
    result = await _withDictionaryFallbacks(result);
    if (requestVersion != _requestVersion) return;
    _applyWordLookupResult(result);
    state = state.copyWith(isLoadingWord: false);
  }

  void goBackWordLookup() {
    if (state.wordLookupHistory.isEmpty) return;
    final history = List<DictionaryLookupResult>.from(state.wordLookupHistory);
    final previous = history.removeLast();
    _applyWordLookupResult(previous);
    state = state.copyWith(
      wordLookupHistory: history,
      isLoadingWord: false,
    );
  }

  void clearWordLookup() {
    _requestVersion += 1;
    state = state.copyWith(clearWordLookup: true, wordLookupHistory: []);
  }

  void _applyWordLookupResult(DictionaryLookupResult result) {
    state = state.copyWith(
      selectedWord: result.request.displayWord,
      selectedWordContext: result.request.contextText,
      selectedWordContextStart: result.request.contextWordStart,
      selectedWordContextEnd: result.request.contextWordEnd,
      selectedWordEntry: result.entry,
      selectedWordTranslation: result.primaryDefinition,
      selectedWordLookupResult: result,
    );
  }

  Future<DictionaryLookupResult> _withDictionaryFallbacks(
    DictionaryLookupResult result,
  ) async {
    if (result.hasDictionaryContent || result.hasDictionaryError) {
      return result;
    }

    final reader = ref.read(readingProvider);
    final request = result.request;
    final compoundAnalysis = request.languageCode == 'en'
        ? _compoundAnalyzer(reader).analyze(request.query)
        : null;
    final bookContexts = await _bookContextSnippets(reader, request);

    if (compoundAnalysis == null && bookContexts.isEmpty) return result;
    return result.copyWith(
      compoundAnalysis: compoundAnalysis,
      bookContexts: bookContexts,
    );
  }

  CompoundWordAnalyzer _compoundAnalyzer(ReadingProvider reader) {
    return CompoundWordAnalyzer(
      isKnownWord: (word) {
        final normalized = reader.activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints.containsKey(word) ||
            _compoundMeaningHints.containsKey(normalized) ||
            (_wordLevelService.hasWord(word)) ||
            (_wordLevelService.hasWord(normalized));
      },
      getMeaning: (word) {
        final normalized = reader.activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints[word] ??
            _compoundMeaningHints[normalized];
      },
    );
  }

  Future<List<BookContextSnippet>> _bookContextSnippets(
    ReadingProvider reader,
    DictionaryLookupRequest request,
  ) async {
    final book = reader.book;
    final query = request.query;
    if (book == null || query.isEmpty) return const [];

    final snippets = <BookContextSnippet>[];
    await for (final progress in ReadingSearchService.search(
      book,
      query,
      limit: 5,
    )) {
      final result = progress.result;
      if (result == null) continue;
      snippets.add(
        BookContextSnippet(
          text: result.snippet,
          chapterIndex: result.chapterIndex,
          chapterTitle: result.chapterTitle,
        ),
      );
    }
    return snippets;
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _wordContextService.examplesFor(word);
  }

  Future<void> speakWord(String word) async {
    await _pronunciation.speakWord(word);
  }

  void setAIWordAnalysis(WordAnalysis? analysis) {
    state = state.copyWith(aiWordAnalysis: analysis);
  }

  void setAnalyzingWord(bool value) {
    state = state.copyWith(isAnalyzingWord: value);
  }

  static const _compoundMeaningHints = <String, String>{
    'god': '神',
    'gods': '众神',
    'wood': '树林',
    'dragon': '龙',
    'glass': '玻璃',
    'king': '国王',
    'road': '道路',
  };

  String? _nonEmptyOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  ({String? text, int? wordStart, int? wordEnd}) _normalizeLookupContext(
    String? contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    final raw = contextText;
    if (raw == null) return (text: null, wordStart: null, wordEnd: null);

    final leadingWhitespace = raw.length - raw.trimLeft().length;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (text: null, wordStart: null, wordEnd: null);
    }

    if (contextWordStart == null || contextWordEnd == null) {
      return (text: trimmed, wordStart: null, wordEnd: null);
    }

    final normalizedStart = contextWordStart - leadingWhitespace;
    final normalizedEnd = contextWordEnd - leadingWhitespace;
    final hasValidRange = normalizedStart >= 0 &&
        normalizedEnd > normalizedStart &&
        normalizedEnd <= trimmed.length;

    return (
      text: trimmed,
      wordStart: hasValidRange ? normalizedStart : null,
      wordEnd: hasValidRange ? normalizedEnd : null,
    );
  }
}

final wordLookupNotifierProvider =
    NotifierProvider<WordLookupNotifier, WordLookupState>(
  WordLookupNotifier.new,
);
