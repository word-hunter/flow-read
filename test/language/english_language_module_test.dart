import 'package:flow_read/services/language/english_language_module.dart';
import 'package:flow_read/services/language/language_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnglishLanguageModule', () {
    const module = EnglishLanguageModule();

    test('tokenizes English words in appearance order', () {
      expect(module.tokenize('Hello, world!'), ['Hello', 'world']);
    });

    test('tokenizes to structured tokens with boundaries and offsets', () {
      final tokenized = module.tokenizeToTokens("Hello, reader's world!");

      expect(tokenized.originalText, "Hello, reader's world!");
      expect(tokenized.languageId, 'en');
      expect(tokenized.tokens.map((token) => token.surface), [
        'Hello',
        ', ',
        "reader's",
        ' ',
        'world',
        '!',
      ]);
      expect(tokenized.tokens.map((token) => token.isBoundary), [
        false,
        true,
        false,
        true,
        false,
        true,
      ]);

      final reader = tokenized.tokens[2];
      expect(reader.canonical, 'reader');
      expect(reader.startOffset, 7);
      expect(reader.endOffset, 15);
      expect(tokenized.tokenAt(8), reader);
      expect(tokenized.tokenAt(tokenized.originalText.length), isNull);
      expect(
        tokenized.tokensInRange(6, 16).map((token) => token.surface),
        [', ', "reader's", ' '],
      );
    });

    test('canonicalizes contractions and apostrophes', () {
      expect(module.canonicalize("won't"), 'will');
      expect(module.canonicalize("Reader\u2019s"), 'reader');
    });

    test('identifies common words with the configured length limit', () {
      expect(module.isCommonWord('the', maxLength: 6), isTrue);
      expect(module.isCommonWord('because', maxLength: 6), isFalse);
    });

    test('splits sentences and exposes syntax markers', () {
      expect(module.splitSentences('One. Two? Three!'), [
        'One.',
        'Two?',
        'Three!',
      ]);
      expect(module.subordinatingMarkers, contains('because'));
    });
  });

  group('LanguageRegistry', () {
    test('normalizes common EPUB language codes', () {
      expect(LanguageRegistry.normalizeLanguageCode('en-US'), 'en');
      expect(LanguageRegistry.normalizeLanguageCode('eng'), 'en');
      expect(LanguageRegistry.normalizeLanguageCode('jpn'), 'ja');
      expect(LanguageRegistry.normalizeLanguageCode('zho'), 'zh');
      expect(LanguageRegistry.normalizeLanguageCode('unknown'), isNull);
    });
  });
}
