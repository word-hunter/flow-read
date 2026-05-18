class DictionaryEntry {
  final String word;
  final String? phonetic;
  final List<Meaning> meanings;
  final String? sourceName;
  final String? sourceUrl;
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

abstract class WordRepository {
  Future<DictionaryEntry?> lookup(String word);
}
