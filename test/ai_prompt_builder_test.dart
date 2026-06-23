import 'package:flow_ai/flow_ai.dart';
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
    expect(prompt.systemPrompt, contains('"events"'));
    expect(prompt.systemPrompt, contains('"character_developments"'));
    expect(prompt.systemPrompt, contains('"key_vocabulary"'));
    expect(prompt.systemPrompt, contains('"locations"'));
    expect(prompt.systemPrompt, contains('"themes"'));
    expect(prompt.systemPrompt, contains('"source_anchors"'));
    expect(prompt.systemPrompt, contains('Use empty arrays'));
    expect(prompt.userPrompt, contains('allowed_units: chapters 0..4'));
    expect(prompt.userPrompt, contains('Alice opened the door.'));
  });

  test('Japanese text analysis is not described as English tutoring', () {
    final prompt = const PromptBuilder().buildTextAnalysis(
      TextAnalysisPromptRequest(
        selectedText: '彼は静かにうなずいた。',
        currentPassage: '彼は静かにうなずいた。',
        sourceLanguage: SourceLanguage.japanese,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      ),
    );

    expect(prompt.systemPrompt, contains('Source language: Japanese'));
    expect(prompt.systemPrompt, contains('particles'));
    expect(prompt.userPrompt, contains('## Current Passage'));
    expect(prompt.userPrompt, isNot(contains('## Context Before')));
    expect(
      prompt.systemPrompt,
      contains('Do not describe the passage as English'),
    );
    expect(prompt.systemPrompt, isNot(contains('English reading tutor')));
  });

  test('text and word analysis prompts include learning memory context', () {
    final textPrompt = const PromptBuilder().buildTextAnalysis(
      TextAnalysisPromptRequest(
        selectedText: 'He was reluctant to admit defeat.',
        currentPassage: 'He was reluctant to admit defeat.',
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
        contextBundle:
            'Personal learning memory:\n  · Learning words: reluctant',
      ),
    );
    final wordPrompt = const PromptBuilder().buildWordAnalysis(
      WordAnalysisPromptRequest(
        word: 'reluctant',
        sentence: 'He was reluctant to admit defeat.',
        chapterContext: 'He was reluctant to admit defeat.',
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
        contextBundle:
            'Personal learning memory:\n  · Saved AI explanations:\n      - reluctant: unwilling to do something',
      ),
    );

    expect(
      textPrompt.userPrompt,
      contains('## Personal Learning Memory Context'),
    );
    expect(textPrompt.userPrompt, contains('Learning words: reluctant'));
    expect(
      wordPrompt.userPrompt,
      contains('## Personal Learning Memory Context'),
    );
    expect(wordPrompt.userPrompt, contains('Saved AI explanations'));
  });

  test('chapter preview prompt uses only opening excerpt', () {
    final prompt = const PromptBuilder().buildChapterPreview(
      ChapterPreviewPromptRequest(
        chapterTitle: 'The Door',
        openingText: 'Alice opened the door and listened.',
        vocabulary: const ['listened'],
        sourceLanguage: SourceLanguage.english,
        outputLanguage: OutputLanguage.zhHans,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: 'book-1',
          chapterIndex: 2,
        ),
      ),
    );

    expect(prompt.systemPrompt, contains('pre-reading preview'));
    expect(prompt.systemPrompt, contains('Do not summarize the whole chapter'));
    expect(prompt.userPrompt, contains('allowed_units: chapters 0..2'));
    expect(prompt.userPrompt, contains('## Opening Excerpt Only'));
    expect(prompt.userPrompt, contains('Alice opened the door'));
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
