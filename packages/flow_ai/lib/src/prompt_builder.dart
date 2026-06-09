import 'models/ai_summary.dart';

enum SourceLanguage {
  english('en', 'English'),
  japanese('ja', 'Japanese');

  const SourceLanguage(this.code, this.promptLabel);

  final String code;
  final String promptLabel;

  static SourceLanguage fromCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    if (normalized.startsWith('ja') || normalized == 'jp') {
      return SourceLanguage.japanese;
    }
    return SourceLanguage.english;
  }

  static SourceLanguage inferFromText(String text) {
    final sample = text.length <= 2400 ? text : text.substring(0, 2400);
    final japaneseChars = RegExp(
      r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]',
    ).allMatches(sample).length;
    final latinWords = RegExp(
      r"[A-Za-z]+(?:[-'][A-Za-z]+)?",
    ).allMatches(sample).length;
    if (japaneseChars >= 8 && japaneseChars > latinWords) {
      return SourceLanguage.japanese;
    }
    return SourceLanguage.english;
  }
}

enum OutputLanguage {
  zhHans('zh', 'Chinese (Simplified)'),
  english('en', 'English');

  const OutputLanguage(this.code, this.promptLabel);

  final String code;
  final String promptLabel;

  static OutputLanguage fromCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    if (normalized == 'en' || normalized.startsWith('en-')) {
      return OutputLanguage.english;
    }
    return OutputLanguage.zhHans;
  }
}

enum AIContextScope {
  currentPassage('current_passage'),
  currentChapter('current_chapter'),
  readSoFar('read_so_far'),
  fullBook('full_book');

  const AIContextScope(this.promptValue);

  final String promptValue;
}

class SpoilerBoundary {
  final String bookId;
  final String currentUnitId;
  final int maxReadUnitOrder;
  final String unitType;
  final AIContextScope scope;

  const SpoilerBoundary({
    required this.bookId,
    required this.currentUnitId,
    required this.maxReadUnitOrder,
    required this.unitType,
    required this.scope,
  });

  factory SpoilerBoundary.chapter({
    required String bookId,
    required int chapterIndex,
    AIContextScope scope = AIContextScope.currentChapter,
  }) {
    return SpoilerBoundary(
      bookId: bookId,
      currentUnitId: 'chapter:$chapterIndex',
      maxReadUnitOrder: chapterIndex,
      unitType: 'chapter',
      scope: scope,
    );
  }

  factory SpoilerBoundary.currentPassage() {
    return const SpoilerBoundary(
      bookId: 'selection',
      currentUnitId: 'current_passage',
      maxReadUnitOrder: 0,
      unitType: 'passage',
      scope: AIContextScope.currentPassage,
    );
  }

  String get allowedUnits {
    if (unitType == 'chapter') {
      return 'chapters 0..$maxReadUnitOrder';
    }
    return 'the provided current passage only';
  }
}

class PromptBuildResult {
  final String systemPrompt;
  final String userPrompt;
  final int promptVersion;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const PromptBuildResult({
    required this.systemPrompt,
    required this.userPrompt,
    required this.promptVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class ChapterSummaryPromptRequest {
  final String chapterText;
  final List<String> vocabulary;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const ChapterSummaryPromptRequest({
    required this.chapterText,
    required this.vocabulary,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class ChapterPreviewPromptRequest {
  final String chapterTitle;
  final String openingText;
  final List<String> vocabulary;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const ChapterPreviewPromptRequest({
    required this.chapterTitle,
    required this.openingText,
    required this.vocabulary,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class PracticePromptRequest {
  final String chapterText;
  final List<String> vocabulary;
  final List<SummaryEvent> events;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const PracticePromptRequest({
    required this.chapterText,
    required this.vocabulary,
    required this.events,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class TextAnalysisPromptRequest {
  final String selectedText;
  final String currentPassage;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const TextAnalysisPromptRequest({
    required this.selectedText,
    required this.currentPassage,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class TranslationPromptRequest {
  final String selectedText;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const TranslationPromptRequest({
    required this.selectedText,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class WordAnalysisPromptRequest {
  final String word;
  final String sentence;
  final String chapterContext;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const WordAnalysisPromptRequest({
    required this.word,
    required this.sentence,
    required this.chapterContext,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
  });
}

class ArticlePromptRequest {
  final String surfaceLabel;
  final String title;
  final String text;
  final String? url;
  final String? question;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;

  const ArticlePromptRequest({
    required this.surfaceLabel,
    required this.title,
    required this.text,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
    this.url,
    this.question,
  });
}

class BookGlossaryPromptRequest {
  final String word;
  final String canonicalForm;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final String currentPassage;
  final List<String> earlierOccurrences;
  final List<CharacterCardSnippet> relatedCharacters;
  final SpoilerBoundary spoilerBoundary;

  const BookGlossaryPromptRequest({
    required this.word,
    required this.canonicalForm,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.currentPassage,
    required this.spoilerBoundary,
    this.earlierOccurrences = const [],
    this.relatedCharacters = const [],
  });
}

class CharacterCardSnippet {
  final String name;
  final String description;

  const CharacterCardSnippet({
    required this.name,
    required this.description,
  });
}

class PromptSections {
  static String flowReadRole(SourceLanguage sourceLanguage) {
    return 'You are a Flow Read reading tutor embedded in a Flutter reading app. '
        'You help Chinese speakers read source-language content across EPUB, RSS, and web pages. '
        'Source language: ${sourceLanguage.promptLabel}.';
  }

  static String outputLanguage(OutputLanguage outputLanguage) {
    return 'Output language: ${outputLanguage.promptLabel}. Keep source excerpts in their original language.';
  }

  static String evidenceRules() {
    return 'Evidence rules: use ONLY the provided text and context. '
        'Do NOT use outside knowledge about the book, author, web page, or later plot. '
        'Every analysis point, event, answer, or vocabulary explanation that depends on the text MUST cite exact source text. '
        'If evidence is missing or uncertain, say so or omit the point.';
  }

  static String spoilerBoundary(SpoilerBoundary boundary) {
    return 'Spoiler boundary: scope=${boundary.scope.promptValue}; '
        'unit_type=${boundary.unitType}; current_unit=${boundary.currentUnitId}; '
        'allowed_units=${boundary.allowedUnits}. '
        'Do NOT reference or infer anything outside this boundary.';
  }

  static String learningFocus(SourceLanguage sourceLanguage) {
    switch (sourceLanguage) {
      case SourceLanguage.japanese:
        return 'Language strategy: explain Japanese particles such as は, が, を, に, で, へ, and と when relevant; '
            'notice honorifics, register shifts, omitted subjects, kanji/kana choices, and readings. '
            'Do not describe the passage as English or force English grammar labels onto Japanese text.';
      case SourceLanguage.english:
        return 'Language strategy: explain tense, clauses, modifiers, phrasal verbs, pronoun references, collocations, and literary wording when relevant.';
    }
  }

  static String strictJsonSchema(String schema) {
    return 'Output format: strict JSON object only. Do not wrap it in Markdown.\n$schema';
  }

  static String preamble({
    required SourceLanguage sourceLanguage,
    required OutputLanguage outputLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) {
    return [
      flowReadRole(sourceLanguage),
      PromptSections.outputLanguage(outputLanguage),
      evidenceRules(),
      PromptSections.spoilerBoundary(spoilerBoundary),
      learningFocus(sourceLanguage),
    ].join('\n');
  }
}

class PromptBuilder {
  static const currentPromptVersion = 1;

  const PromptBuilder();

  PromptBuildResult buildChapterSummary(ChapterSummaryPromptRequest request) {
    final langName = request.outputLanguage.promptLabel;
    final vocabList = request.vocabulary.take(30).join(', ');
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: summarize the provided chapter text for reading comprehension. '
          'Do not add events, characters, motivations, or cultural context that are not directly supported by the chapter text.',
      PromptSections.strictJsonSchema('''{
  "events": [
    {
      "description": "What happened ($langName)",
      "source": "Exact sentence or short excerpt from the source text",
      "significance": "Why this event matters ($langName)",
      "confidence": "high|medium|low"
    }
  ],
  "character_developments": [
    {
      "character": "Character name from the text",
      "change": "How this character changed or was revealed in this chapter ($langName)",
      "source": "Exact sentence or short excerpt from the source text",
      "confidence": "high|medium|low"
    }
  ],
  "key_vocabulary": [
    {
      "word": "Word or expression from the text",
      "sentence": "The source sentence containing this word or expression",
      "meaning_in_context": "Meaning in this context ($langName)",
      "why_important": "Why understanding this helps understand the chapter ($langName)"
    }
  ],
  "reading_guidance": "1-2 sentences of reading advice ($langName)"
}'''),
      'Limits: at most 8 events in source order, at most 8 key vocabulary items, and fewer items are better than fabricated items.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Chapter Text
${request.chapterText}

## Key Vocabulary to Consider
$vocabList''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildChapterPreview(ChapterPreviewPromptRequest request) {
    final vocabList = request.vocabulary.take(20).join(', ');
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: create a spoiler-safe pre-reading preview for the chapter. '
          'Use only the title, opening excerpt, and vocabulary provided. '
          'Do not summarize the whole chapter, reveal outcomes, or infer later plot.',
      PromptSections.strictJsonSchema('''{
  "setup": "What the reader should be ready to notice before reading (${request.outputLanguage.promptLabel})",
  "focus_points": [
    "A concrete reading focus that does not reveal later outcomes (${request.outputLanguage.promptLabel})"
  ],
  "vocabulary_hints": [
    "A word or expression to watch for, with a short non-spoiling hint (${request.outputLanguage.promptLabel})"
  ],
  "spoiler_boundary_note": "Short note confirming the preview uses only the provided opening context (${request.outputLanguage.promptLabel})"
}'''),
      'Limits: at most 3 focus points and at most 5 vocabulary hints. '
          'Prefer uncertainty over spoilers; say what to watch for, not what will happen.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Chapter Title
${request.chapterTitle}

## Opening Excerpt Only
${request.openingText}

## Vocabulary to Watch
$vocabList''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildPractice(PracticePromptRequest request) {
    final vocabList = request.vocabulary.take(30).join(', ');
    final eventsText = request.events.map((e) => e.description).join('; ');
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: generate multiple-choice comprehension questions based on the provided reading context. '
          'Questions and correct answers should use the source language when that best tests reading comprehension. '
          'Explanations should use ${request.outputLanguage.promptLabel}.',
      PromptSections.strictJsonSchema('''{
  "questions": [
    {
      "type": "detail|vocabulary|inference|grammar",
      "question": "Question",
      "source_excerpt": "Exact source sentence or short excerpt that supports the answer",
      "answer": "The correct answer",
      "answer_explanation": "Why this answer is correct (${request.outputLanguage.promptLabel})",
      "distractors": [
        {"text": "Wrong option A", "why_wrong": "Why A is wrong (${request.outputLanguage.promptLabel})"},
        {"text": "Wrong option B", "why_wrong": "Why B is wrong (${request.outputLanguage.promptLabel})"},
        {"text": "Wrong option C", "why_wrong": "Why C is wrong (${request.outputLanguage.promptLabel})"}
      ],
      "difficulty": "easy|medium|hard"
    }
  ]
}'''),
      'Rules: include detail, vocabulary, inference, and grammar when the text supports them. '
          'Total questions: at least 3, at most 5. Distractors must be plausible but clearly wrong from the text.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Chapter Text
${request.chapterText}

## Key Events (for reference)
$eventsText

## Vocabulary List (for reference)
$vocabList''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildTextAnalysis(TextAnalysisPromptRequest request) {
    final sourceFocus = request.sourceLanguage == SourceLanguage.japanese
        ? 'particles, predicates, omitted subjects, register, kanji/kana choices, and context-sensitive readings'
        : 'sentence structure, clauses, grammar, vocabulary, collocations, and expressions';
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: analyze ONLY the selected text. Use the current passage only to resolve meaning. Focus on $sourceFocus.',
      PromptSections.strictJsonSchema('''{
  "translation": "Contextual translation in ${request.outputLanguage.promptLabel}",
  "structure_notes": [
    {
      "source": "Exact clause or phrase from the selected text",
      "role": "main clause|subordinate clause|modifier|object|particle|predicate|register|reference|other",
      "explanation": "How this part functions (${request.outputLanguage.promptLabel})"
    }
  ],
  "grammar_points": [
    {
      "source": "Exact phrase from the selected text",
      "explanation": "Grammar explanation (${request.outputLanguage.promptLabel})",
      "difficulty": "easy|medium|hard"
    }
  ],
  "vocabulary_notes": [
    {
      "word": "Word or expression from the selected text",
      "context_meaning": "Meaning in this context (${request.outputLanguage.promptLabel})",
      "pos": "part of speech or role"
    }
  ],
  "expression_notes": [
    {
      "source": "Reusable expression or collocation from the selected text",
      "meaning": "Contextual meaning (${request.outputLanguage.promptLabel})",
      "usage": "How a learner can reuse or recognize it (${request.outputLanguage.promptLabel})"
    }
  ],
  "reading_tip": "One key reading insight (${request.outputLanguage.promptLabel})"
}'''),
      'Limits: at most 3 structure notes, 3 grammar points, 5 vocabulary notes, and 3 expression notes. '
          'Each source field must be copied from the selected text.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Selected Text
"${request.selectedText}"

## Current Passage (for reference only)
"${request.currentPassage}"''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildTranslation(TranslationPromptRequest request) {
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: translate the provided text naturally while preserving literary style, tone, and voice. '
          'Output only the translation. Do not add notes.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Text
${request.selectedText}''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildWordAnalysis(WordAnalysisPromptRequest request) {
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: analyze the word or expression as it is used in the provided sentence and local context. '
          'Focus on practical understanding and memory aids. Do not give generic dictionary content when it conflicts with the context.',
      PromptSections.strictJsonSchema('''{
  "pronunciation": "Pronunciation, IPA, or reading when available",
  "meanings": [
    {
      "meaning": "Meaning in this sentence (${request.outputLanguage.promptLabel})",
      "explanation": "Nuance and why this wording fits the context (${request.outputLanguage.promptLabel})"
    }
  ],
  "usage_tips": [
    "Practical usage tip (${request.outputLanguage.promptLabel})"
  ],
  "memory_tip": "A memorable way to remember this item (${request.outputLanguage.promptLabel})"
}'''),
      'Rules: focus on this context, keep usage tips practical, and cite or reuse source words where helpful.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}

## Word Or Expression
${request.word}

## Sentence
"${request.sentence}"

## Local Context
"${request.chapterContext}"''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildArticleSummary(ArticlePromptRequest request) {
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: summarize this reading context concisely for a learner. Cover 3-5 key points, important vocabulary or phrases, and one reading suggestion.',
    ].join('\n\n');

    final userPrompt =
        '''## Context Type
${request.surfaceLabel}

## Title
${request.title}

## URL
${request.url ?? ''}

## Text
${request.text}''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildArticleAnswer(ArticlePromptRequest request) {
    final question = request.question ?? '';
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: answer the user question using only the provided reading context. '
          'If the context does not contain enough evidence, say so clearly.',
    ].join('\n\n');

    final userPrompt =
        '''## Context Type
${request.surfaceLabel}

## Title
${request.title}

## URL
${request.url ?? ''}

## Reading Context
${request.text}

## Question
$question''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildBookGlossaryExplanation(
    BookGlossaryPromptRequest request,
  ) {
    final systemPrompt = [
      PromptSections.preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: explain the meaning of a word or phrase as it is used in this book. '
          'Use the provided passage and earlier occurrences as context. '
          'Write a concise, glossary-style explanation (1-3 sentences) '
          'suitable for a book glossary entry. '
          'If related characters are provided, mention how the word relates to them. '
          'Do not add pronunciation guides, grammar notes, or usage tips.',
    ].join('\n\n');

    final occurrenceLines = request.earlierOccurrences.isNotEmpty
        ? '\n## Earlier occurrences\n${request.earlierOccurrences.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}'
        : '';

    final characterLines = request.relatedCharacters.isNotEmpty
        ? '\n## Related characters\n${request.relatedCharacters.map((c) => '- ${c.name}: ${c.description}').join('\n')}'
        : '';

    final userPrompt =
        '''## Word
${request.word} (${request.canonicalForm})

## Current passage
${request.currentPassage}$occurrenceLines$characterLines''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult _result(
    Object request,
    String systemPrompt,
    String userPrompt,
  ) {
    final sourceLanguage = switch (request) {
      ChapterSummaryPromptRequest r => r.sourceLanguage,
      ChapterPreviewPromptRequest r => r.sourceLanguage,
      PracticePromptRequest r => r.sourceLanguage,
      TextAnalysisPromptRequest r => r.sourceLanguage,
      TranslationPromptRequest r => r.sourceLanguage,
      WordAnalysisPromptRequest r => r.sourceLanguage,
      ArticlePromptRequest r => r.sourceLanguage,
      BookGlossaryPromptRequest r => r.sourceLanguage,
      _ => SourceLanguage.english,
    };
    final outputLanguage = switch (request) {
      ChapterSummaryPromptRequest r => r.outputLanguage,
      ChapterPreviewPromptRequest r => r.outputLanguage,
      PracticePromptRequest r => r.outputLanguage,
      TextAnalysisPromptRequest r => r.outputLanguage,
      TranslationPromptRequest r => r.outputLanguage,
      WordAnalysisPromptRequest r => r.outputLanguage,
      ArticlePromptRequest r => r.outputLanguage,
      BookGlossaryPromptRequest r => r.outputLanguage,
      _ => OutputLanguage.zhHans,
    };
    final spoilerBoundary = switch (request) {
      ChapterSummaryPromptRequest r => r.spoilerBoundary,
      ChapterPreviewPromptRequest r => r.spoilerBoundary,
      PracticePromptRequest r => r.spoilerBoundary,
      TextAnalysisPromptRequest r => r.spoilerBoundary,
      TranslationPromptRequest r => r.spoilerBoundary,
      WordAnalysisPromptRequest r => r.spoilerBoundary,
      ArticlePromptRequest r => r.spoilerBoundary,
      BookGlossaryPromptRequest r => r.spoilerBoundary,
      _ => SpoilerBoundary.currentPassage(),
    };
    return PromptBuildResult(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      promptVersion: currentPromptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      spoilerBoundary: spoilerBoundary,
    );
  }
}
