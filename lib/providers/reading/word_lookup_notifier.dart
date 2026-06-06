import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_analysis.dart';
import '../../models/word_context_example.dart';
import '../../services/dictionary/word_repository.dart';
import '../../services/word_context_service.dart';
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
  WordContextService get _wordContextService =>
      ref.read(wordContextServiceProvider);

  @override
  WordLookupState build() {
    final reader = ref.watch(readingProvider);
    return WordLookupState(
      selectedWord: reader.selectedWord,
      selectedWordTranslation: reader.selectedWordTranslation,
      selectedWordContext: reader.selectedWordContext,
      selectedWordContextStart: reader.selectedWordContextStart,
      selectedWordContextEnd: reader.selectedWordContextEnd,
      selectedWordEntry: reader.selectedWordEntry,
      selectedWordLookupResult: reader.selectedWordLookupResult,
      isLoadingWord: reader.isLoadingWord,
      aiWordAnalysis: reader.aiWordAnalysis,
      isAnalyzingWord: reader.isAnalyzingWord,
    );
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
    final history = current != null
        ? [...state.wordLookupHistory, current]
        : state.wordLookupHistory;
    await reader.lookupRelatedWord(word);
    state = state.copyWith(
      selectedWord: reader.selectedWord,
      selectedWordTranslation: reader.selectedWordTranslation,
      selectedWordContext: reader.selectedWordContext,
      selectedWordContextStart: reader.selectedWordContextStart,
      selectedWordContextEnd: reader.selectedWordContextEnd,
      selectedWordEntry: reader.selectedWordEntry,
      selectedWordLookupResult: reader.selectedWordLookupResult,
      isLoadingWord: reader.isLoadingWord,
      wordLookupHistory: history,
    );
  }

  Future<void> _lookupWord(
    DictionaryLookupRequest request, {
    bool trackReadingLookup = false,
  }) async {
    final reader = ref.read(readingProvider);
    await reader.lookupWord(
      request.word,
      canonicalForm: request.canonicalForm,
      languageCode: request.languageCode,
      reading: request.reading,
      contextText: request.contextText,
      contextWordStart: request.contextWordStart,
      contextWordEnd: request.contextWordEnd,
      trackReadingLookup: trackReadingLookup,
    );
    state = state.copyWith(
      selectedWord: reader.selectedWord,
      selectedWordTranslation: reader.selectedWordTranslation,
      selectedWordContext: reader.selectedWordContext,
      selectedWordContextStart: reader.selectedWordContextStart,
      selectedWordContextEnd: reader.selectedWordContextEnd,
      selectedWordEntry: reader.selectedWordEntry,
      selectedWordLookupResult: reader.selectedWordLookupResult,
      isLoadingWord: reader.isLoadingWord,
    );
  }

  void goBackWordLookup() {
    if (state.wordLookupHistory.isEmpty) return;
    final history = List<DictionaryLookupResult>.from(state.wordLookupHistory);
    history.removeLast();
    final reader = ref.read(readingProvider);
    reader.goBackWordLookup();
    state = state.copyWith(
      selectedWord: reader.selectedWord,
      selectedWordTranslation: reader.selectedWordTranslation,
      selectedWordContext: reader.selectedWordContext,
      selectedWordContextStart: reader.selectedWordContextStart,
      selectedWordContextEnd: reader.selectedWordContextEnd,
      selectedWordEntry: reader.selectedWordEntry,
      selectedWordLookupResult: reader.selectedWordLookupResult,
      isLoadingWord: reader.isLoadingWord,
      wordLookupHistory: history,
    );
  }

  void clearWordLookup() {
    final reader = ref.read(readingProvider);
    reader.clearWordLookup();
    state = state.copyWith(
      selectedWord: reader.selectedWord,
      selectedWordTranslation: reader.selectedWordTranslation,
      selectedWordContext: reader.selectedWordContext,
      selectedWordContextStart: reader.selectedWordContextStart,
      selectedWordContextEnd: reader.selectedWordContextEnd,
      selectedWordEntry: reader.selectedWordEntry,
      selectedWordLookupResult: reader.selectedWordLookupResult,
      isLoadingWord: reader.isLoadingWord,
    );
  }

  List<WordContextExample> importedExamplesFor(String word) {
    final reader = ref.read(readingProvider);
    try {
      return reader.wordContextService?.examplesFor(word) ?? const [];
    } catch (_) {
      try {
        return _wordContextService.examplesFor(word);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<void> speakWord(String word) async {
    final reader = ref.read(readingProvider);
    try {
      await reader.speakWord(word);
    } catch (_) {
      // fallback if readingProvider not set up
    }
  }

  void setAIWordAnalysis(WordAnalysis? analysis) {
    state = state.copyWith(aiWordAnalysis: analysis);
  }

  void setAnalyzingWord(bool value) {
    state = state.copyWith(isAnalyzingWord: value);
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
