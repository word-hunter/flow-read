import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AIContextSnapshot infers scope from source', () {
    final selected = AIContextSnapshot(
      source: AIContextSource.readerSelectedText,
      selectedText: 'Winter came early.',
    );
    final chapter = AIContextSnapshot(
      source: AIContextSource.readerChapter,
      chapterContent: 'Chapter text',
    );

    expect(selected.scope, AIContextScope.currentPassage);
    expect(chapter.scope, AIContextScope.currentChapter);
    expect(selected.hasPrimaryContent, isTrue);
    expect(
      AIContextSnapshot(source: AIContextSource.readerWord).hasPrimaryContent,
      isFalse,
    );
  });

  test('reading insight profile builds compact learning focus summary', () {
    const profile = ReadingInsightProfile(
      focusAreas: {'idiom', 'tense'},
      weakPosCategories: {'verb': 0.42, 'noun': 0.12},
      lookupDensity: 18.4,
      recheckRate: 0.25,
    );

    expect(profile.isEmpty, isFalse);
    expect(profile.learningFocusSummary, contains('idiom'));
    expect(profile.learningFocusSummary, contains('verb 42%'));
    expect(profile.learningFocusSummary.length, lessThanOrEqualTo(800));
  });

  test('assistant supporting models expose expected value semantics', () {
    const settings = AIAutomationSettings(
      mode: AIAutomationMode.assisted,
      allowedActionModes: {AIAutomationMode.saving, AIAutomationMode.assisted},
    );
    final character = CharacterRegistryEntry(
      canonicalName: 'Eddard Stark',
      aliases: const {'Ned'},
      userOverrides: const {'Lord Stark'},
      updatedAt: DateTime.utc(2026),
    );
    const result = AIErrorResult(message: 'network', isRetryable: false);

    expect(settings.allows(AIAutomationMode.assisted), isTrue);
    expect(settings.canAutoSpendTokens, isFalse);
    expect(character.matches('lord stark'), isTrue);
    expect(result.isRetryable, isFalse);
    expect(AIAssistantActionType.summary.name, 'summary');
  });
}
