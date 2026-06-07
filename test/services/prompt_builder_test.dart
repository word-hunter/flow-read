import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/services/prompt_builder.dart';

void main() {
  const builder = PromptBuilder();

  test('buildBookGlossaryExplanation returns valid PromptBuildResult', () {
    final result = builder.buildBookGlossaryExplanation(
      BookGlossaryPromptRequest(
        word: 'godswood',
        canonicalForm: 'godswood',
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        currentPassage: 'The godswood was silent and sacred.',
        earlierOccurrences: const ['She found peace in the godswood.'],
        relatedCharacters: const [
          CharacterCardSnippet(
            name: 'Ned Stark',
            description: 'Lord of Winterfell, often visits the godswood.',
          ),
        ],
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );

    expect(result.promptVersion, PromptBuilder.currentPromptVersion);
    expect(result.userPrompt, contains('godswood'));
    expect(result.userPrompt, contains('Ned Stark'));
    expect(result.userPrompt, contains('She found peace'));
    expect(result.sourceLanguage, SourceLanguage.english);
    expect(result.outputLanguage, OutputLanguage.zhHans);
  });

  test('buildBookGlossaryExplanation handles empty occurrences and characters',
      () {
    final result = builder.buildBookGlossaryExplanation(
      BookGlossaryPromptRequest(
        word: 'weirwood',
        canonicalForm: 'weirwood',
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.english,
        currentPassage: 'The weirwood stood ancient.',
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );

    expect(result.userPrompt, contains('weirwood'));
    expect(result.userPrompt, contains('The weirwood stood'));
    expect(result.userPrompt, isNot(contains('Earlier occurrences')));
    expect(result.userPrompt, isNot(contains('Related characters')));
    expect(result.outputLanguage, OutputLanguage.english);
  });
}
