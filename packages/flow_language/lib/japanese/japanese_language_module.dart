import '../language_module.dart';
import '../reading_token.dart';
import 'japanese_common_words.dart';

class JapaneseLanguageModule implements LanguageModule {
  const JapaneseLanguageModule();

  @override
  String get languageCode => 'ja';

  @override
  String get languageName => '日本語';

  static final _kanjiWithOkurigana = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]+'
    r'[\u3040-\u309F]*',
  );

  static final _katakana = RegExp(
    r'[\u30A0-\u30FF\u31F0-\u31FF\uFF66-\uFF9F][\u30A0-\u30FF\u31F0-\u31FF\uFF66-\uFF9Fー]*',
  );

  static final _hiragana = RegExp(r'[\u3040-\u309F]{2,}');

  @override
  RegExp get wordPattern => RegExp(
    '(?:${_kanjiWithOkurigana.pattern})'
    '|(?:${_katakana.pattern})'
    '|(?:${_hiragana.pattern})',
  );

  @override
  List<String> tokenize(String text) {
    return wordPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  @override
  TokenizedText tokenizeToTokens(String text) {
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
      createdAt: DateTime.now(),
    );
  }

  @override
  String canonicalize(String word) {
    return word.trim();
  }

  @override
  bool isCommonWord(String word, {int? maxLength}) {
    final canonical = canonicalize(word);
    if (canonical.isEmpty) return true;
    if (_isSingleHiragana(canonical)) return true;
    return japaneseCommonWords.contains(canonical);
  }

  @override
  List<String> splitSentences(String text) {
    return text.split(RegExp(r'(?<=[。！？\n])\s*'));
  }

  @override
  int wordCount(String text) {
    return wordPattern.allMatches(text).length;
  }

  @override
  String? get dictionaryAssetPath => null;

  @override
  List<String> get supportedLevelKeys =>
      const ['n5', 'n4', 'n3', 'n2', 'n1', 'o'];

  @override
  Set<String> get subordinatingMarkers => _japaneseSubordinators;

  static bool _isSingleHiragana(String s) {
    if (s.length != 1) return false;
    final code = s.codeUnitAt(0);
    return code >= 0x3040 && code <= 0x309F;
  }

  static const _japaneseSubordinators = {
    'から',
    'ので',
    'けど',
    'けれど',
    'けれども',
    'ながら',
    'ば',
    'たら',
    'のに',
    'ても',
    'でも',
    'ところ',
    'ものの',
    'とはいえ',
    'にもかかわらず',
    'つつ',
    'ように',
    'ために',
    'として',
    'について',
    'に対して',
    'において',
    'によって',
    'に関して',
  };
}
