import 'package:flow_read/models/book_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes language confidence and explanation language override', () {
    final metadata = BookMetadata(
      id: 'book-1',
      title: 'Fixture',
      author: 'Author',
      sourcePath: '/tmp/book.epub',
      sourceLanguage: 'en',
      sourceLanguageOverride: 'ja',
      languageConfidence: 0.9,
      targetExplanationLanguage: 'en',
    );

    final restored = BookMetadata.fromJson(metadata.toJson());

    expect(restored.sourceLanguage, 'en');
    expect(restored.sourceLanguageOverride, 'ja');
    expect(restored.languageConfidence, 0.9);
    expect(restored.targetExplanationLanguage, 'en');
    expect(restored.effectiveSourceLanguage, 'ja');
    expect(restored.effectiveTargetExplanationLanguage('zh'), 'en');
  });

  test('copyWith preserves language metadata by default', () {
    final metadata = BookMetadata(
      id: 'book-1',
      title: 'Fixture',
      author: 'Author',
      sourcePath: '/tmp/book.epub',
      languageConfidence: 0.5,
      targetExplanationLanguage: 'ja',
    );

    final updated = metadata.copyWith(title: 'Updated');

    expect(updated.title, 'Updated');
    expect(updated.languageConfidence, 0.5);
    expect(updated.targetExplanationLanguage, 'ja');
    expect(updated.effectiveTargetExplanationLanguage('zh'), 'ja');
  });
}
