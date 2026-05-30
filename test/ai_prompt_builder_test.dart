import 'package:flow_read/services/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chapter summary includes language, evidence, and spoiler boundary', () {
    final prompt = const PromptBuilder().buildChapterSummary(
      ChapterSummaryPromptRequest(
        chapterText: 'Alice opened the door.',
        vocabulary: const ['opened'],
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: 'book-1',
          chapterIndex: 4,
        ),
      ),
    );

    expect(prompt.promptVersion, PromptBuilder.currentPromptVersion);
    expect(prompt.systemPrompt, contains('Output language: Chinese'));
    expect(prompt.systemPrompt, contains('Evidence rules'));
    expect(prompt.systemPrompt, contains('Spoiler boundary'));
    expect(prompt.userPrompt, contains('allowed_units: chapters 0..4'));
    expect(prompt.userPrompt, contains('Alice opened the door.'));
  });

  test('Japanese text analysis is not described as English tutoring', () {
    final prompt = const PromptBuilder().buildTextAnalysis(
      TextAnalysisPromptRequest(
        selectedText: '彼は静かにうなずいた。',
        contextBefore: '',
        contextAfter: '',
        sourceLanguage: SourceLanguage.japanese,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );

    expect(prompt.systemPrompt, contains('Source language: Japanese'));
    expect(prompt.systemPrompt, contains('particles'));
    expect(
      prompt.systemPrompt,
      contains('Do not describe the passage as English'),
    );
    expect(prompt.systemPrompt, isNot(contains('English reading tutor')));
  });

  test('article summary prompt carries browser context', () {
    final prompt = const PromptBuilder().buildArticleSummary(
      ArticlePromptRequest(
        surfaceLabel: 'Browser',
        title: 'Readable Title',
        text: 'The page content.',
        url: 'https://example.com/story',
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );

    expect(prompt.systemPrompt, contains('EPUB, RSS, and web pages'));
    expect(prompt.userPrompt, contains('Browser'));
    expect(prompt.userPrompt, contains('Readable Title'));
    expect(prompt.userPrompt, contains('https://example.com/story'));
  });
}
