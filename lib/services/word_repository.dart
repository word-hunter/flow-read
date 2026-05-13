class DictionaryEntry {
  final String word;
  final String? phonetic;
  final List<Meaning> meanings;
  final String? sourceName;
  final String? sourceUrl;
  final String? htmlContent;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    required this.meanings,
    this.sourceName,
    this.sourceUrl,
    this.htmlContent,
  });

  bool get isEmpty => meanings.isEmpty && phonetic == null;
}

class Meaning {
  final String partOfSpeech;
  final List<String> definitions;

  const Meaning({required this.partOfSpeech, required this.definitions});
}

abstract class WordRepository {
  Future<DictionaryEntry?> lookup(String word);
}
