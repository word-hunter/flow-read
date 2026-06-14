import 'dart:async';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_context_example.dart';
import '../../services/compound_word_analyzer.dart';
import '../../services/reading_search_service.dart';
import '../../services/word_context_service.dart';
import '../settings_provider.dart';
import 'bookshelf_notifier.dart';
import 'current_book_notifier.dart';
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
    this.visualDefinition,
    this.isLoadingVisualHint = false,
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
  final VisualDefinition? visualDefinition;
  final bool isLoadingVisualHint;

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
    VisualDefinition? visualDefinition,
    bool? isLoadingVisualHint,
    bool clearWordLookup = false,
    bool clearAIAnalysis = false,
    bool clearVisualHint = false,
  }) {
    return WordLookupState(
      selectedWord: clearWordLookup
          ? null
          : (selectedWord ?? this.selectedWord),
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
      selectedWordEntry: clearWordLookup
          ? null
          : (selectedWordEntry ?? this.selectedWordEntry),
      selectedWordLookupResult: clearWordLookup
          ? null
          : (selectedWordLookupResult ?? this.selectedWordLookupResult),
      wordLookupHistory: wordLookupHistory ?? this.wordLookupHistory,
      isLoadingWord: isLoadingWord ?? this.isLoadingWord,
      aiWordAnalysis: clearAIAnalysis
          ? null
          : (aiWordAnalysis ?? this.aiWordAnalysis),
      isAnalyzingWord: isAnalyzingWord ?? this.isAnalyzingWord,
      visualDefinition: clearWordLookup || clearVisualHint
          ? null
          : (visualDefinition ?? this.visualDefinition),
      isLoadingVisualHint: clearWordLookup || clearVisualHint
          ? false
          : (isLoadingVisualHint ?? this.isLoadingVisualHint),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WordLookupState &&
        other.selectedWord == selectedWord &&
        other.selectedWordTranslation == selectedWordTranslation &&
        other.isLoadingWord == isLoadingWord &&
        other.isAnalyzingWord == isAnalyzingWord &&
        other.isLoadingVisualHint == isLoadingVisualHint &&
        other.visualDefinition == visualDefinition;
  }

  @override
  int get hashCode => Object.hash(
    selectedWord,
    selectedWordTranslation,
    isLoadingWord,
    isAnalyzingWord,
    isLoadingVisualHint,
    visualDefinition,
  );
}

class WordLookupNotifier extends Notifier<WordLookupState> {
  static const _compoundMeaningHints = <String, String>{
    'god': '神',
    'gods': '众神',
    'wood': '树林',
    'dragon': '龙',
    'glass': '玻璃',
    'king': '国王',
    'road': '道路',
  };

  int _wordLookupRequestVersion = 0;

  WordRepository get _wordRepo => ref.read(wordRepositoryProvider);
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
    final activeModule = _activeLanguageModule;
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
    final current = state.selectedWordLookupResult;
    final history = current != null
        ? [...state.wordLookupHistory, current]
        : state.wordLookupHistory;
    await _lookupWord(
      DictionaryLookupRequest(
        word: word,
        languageCode: _activeLanguageModule.languageCode,
        canonicalForm: _activeLanguageModule.canonicalize(word),
      ),
    );
    state = state.copyWith(wordLookupHistory: history);
  }

  Future<void> _lookupWord(
    DictionaryLookupRequest request, {
    bool trackReadingLookup = false,
  }) async {
    final requestVersion = ++_wordLookupRequestVersion;
    state = state.copyWith(
      selectedWord: request.displayWord,
      selectedWordTranslation: null,
      selectedWordContext: request.contextText,
      selectedWordContextStart: request.contextWordStart,
      selectedWordContextEnd: request.contextWordEnd,
      selectedWordEntry: null,
      selectedWordLookupResult: null,
      isLoadingWord: true,
      clearVisualHint: true,
    );

    final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (trackReadingLookup && activeBookId != null && book != null) {
      final analytics = ref.read(learningAnalyticsServiceProvider);
      await analytics.recordLookup(
        bookId: activeBookId,
        chapterIndex: ref.read(currentBookNotifierProvider).currentChapter,
        word: request.displayWord,
      );
    }
    if (requestVersion != _wordLookupRequestVersion) return;

    final glossaryResult = await _checkBookGlossary(request);
    if (glossaryResult != null) {
      if (requestVersion != _wordLookupRequestVersion) return;
      _applyWordLookupResult(glossaryResult);
      state = state.copyWith(isLoadingWord: false);
      return;
    }

    var result = await _wordRepo.lookupRequest(request);
    if (requestVersion != _wordLookupRequestVersion) return;
    result = await _withDictionaryFallbacks(result);
    if (requestVersion != _wordLookupRequestVersion) return;
    _applyWordLookupResult(result);
    state = state.copyWith(isLoadingWord: false);
    unawaited(_fetchVisualHint(request.query, requestVersion));
  }

  void goBackWordLookup() {
    if (state.wordLookupHistory.isEmpty) return;
    final history = List<DictionaryLookupResult>.from(state.wordLookupHistory)
      ..removeLast();
    final previous = state.wordLookupHistory.last;
    _applyWordLookupResult(previous);
    state = state.copyWith(
      isLoadingWord: false,
      wordLookupHistory: history,
    );
  }

  void clearWordLookup() {
    _wordLookupRequestVersion += 1;
    state = state.copyWith(clearWordLookup: true, isLoadingWord: false);
  }

  List<WordContextExample> importedExamplesFor(String word) {
    return _wordContextService.examplesFor(word);
  }

  Future<void> speakWord(String word) async {
    final pronunciation = ref.read(pronunciationServiceProvider);
    await pronunciation.speakWord(word);
  }

  void setAIWordAnalysis(WordAnalysis? analysis) {
    state = state.copyWith(aiWordAnalysis: analysis);
  }

  void setAnalyzingWord(bool value) {
    state = state.copyWith(isAnalyzingWord: value);
  }

  // ---- Internal helpers ----

  Future<void> _fetchVisualHint(String word, int requestVersion) async {
    final settings = ref.read(settingsProvider);
    if (!settings.visualDictionaryEnabled) return;
    state = state.copyWith(isLoadingVisualHint: true);
    try {
      final service = ref.read(visualDictionaryServiceProvider);
      final result = await service.lookup(word);
      if (requestVersion != _wordLookupRequestVersion) return;
      state = state.copyWith(
        visualDefinition: result,
        isLoadingVisualHint: false,
      );
    } on Object {
      state = state.copyWith(isLoadingVisualHint: false);
    }
  }

  LanguageModule get _activeLanguageModule {
    final settings = ref.read(settingsProvider);
    final code = settings.activeSourceLanguage;
    final module = LanguageRegistry.instance.get(code);
    if (module == null) throw StateError('Language "$code" not registered');
    return module;
  }

  void _applyWordLookupResult(DictionaryLookupResult result) {
    state = state.copyWith(
      selectedWordLookupResult: result,
      selectedWord: result.request.displayWord,
      selectedWordContext: result.request.contextText,
      selectedWordContextStart: result.request.contextWordStart,
      selectedWordContextEnd: result.request.contextWordEnd,
      selectedWordEntry: result.entry,
      selectedWordTranslation: result.primaryDefinition,
    );
  }

  Future<DictionaryLookupResult?> _checkBookGlossary(
    DictionaryLookupRequest request,
  ) async {
    final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
    if (activeBookId == null) return null;
    if (!ref.read(appDatabaseProvider).hasValue) return null;

    final glossaryService = ref.read(bookGlossaryServiceProvider);
    final entry = await glossaryService.getEntry(
      bookId: activeBookId,
      word: request.query,
      canonicalForm: request.canonicalForm,
    );
    if (entry == null || entry.explanation.trim().isEmpty) return null;

    return DictionaryLookupResult.fromEntry(
      request: request,
      entry: null,
    ).copyWith(primaryDefinition: entry.explanation);
  }

  Future<DictionaryLookupResult> _withDictionaryFallbacks(
    DictionaryLookupResult result,
  ) async {
    if (result.hasDictionaryContent || result.hasDictionaryError) {
      return result;
    }

    final request = result.request;
    final compoundAnalysis = request.languageCode == 'en'
        ? _compoundAnalyzer().analyze(request.query)
        : null;
    final bookContexts = await _bookContextSnippets(request);

    if (compoundAnalysis == null && bookContexts.isEmpty) return result;
    return result.copyWith(
      compoundAnalysis: compoundAnalysis,
      bookContexts: bookContexts,
    );
  }

  CompoundWordAnalyzer _compoundAnalyzer() {
    final wordLevelService = ref.read(wordLevelServiceProvider);
    return CompoundWordAnalyzer(
      isKnownWord: (word) {
        final normalized = _activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints.containsKey(word) ||
            _compoundMeaningHints.containsKey(normalized) ||
            wordLevelService.hasWord(word) ||
            wordLevelService.hasWord(normalized);
      },
      getMeaning: (word) {
        final normalized = _activeLanguageModule.canonicalize(word);
        return _compoundMeaningHints[word] ?? _compoundMeaningHints[normalized];
      },
    );
  }

  Future<List<BookContextSnippet>> _bookContextSnippets(
    DictionaryLookupRequest request,
  ) async {
    final book = ref.read(bookshelfNotifierProvider).book;
    final query = request.query;
    if (book == null || query.isEmpty) return const [];

    final snippets = <BookContextSnippet>[];
    await for (final progress in ReadingSearchService.search(
      book,
      query,
      limit: 5,
    )) {
      final searchResult = progress.result;
      if (searchResult == null) continue;
      snippets.add(
        BookContextSnippet(
          text: searchResult.snippet,
          chapterIndex: searchResult.chapterIndex,
          chapterTitle: searchResult.chapterTitle,
        ),
      );
    }
    return snippets;
  }

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
    final hasValidRange =
        normalizedStart >= 0 &&
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
