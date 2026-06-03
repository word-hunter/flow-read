import 'package:flow_read/services/language/english_language_module.dart';
import 'package:flow_read/services/language/language_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnglishLanguageModule', () {
    const module = EnglishLanguageModule();

    test('tokenizes English words in appearance order', () {
      expect(module.tokenize('Hello, world!'), ['Hello', 'world']);
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
