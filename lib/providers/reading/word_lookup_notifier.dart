import 'dart:async';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/book_glossary_entry.dart';
import '../../models/reading_memory.dart';
import '../../models/word_context_example.dart';
import '../../services/compound_word_analyzer.dart';
import '../../services/reading_memory/reading_memory_ids.dart';
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
    this.wordMemoryCard,
    this.isLoadingWordMemory = false,
    this.bookGlossaryDraftExplanation,
    this.isGeneratingBookGlossaryExplanation = false,
    this.isSavingBookGlossaryExplanation = false,
    this.bookGlossaryError,
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
  final WordMemoryCard? wordMemoryCard;
  final bool isLoadingWordMemory;
  final String? bookGlossaryDraftExplanation;
  final bool isGeneratingBookGlossaryExplanation;
  final bool isSavingBookGlossaryExplanation;
  final String? bookGlossaryError;

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
    WordMemoryCard? wordMemoryCard,
    bool? isLoadingWordMemory,
    String? bookGlossaryDraftExplanation,
    bool? isGeneratingBookGlossaryExplanation,
    bool? isSavingBookGlossaryExplanation,
    String? bookGlossaryError,
    bool clearWordLookup = false,
    bool clearAIAnalysis = false,
    bool clearVisualHint = false,
    bool clearWordMemory = false,
    bool clearBookGlossarySuggestion = false,
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
      wordMemoryCard: clearWordLookup || clearWordMemory
          ? null
          : (wordMemoryCard ?? this.wordMemoryCard),
      isLoadingWordMemory: clearWordLookup || clearWordMemory
          ? false
          : (isLoadingWordMemory ?? this.isLoadingWordMemory),
      bookGlossaryDraftExplanation:
          clearWordLookup || clearBookGlossarySuggestion
          ? bookGlossaryDraftExplanation
          : (bookGlossaryDraftExplanation ?? this.bookGlossaryDraftExplanation),
      isGeneratingBookGlossaryExplanation:
          clearWordLookup || clearBookGlossarySuggestion
          ? isGeneratingBookGlossaryExplanation ?? false
          : (isGeneratingBookGlossaryExplanation ??
                this.isGeneratingBookGlossaryExplanation),
      isSavingBookGlossaryExplanation:
          clearWordLookup || clearBookGlossarySuggestion
          ? isSavingBookGlossaryExplanation ?? false
          : (isSavingBookGlossaryExplanation ??
                this.isSavingBookGlossaryExplanation),
      bookGlossaryError: clearWordLookup || clearBookGlossarySuggestion
          ? bookGlossaryError
          : (bookGlossaryError ?? this.bookGlossaryError),
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
        other.visualDefinition == visualDefinition &&
        other.wordMemoryCard == wordMemoryCard &&
        other.isLoadingWordMemory == isLoadingWordMemory &&
        other.bookGlossaryDraftExplanation == bookGlossaryDraftExplanation &&
        other.isGeneratingBookGlossaryExplanation ==
            isGeneratingBookGlossaryExplanation &&
        other.isSavingBookGlossaryExplanation ==
            isSavingBookGlossaryExplanation &&
        other.bookGlossaryError == bookGlossaryError;
  }

  @override
  int get hashCode => Object.hash(
    selectedWord,
    selectedWordTranslation,
    isLoadingWord,
    isAnalyzingWord,
    isLoadingVisualHint,
    visualDefinition,
    wordMemoryCard,
    isLoadingWordMemory,
    bookGlossaryDraftExplanation,
    isGeneratingBookGlossaryExplanation,
    isSavingBookGlossaryExplanation,
    bookGlossaryError,
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
    MemorySourceRef? memorySourceRef,
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
      memorySourceRef: memorySourceRef,
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
    MemorySourceRef? memorySourceRef,
  }) async {
    final requestVersion = ++_wordLookupRequestVersion;
    state = WordLookupState(
      selectedWord: request.displayWord,
      selectedWordContext: request.contextText,
      selectedWordContextStart: request.contextWordStart,
      selectedWordContextEnd: request.contextWordEnd,
      wordLookupHistory: state.wordLookupHistory,
      isLoadingWord: true,
      aiWordAnalysis: state.aiWordAnalysis,
      isAnalyzingWord: state.isAnalyzingWord,
      isLoadingWordMemory: true,
    );

    final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    final currentChapter = ref.read(currentBookNotifierProvider).currentChapter;
    if (trackReadingLookup && activeBookId != null && book != null) {
      final analytics = ref.read(learningAnalyticsServiceProvider);
      await analytics.recordLookup(
        bookId: activeBookId,
        chapterIndex: currentChapter,
        word: request.displayWord,
      );
    }
    await _recordReadingMemoryLookup(
      request,
      sourceRef:
          memorySourceRef ??
          _bookMemorySourceRef(
            trackReadingLookup: trackReadingLookup,
            activeBookId: activeBookId,
            book: book,
            chapterIndex: currentChapter,
            contextWordStart: request.contextWordStart,
            contextWordEnd: request.contextWordEnd,
          ),
    );
    if (requestVersion != _wordLookupRequestVersion) return;
    unawaited(_loadWordMemoryCard(request, requestVersion));

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
    _applyWordLookupResult(previous, preserveWordMemory: false);
    state = state.copyWith(
      isLoadingWord: false,
      wordLookupHistory: history,
      isLoadingWordMemory: true,
    );
    unawaited(_loadWordMemoryCard(previous.request, _wordLookupRequestVersion));
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
    final result = state.selectedWordLookupResult;
    await pronunciation.speakWord(
      word,
      audioUrl: result?.entry?.audioUrl,
      languageCode: result?.request.languageCode ?? 'en',
    );
  }

  void setAIWordAnalysis(WordAnalysis? analysis) {
    state = state.copyWith(aiWordAnalysis: analysis);
  }

  void setAnalyzingWord(bool value) {
    state = state.copyWith(isAnalyzingWord: value);
  }

  bool get canGenerateBookGlossaryExplanation {
    final result = state.selectedWordLookupResult;
    if (result == null ||
        result.hasDictionaryContent ||
        result.hasDictionaryError) {
      return false;
    }
    if ((result.primaryDefinition?.trim().isNotEmpty ?? false) ||
        state.bookGlossaryDraftExplanation?.trim().isNotEmpty == true) {
      return false;
    }
    final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    return activeBookId != null &&
        book != null &&
        ref.read(settingsProvider).aiFeaturesEnabled;
  }

  Future<void> generateBookGlossaryExplanation() async {
    final result = state.selectedWordLookupResult;
    if (result == null || !canGenerateBookGlossaryExplanation) return;

    final bookId = ref.read(bookshelfNotifierProvider).activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (bookId == null || book == null) return;

    state = state.copyWith(
      isGeneratingBookGlossaryExplanation: true,
      bookGlossaryError: '',
      clearBookGlossarySuggestion: true,
    );

    try {
      final request = result.request;
      final chapterIndex = ref.read(currentBookNotifierProvider).currentChapter;
      final currentPassage = _glossaryCurrentPassage(request, book);
      final explanation = await ref
          .read(aiServiceProvider)
          .explainBookGlossaryTerm(
            word: request.displayWord,
            canonicalForm: request.canonicalForm,
            currentPassage: currentPassage,
            earlierOccurrences: result.bookContexts
                .map((snippet) => snippet.text)
                .where((text) => text.trim().isNotEmpty)
                .take(5)
                .toList(growable: false),
            relatedCharacters: _relatedCharacterSnippets(
              bookId,
              currentPassage,
            ),
            sourceLanguage: SourceLanguage.inferFromText(
              '${request.displayWord} $currentPassage',
            ),
            outputLanguage: OutputLanguage.fromCode(
              ref.read(settingsProvider).targetExplanationLanguage,
            ),
            spoilerBoundary: SpoilerBoundary.chapter(
              bookId: bookId,
              chapterIndex: chapterIndex,
              scope: AIContextScope.readSoFar,
            ),
          );
      if (explanation.trim().isEmpty) {
        state = state.copyWith(
          isGeneratingBookGlossaryExplanation: false,
          bookGlossaryError: 'AI 未返回有效解释',
        );
        return;
      }
      state = state.copyWith(
        bookGlossaryDraftExplanation: explanation.trim(),
        isGeneratingBookGlossaryExplanation: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingBookGlossaryExplanation: false,
        bookGlossaryError: 'AI 推测失败: $e',
      );
    }
  }

  Future<bool> saveBookGlossaryExplanation({String? explanation}) async {
    final result = state.selectedWordLookupResult;
    if (result == null) return false;
    final text = (explanation ?? state.bookGlossaryDraftExplanation ?? '')
        .trim();
    if (text.isEmpty) return false;

    final activeBookId = ref.read(bookshelfNotifierProvider).activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (activeBookId == null || book == null) return false;

    state = state.copyWith(isSavingBookGlossaryExplanation: true);
    try {
      final request = result.request;
      final chapterIndex = ref.read(currentBookNotifierProvider).currentChapter;
      final sourceRef = MemorySourceRef(
        sourceId: ReadingMemoryIds.source(SourceKind.book, activeBookId),
        sourceKind: SourceKind.book,
        sourceTitleSnapshot: book.title,
        bookId: activeBookId,
        chapterIndex: chapterIndex,
        locationLocator: _wordLocationLocator(
          chapterIndex: chapterIndex,
          contextWordStart: request.contextWordStart,
          contextWordEnd: request.contextWordEnd,
        ),
      );
      await ref
          .read(bookGlossaryServiceProvider)
          .saveEntry(
            BookGlossaryEntry.create(
              bookId: activeBookId,
              word: request.displayWord,
              canonicalForm: request.canonicalForm,
              explanation: text,
              sourceContext: request.contextText,
            ),
          );
      await ref
          .read(readingMemoryServiceProvider)
          .saveExplanation(
            targetText: request.displayWord,
            canonical: request.canonicalForm,
            explanation: text,
            type: KnowledgeEntityType.bookTerm,
            source: ExplanationSource.ai,
            sourceRef: sourceRef,
            targetLanguage: ref
                .read(settingsProvider)
                .targetExplanationLanguage,
            promptVersion: ref.read(aiServiceProvider).promptVersion.toString(),
            languageCode: request.languageCode,
          );
      _applyWordLookupResult(result.copyWith(primaryDefinition: text));
      state = state.copyWith(
        isSavingBookGlossaryExplanation: false,
        clearBookGlossarySuggestion: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingBookGlossaryExplanation: false,
        bookGlossaryError: '保存术语失败: $e',
      );
      return false;
    }
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

  String _glossaryCurrentPassage(
    DictionaryLookupRequest request,
    Book book,
  ) {
    final contextText = request.contextText?.trim();
    if (contextText != null && contextText.isNotEmpty) return contextText;

    final chapterIndex = ref.read(currentBookNotifierProvider).currentChapter;
    if (chapterIndex >= 0 && chapterIndex < book.chapters.length) {
      final chapterText = book.chapters[chapterIndex].plainText.trim();
      if (chapterText.isNotEmpty) return chapterText;
    }
    return request.displayWord;
  }

  List<CharacterCardSnippet> _relatedCharacterSnippets(
    String bookId,
    String passage,
  ) {
    final registry = ref.read(characterRegistryProvider);
    final normalizedPassage = passage.toLowerCase();
    return registry
        .getAll(bookId)
        .where((entry) {
          final names = [
            entry.canonicalName,
            ...entry.aliases,
            ...entry.userOverrides,
          ];
          return names.any(
            (name) =>
                name.trim().isNotEmpty &&
                normalizedPassage.contains(name.toLowerCase()),
          );
        })
        .take(5)
        .map(
          (entry) => CharacterCardSnippet(
            name: entry.canonicalName,
            description: [
              if (entry.aliases.isNotEmpty)
                'aliases: ${entry.aliases.join(', ')}',
              if (entry.userOverrides.isNotEmpty)
                'user aliases: ${entry.userOverrides.join(', ')}',
            ].join('; '),
          ),
        )
        .toList(growable: false);
  }

  LanguageModule get _activeLanguageModule {
    final settings = ref.read(settingsProvider);
    final code = settings.activeSourceLanguage;
    final module = LanguageRegistry.instance.get(code);
    if (module == null) throw StateError('Language "$code" not registered');
    return module;
  }

  void _applyWordLookupResult(
    DictionaryLookupResult result, {
    bool preserveWordMemory = true,
  }) {
    state = WordLookupState(
      selectedWordLookupResult: result,
      selectedWord: result.request.displayWord,
      selectedWordContext: result.request.contextText,
      selectedWordContextStart: result.request.contextWordStart,
      selectedWordContextEnd: result.request.contextWordEnd,
      selectedWordEntry: result.entry,
      selectedWordTranslation: result.primaryDefinition,
      wordLookupHistory: state.wordLookupHistory,
      isLoadingWord: state.isLoadingWord,
      aiWordAnalysis: state.aiWordAnalysis,
      isAnalyzingWord: state.isAnalyzingWord,
      visualDefinition: state.visualDefinition,
      isLoadingVisualHint: state.isLoadingVisualHint,
      wordMemoryCard: preserveWordMemory ? state.wordMemoryCard : null,
      isLoadingWordMemory: preserveWordMemory
          ? state.isLoadingWordMemory
          : false,
    );
  }

  Future<void> _loadWordMemoryCard(
    DictionaryLookupRequest request,
    int requestVersion,
  ) async {
    final canonical = ReadingMemoryIds.normalizeCanonical(
      request.canonicalForm,
    );
    if (canonical.isEmpty) {
      if (requestVersion == _wordLookupRequestVersion) {
        state = state.copyWith(
          clearWordMemory: true,
          isLoadingWordMemory: false,
        );
      }
      return;
    }

    try {
      final card = await ref
          .read(wordMemoryServiceProvider)
          .getWordCard(
            canonical: canonical,
            displayText: request.displayWord,
            languageCode: request.languageCode,
          );
      if (!ref.mounted || requestVersion != _wordLookupRequestVersion) return;
      state = state.copyWith(wordMemoryCard: card, isLoadingWordMemory: false);
    } on Object {
      if (!ref.mounted || requestVersion != _wordLookupRequestVersion) return;
      state = state.copyWith(clearWordMemory: true, isLoadingWordMemory: false);
    }
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

  Future<void> _recordReadingMemoryLookup(
    DictionaryLookupRequest request, {
    required MemorySourceRef? sourceRef,
  }) async {
    if (sourceRef == null) return;
    final memory = ref.read(readingMemoryServiceProvider);
    await memory.recordLookup(
      targetText: request.displayWord,
      canonical: request.canonicalForm,
      languageCode: request.languageCode,
      sourceRef: sourceRef,
      sentence: request.contextText,
    );
  }

  MemorySourceRef? _bookMemorySourceRef({
    required bool trackReadingLookup,
    required String? activeBookId,
    required Book? book,
    required int chapterIndex,
    required int? contextWordStart,
    required int? contextWordEnd,
  }) {
    if (!trackReadingLookup || activeBookId == null || book == null) {
      return null;
    }
    return MemorySourceRef(
      sourceId: ReadingMemoryIds.source(SourceKind.book, activeBookId),
      sourceKind: SourceKind.book,
      sourceTitleSnapshot: book.title,
      bookId: activeBookId,
      chapterIndex: chapterIndex,
      locationLocator: _wordLocationLocator(
        chapterIndex: chapterIndex,
        contextWordStart: contextWordStart,
        contextWordEnd: contextWordEnd,
      ),
    );
  }

  String? _wordLocationLocator({
    required int chapterIndex,
    required int? contextWordStart,
    required int? contextWordEnd,
  }) {
    if (contextWordStart == null || contextWordEnd == null) {
      return 'chapter:$chapterIndex';
    }
    return 'chapter:$chapterIndex:word:$contextWordStart-$contextWordEnd';
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
