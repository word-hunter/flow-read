abstract class Tokenizer {
  RegExp get wordPattern;

  List<String> tokenize(String text);

  String canonicalize(String word);

  bool isCommonWord(String word, {int? maxLength});
}

abstract class SentenceSplitter {
  List<String> splitSentences(String text);
}

abstract class SyntaxMarkerProvider {
  Set<String> get subordinatingMarkers;
}

abstract class LanguageModule
    implements Tokenizer, SentenceSplitter, SyntaxMarkerProvider {
  String get languageCode;
  String get languageName;
}
