import '../language_module.dart';
import '../reading_token.dart';
import 'common_words.dart';
import 'english_word_utils.dart';

class EnglishLanguageModule implements LanguageModule {
  const EnglishLanguageModule();

  @override
  String get languageCode => 'en';

  @override
  String get languageName => 'English';

  @override
  RegExp get wordPattern => englishWordPattern;

  @override
  List<String> tokenize(String text) {
    return wordPattern
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  @override
  TokenizedText tokenizeToTokens(String text) {
    return tokenizeTextWithPattern(
      text: text,
      languageCode: languageCode,
      wordPattern: wordPattern,
      canonicalize: canonicalize,
    );
  }

  @override
  String canonicalize(String word) {
    final normalized = normalizeEnglishApostrophes(word).toLowerCase().trim();
    return canonicalEnglishContraction(normalized) ?? normalized;
  }

  @override
  bool isCommonWord(String word, {int? maxLength}) {
    final canonical = canonicalize(word);
    final limit = maxLength ?? canonical.length + 1;
    return canonical.length <= limit && commonWords.contains(canonical);
  }

  @override
  List<String> splitSentences(String text) {
    return text.split(RegExp(r'(?<=[.!?])\s+'));
  }

  @override
  Set<String> get subordinatingMarkers => _englishSubordinators;

  static const _englishSubordinators = {
    'which',
    'who',
    'whom',
    'whose',
    'that',
    'when',
    'where',
    'why',
    'because',
    'since',
    'although',
    'though',
    'while',
    'if',
    'unless',
    'until',
    'after',
    'before',
    'whereas',
    'whereby',
    'wherein',
    'wherever',
    'whenever',
    'even',
    'as',
    'whether',
    'what',
  };
}
