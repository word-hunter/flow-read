import 'compound_analysis.dart';

class DictionaryLookupException implements Exception {
  const DictionaryLookupException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class DictionaryEntry {
  final String word;
  final String? phonetic;
  final List<Meaning> meanings;
  final String? sourceName;
  final String? sourceUrl;
  final String? audioUrl;
  final String? htmlContent;
  final bool fromCache;
  final String? errorMessage;
  final String? parserVersion;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    required this.meanings,
    this.sourceName,
    this.sourceUrl,
    this.audioUrl,
    this.htmlContent,
    this.fromCache = false,
    this.errorMessage,
    this.parserVersion,
  });

  bool get isEmpty =>
      meanings.isEmpty && phonetic == null && (errorMessage ?? '').isEmpty;

  DictionaryEntry copyWith({
    String? word,
    String? phonetic,
    List<Meaning>? meanings,
    String? sourceName,
    String? sourceUrl,
    String? audioUrl,
    String? htmlContent,
    bool? fromCache,
    String? errorMessage,
    String? parserVersion,
  }) {
    return DictionaryEntry(
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      meanings: meanings ?? this.meanings,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      htmlContent: htmlContent ?? this.htmlContent,
      fromCache: fromCache ?? this.fromCache,
      errorMessage: errorMessage ?? this.errorMessage,
      parserVersion: parserVersion ?? this.parserVersion,
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> examples;

  const Meaning({
    required this.partOfSpeech,
    required this.definitions,
    this.examples = const [],
  });
}

class DictionaryLookupRequest {
  final String word;
  final String languageCode;
  final String canonicalForm;
  final String? reading;
  final String? contextText;
  final int? contextWordStart;
  final int? contextWordEnd;

  DictionaryLookupRequest({
    required this.word,
    this.languageCode = 'en',
    String? canonicalForm,
    this.reading,
    this.contextText,
    this.contextWordStart,
    this.contextWordEnd,
  }) : canonicalForm = canonicalForm ?? word;

  String get query => canonicalForm.trim().toLowerCase();
  String get displayWord {
    final trimmed = word.trim();
    return trimmed.isEmpty ? word : trimmed;
  }
}

class DictionaryLookupResult {
  final DictionaryLookupRequest request;
  final DictionaryEntry? entry;
  final String? primaryDefinition;
  final CompoundAnalysisResult? compoundAnalysis;
  final List<BookContextSnippet> bookContexts;

  const DictionaryLookupResult({
    required this.request,
    required this.entry,
    required this.primaryDefinition,
    this.compoundAnalysis,
    this.bookContexts = const [],
  });

  bool get hasDictionaryContent {
    final current = entry;
    if (current == null) return false;
    return current.meanings.isNotEmpty ||
        (current.phonetic?.trim().isNotEmpty ?? false) ||
        (current.htmlContent?.trim().isNotEmpty ?? false);
  }

  bool get hasDictionaryError =>
      entry?.errorMessage?.trim().isNotEmpty ?? false;

  bool get fromDictionary => hasDictionaryContent;

  bool get hasAnyResult =>
      hasDictionaryContent ||
      hasDictionaryError ||
      (primaryDefinition?.trim().isNotEmpty ?? false) ||
      compoundAnalysis != null ||
      bookContexts.isNotEmpty;

  factory DictionaryLookupResult.fromEntry({
    required DictionaryLookupRequest request,
    required DictionaryEntry? entry,
  }) {
    return DictionaryLookupResult(
      request: request,
      entry: entry,
      primaryDefinition: entry?.meanings
          .expand((meaning) => meaning.definitions)
          .firstOrNull,
    );
  }

  DictionaryLookupResult copyWith({
    DictionaryEntry? entry,
    String? primaryDefinition,
    CompoundAnalysisResult? compoundAnalysis,
    List<BookContextSnippet>? bookContexts,
  }) {
    return DictionaryLookupResult(
      request: request,
      entry: entry ?? this.entry,
      primaryDefinition: primaryDefinition ?? this.primaryDefinition,
      compoundAnalysis: compoundAnalysis ?? this.compoundAnalysis,
      bookContexts: bookContexts ?? this.bookContexts,
    );
  }
}

class BookContextSnippet {
  final String text;
  final int chapterIndex;
  final String chapterTitle;

  const BookContextSnippet({
    required this.text,
    required this.chapterIndex,
    required this.chapterTitle,
  });
}

abstract class WordRepository {
  Future<DictionaryEntry?> lookup(String word, {String languageCode = 'en'});
}

extension WordRepositoryLookupRequest on WordRepository {
  Future<DictionaryLookupResult> lookupRequest(
    DictionaryLookupRequest request,
  ) async {
    final entry = await lookup(
      request.query,
      languageCode: request.languageCode,
    );
    return DictionaryLookupResult.fromEntry(request: request, entry: entry);
  }
}
