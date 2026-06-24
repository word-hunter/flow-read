import 'dart:convert';

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
  final String? contextBundle;

  const TextAnalysisPromptRequest({
    required this.selectedText,
    required this.currentPassage,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
    this.contextBundle,
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
  final String? contextBundle;

  const WordAnalysisPromptRequest({
    required this.word,
    required this.sentence,
    required this.chapterContext,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
    this.contextBundle,
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

class ParagraphInsightPromptRequest {
  final String paragraphText;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;
  final String? contextBundle;

  const ParagraphInsightPromptRequest({
    required this.paragraphText,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
    this.contextBundle,
  });
}

class CharacterMergePromptRequest {
  final List<Map<String, dynamic>> characterEntries;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;

  const CharacterMergePromptRequest({
    required this.characterEntries,
    required this.sourceLanguage,
    required this.outputLanguage,
  });
}

class BookSynthesisPromptRequest {
  final String bookId;
  final String bookTitle;
  final String? author;
  final int startChapterIndex;
  final int endChapterIndex;
  final double coverage;
  final String scopeHash;
  final String analysisSchemaVersion;
  final SourceLanguage sourceLanguage;
  final OutputLanguage outputLanguage;
  final SpoilerBoundary spoilerBoundary;
  final List<Map<String, dynamic>> chapterSummaries;
  final List<Map<String, dynamic>> characterCards;
  final List<Map<String, dynamic>> storyEvents;
  final List<Map<String, dynamic>> locations;
  final List<String> themes;
  final bool budgetDowngraded;

  const BookSynthesisPromptRequest({
    required this.bookId,
    required this.bookTitle,
    this.author,
    required this.startChapterIndex,
    required this.endChapterIndex,
    required this.coverage,
    required this.scopeHash,
    required this.analysisSchemaVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.spoilerBoundary,
    this.chapterSummaries = const [],
    this.characterCards = const [],
    this.storyEvents = const [],
    this.locations = const [],
    this.themes = const [],
    this.budgetDowngraded = false,
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
    String? userProfile,
  }) {
    final parts = <String>[
      flowReadRole(sourceLanguage),
      PromptSections.outputLanguage(outputLanguage),
      evidenceRules(),
      PromptSections.spoilerBoundary(spoilerBoundary),
      learningFocus(sourceLanguage),
    ];
    if (userProfile != null && userProfile.isNotEmpty) {
      parts.add(
        'Reader profile: the reader shows the following learning patterns. '
        'Adjust your explanations to address these when relevant (keep under 200 tokens). '
        '$userProfile',
      );
    }
    return parts.join('\n');
  }
}

class PromptBuilder {
  static const currentPromptVersion = 3;

  final String? userProfile;

  const PromptBuilder({this.userProfile});

  String _preamble({
    required SourceLanguage sourceLanguage,
    required OutputLanguage outputLanguage,
    required SpoilerBoundary spoilerBoundary,
  }) {
    return PromptSections.preamble(
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      spoilerBoundary: spoilerBoundary,
      userProfile: userProfile,
    );
  }

  PromptBuildResult buildChapterSummary(ChapterSummaryPromptRequest request) {
    final langName = request.outputLanguage.promptLabel;
    final vocabList = request.vocabulary.take(30).join(', ');
    final systemPrompt = [
      _preamble(
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
  "reading_guidance": "1-2 sentences of reading advice ($langName)",
  "locations": [
    {
      "name": "Place name from the text",
      "description": "What this location is in this chapter ($langName)",
      "anchors": [
        {
          "chapter_index": ${request.spoilerBoundary.maxReadUnitOrder},
          "block_index": null,
          "start_offset": null,
          "end_offset": null,
          "quote_snippet": "Exact short excerpt from the source text",
          "confidence": 0.0
        }
      ],
      "confidence": 0.0
    }
  ],
  "themes": [
    "Theme keyword grounded in this chapter ($langName)"
  ],
  "source_anchors": [
    {
      "chapter_index": ${request.spoilerBoundary.maxReadUnitOrder},
      "block_index": null,
      "start_offset": null,
      "end_offset": null,
      "quote_snippet": "Exact short excerpt supporting a key event, character change, location, or theme",
      "confidence": 0.0
    }
  ]
}'''),
      'Limits: at most 8 events in source order, at most 8 key vocabulary items, at most 5 locations, and at most 3 themes. '
          'Use empty arrays for locations, themes, or source_anchors when the chapter text does not clearly support them. '
          'Fewer items are better than fabricated items.',
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

  PromptBuildResult buildBookSynthesis(BookSynthesisPromptRequest request) {
    final inputPayload = jsonEncode({
      'book': {
        'id': request.bookId,
        'title': request.bookTitle,
        if (request.author != null && request.author!.trim().isNotEmpty)
          'author': request.author,
      },
      'analysis_scope': {
        'start_chapter_index': request.startChapterIndex,
        'end_chapter_index': request.endChapterIndex,
        'scope_hash': request.scopeHash,
        'coverage': request.coverage,
        'schema_version': request.analysisSchemaVersion,
        'budget_downgraded': request.budgetDowngraded,
      },
      'chapter_summaries': request.chapterSummaries,
      'character_cards': request.characterCards,
      'story_events': request.storyEvents,
      'locations': request.locations,
      'themes': request.themes,
    });

    final systemPrompt = [
      _preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: perform the Reduce stage of a Map-Reduce book analysis. '
          'Generate a concise whole-scope synthesis from the structured data only. '
          'Do not infer characters, relationships, motivations, events, themes, or endings that are not present in the input.',
      'AnalysisScope: chapters ${request.startChapterIndex}..${request.endChapterIndex}; '
          'scope_hash=${request.scopeHash}; coverage=${request.coverage.toStringAsFixed(3)}. '
          'If budget_downgraded is true, acknowledge uncertainty by keeping claims conservative.',
      PromptSections.strictJsonSchema('''{
  "fullStoryline": "Coherent storyline for the allowed scope (${request.outputLanguage.promptLabel}, 500-1000 Chinese characters or equivalent)",
  "characterGraph": {
    "nodes": [
      {"id": "stable_character_id", "label": "Character name", "role": "Role in the provided scope", "group": "optional group"}
    ],
    "edges": [
      {
        "from": "source_character_id",
        "to": "target_character_id",
        "relation": "Relationship supported by the input (${request.outputLanguage.promptLabel})",
        "confidence": 0.0,
        "anchors": []
      }
    ]
  },
  "bookMindMap": {
    "root": {
      "id": "root",
      "label": "${request.bookTitle}",
      "children": [
        {"id": "plot", "label": "Plot", "children": []},
        {"id": "characters", "label": "Characters", "children": []},
        {"id": "themes", "label": "Themes", "children": []}
      ]
    }
  },
  "structure": "Story structure analysis with chapter references (${request.outputLanguage.promptLabel})",
  "themeAnalysis": "Theme development across the allowed scope (${request.outputLanguage.promptLabel})",
  "keyInsights": [
    "A key reading insight grounded in the input (${request.outputLanguage.promptLabel})"
  ]
}'''),
      'Limits: at most 20 graph nodes, at most 30 graph edges, at most 5 mind-map children per node, and 3-5 key insights. '
          'Prefer empty arrays over unsupported claims. Use source anchors only when the input includes them.',
    ].join('\n\n');

    final userPrompt =
        '''## Book
title: ${request.bookTitle}
book_id: ${request.bookId}
author: ${request.author ?? ''}

## AnalysisScope
start_chapter_index: ${request.startChapterIndex}
end_chapter_index: ${request.endChapterIndex}
scope_hash: ${request.scopeHash}
coverage: ${request.coverage.toStringAsFixed(3)}

## Spoiler Boundary
allowed_units: ${request.spoilerBoundary.allowedUnits}
current_unit: ${request.spoilerBoundary.currentUnitId}
scope: ${request.spoilerBoundary.scope.promptValue}

## Structured Input
$inputPayload''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildChapterPreview(ChapterPreviewPromptRequest request) {
    final vocabList = request.vocabulary.take(20).join(', ');
    final systemPrompt = [
      _preamble(
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
      _preamble(
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
    final contextStr = _contextBundleSection(request.contextBundle);
    final sourceFocus = request.sourceLanguage == SourceLanguage.japanese
        ? 'particles, predicates, omitted subjects, register, kanji/kana choices, and context-sensitive readings'
        : 'sentence structure, clauses, grammar, vocabulary, collocations, and expressions';
    final systemPrompt = [
      _preamble(
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
          'Each source field must be copied from the selected text. '
          'Use personal learning memory only when it is directly relevant.',
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
"${request.currentPassage}"$contextStr''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildTranslation(TranslationPromptRequest request) {
    final systemPrompt = [
      _preamble(
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
    final contextStr = _contextBundleSection(request.contextBundle);
    final systemPrompt = [
      _preamble(
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
      'Rules: focus on this context, keep usage tips practical, and cite or reuse source words where helpful. '
          'Use personal learning memory only when it helps avoid repeating known material or reuse saved explanations.',
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
"${request.chapterContext}"$contextStr''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildArticleSummary(ArticlePromptRequest request) {
    final systemPrompt = [
      _preamble(
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
      _preamble(
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
      _preamble(
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

  PromptBuildResult buildParagraphInsight(
    ParagraphInsightPromptRequest request,
  ) {
    final contextStr = _contextBundleSection(
      request.contextBundle,
      title: 'Additional Context from Earlier Chapters',
    );

    final systemPrompt = [
      _preamble(
        sourceLanguage: request.sourceLanguage,
        outputLanguage: request.outputLanguage,
        spoilerBoundary: request.spoilerBoundary,
      ),
      'Task: analyze this paragraph for a reader who is learning the source language. '
          'Explain what this passage is about, its narrative function, any mood shifts, '
          'key references (pronouns, titles, implications), difficult language, '
          'and why it matters at this point in the reading (without spoiling future events).',
      PromptSections.strictJsonSchema('''{
  "gist": "1-2 sentence summary of what this paragraph is about",
  "narrative_function": "setup / conflict / transition / mood_change / description",
  "has_mood_shift": true,
  "key_references": ["he -> Harry", "it -> the letter"],
  "difficult_language": ["word or phrase that may be hard to understand"],
  "why_it_matters_now": "Why this passage matters for the reader at this point in the story (no spoilers)"
}'''),
      'Rules: use provided context if available, cite source evidence, '
          'do not reveal future events. Keep explanations practical for a language learner.',
    ].join('\n\n');

    final userPrompt =
        '''## Source Language
${request.sourceLanguage.promptLabel}

## Output Language
${request.outputLanguage.promptLabel}

## Paragraph
${request.paragraphText}$contextStr''';

    return _result(request, systemPrompt, userPrompt);
  }

  PromptBuildResult buildCharacterMerge(CharacterMergePromptRequest request) {
    final spoilerBoundary = SpoilerBoundary.currentPassage();
    final entriesJson = request.characterEntries
        .map(
          (e) =>
              '{'
              '"name": "${e["name"]}", '
              '"first_seen_chapter": ${e["firstSeenChapter"] ?? 0}, '
              '"developments": ${jsonEncode(e["developments"] ?? [])}'
              '}',
        )
        .join(',\n');

    final systemPrompt = [
      PromptSections.flowReadRole(request.sourceLanguage),
      'You are processing structured character data extracted from AI chapter summaries.',
      'Task: identify characters that likely refer to the same person, '
          'and return merge suggestions.',
      'Rules: '
          '- Only suggest merges when you are confident they refer to the same character. '
          '- Titles (Mr., Lord, Captain) are often not different characters. '
          '- "the boy" / "the girl" / "the old man" may be pronouns for named characters. '
          '- For Japanese: honorifics (-san, -kun, -sama) do not create different characters. '
          '- Return confidence as "high", "medium", or "low".',
      'Output as JSON array of merge suggestions.',
    ].join('\n\n');

    final userPrompt =
        '''## Characters
[$entriesJson]

Return JSON array of suggestions like:
[{"canonical_name": "Harry Potter", "merged_names": ["Potter", "the boy"], "confidence": "high"}]''';

    return PromptBuildResult(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      promptVersion: currentPromptVersion,
      sourceLanguage: request.sourceLanguage,
      outputLanguage: request.outputLanguage,
      spoilerBoundary: spoilerBoundary,
    );
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
      ParagraphInsightPromptRequest r => r.sourceLanguage,
      BookSynthesisPromptRequest r => r.sourceLanguage,
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
      ParagraphInsightPromptRequest r => r.outputLanguage,
      BookSynthesisPromptRequest r => r.outputLanguage,
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
      ParagraphInsightPromptRequest r => r.spoilerBoundary,
      BookSynthesisPromptRequest r => r.spoilerBoundary,
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

  String _contextBundleSection(String? contextBundle, {String? title}) {
    final trimmed = contextBundle?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    return '\n\n## ${title ?? 'Personal Learning Memory Context'}\n$trimmed';
  }
}
