import 'reading_token.dart';

abstract class Tokenizer {
  RegExp get wordPattern;

  List<String> tokenize(String text);

  String canonicalize(String word);

  bool isCommonWord(String word, {int? maxLength});

  String get languageCode;

  TokenizedText tokenizeToTokens(String text);
}

abstract class SentenceSplitter {
  List<String> splitSentences(String text);
}

abstract class SyntaxMarkerProvider {
  Set<String> get subordinatingMarkers;
}

abstract class LanguageModule
    implements Tokenizer, SentenceSplitter, SyntaxMarkerProvider {
  String get languageName;

  int wordCount(String text);

  String? get dictionaryAssetPath;

  List<String> get supportedLevelKeys;
}

TokenizedText tokenizeTextWithPattern({
  required String text,
  required String languageCode,
  required RegExp wordPattern,
  required String Function(String word) canonicalize,
  DateTime Function()? clock,
}) {
  final tokens = <ReadingToken>[];
  var lastIndex = 0;

  for (final match in wordPattern.allMatches(text)) {
    if (match.start > lastIndex) {
      tokens.add(
        ReadingToken(
          surface: text.substring(lastIndex, match.start),
          canonical: '',
          languageId: languageCode,
          startOffset: lastIndex,
          endOffset: match.start,
          isBoundary: true,
        ),
      );
    }

    final surface = match.group(0)!;
    tokens.add(
      ReadingToken(
        surface: surface,
        canonical: canonicalize(surface),
        languageId: languageCode,
        startOffset: match.start,
        endOffset: match.end,
      ),
    );
    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    tokens.add(
      ReadingToken(
        surface: text.substring(lastIndex),
        canonical: '',
        languageId: languageCode,
        startOffset: lastIndex,
        endOffset: text.length,
        isBoundary: true,
      ),
    );
  }

  return TokenizedText(
    originalText: text,
    languageId: languageCode,
    tokens: List.unmodifiable(tokens),
    createdAt: (clock ?? DateTime.now)(),
  );
}
