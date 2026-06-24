import 'dart:convert';

import 'ai_cache_service.dart';
import 'ai_service.dart';
import 'book_insight_repository.dart';
import 'models/book_analysis.dart';
import 'models/book_synthesis.dart';
import 'models/chapter_insight.dart';
import 'prompt_builder.dart';
import 'structured_ai_response_parser.dart';
import 'token_budget.dart';

class BookSynthesisService {
  BookSynthesisService({
    required AIService aiService,
    required BookInsightRepository repository,
    PromptBuilder promptBuilder = const PromptBuilder(),
    StructuredAIResponseParser parser = const StructuredAIResponseParser(),
    DateTime Function()? clock,
  }) : _aiService = aiService,
       _repository = repository,
       _promptBuilder = promptBuilder,
       _parser = parser,
       _clock = clock ?? DateTime.now;

  final AIService _aiService;
  final BookInsightRepository _repository;
  final PromptBuilder _promptBuilder;
  final StructuredAIResponseParser _parser;
  final DateTime Function() _clock;

  Future<BookSynthesisResult> synthesize(BookSynthesisRequest request) async {
    final selectedPayload = _selectPayloadForBudget(request);
    final prompt = _promptBuilder.buildBookSynthesis(
      selectedPayload.toPromptRequest(request),
    );
    final cacheKey = _cacheKeyFor(request, selectedPayload);

    if (request.useCache) {
      final cached = await _loadCached(cacheKey);
      if (cached != null) return cached;
    }

    final response = await _aiService.executePrompt(
      prompt,
      jsonMode: true,
      debugMetadata: {
        'task': 'book_synthesis',
        'bookId': request.analysisData.bookId,
        'scopeHash': request.analysisData.scope.scopeHash,
        'budgetDowngraded': selectedPayload.budgetDowngraded,
        'estimatedInputTokens': selectedPayload.estimatedInputTokens,
        'maxInputTokens': request.tokenBudget.maxInputTokens,
      },
    );

    final result = await _parser.parseStructuredResponse<BookSynthesisResult>(
      rawResponse: response,
      parser: (json) => BookSynthesisResult.fromJson(
        json,
        generatedAt: _clock().toUtc(),
      ),
      repairFn: (brokenJson) => _repairStructuredJson(prompt, brokenJson),
      fallback: BookSynthesisResult.fallback(
        rawResponse: response,
        generatedAt: _clock().toUtc(),
      ),
    );

    await _repository.saveSynthesisResult(
      key: cacheKey,
      jsonString: jsonEncode(result.toJson()),
    );
    return result;
  }

  Future<BookSynthesisResult?> _loadCached(
    BookSynthesisCacheKey cacheKey,
  ) async {
    final cached = await _repository.loadSynthesisResult(cacheKey);
    if (cached == null) return null;
    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        return BookSynthesisResult.fromJson(decoded);
      }
      if (decoded is Map) {
        return BookSynthesisResult.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  BookSynthesisCacheKey _cacheKeyFor(
    BookSynthesisRequest request,
    _BookSynthesisPromptPayload payload,
  ) {
    return BookSynthesisCacheKey(
      bookId: request.analysisData.bookId,
      synthesisType: _synthesisTypeFor(request.analysisData.scope),
      scopeHash: request.analysisData.scope.scopeHash,
      coverageHash: AICacheService.contentHashFor(jsonEncode(payload.toJson())),
      promptVersion: PromptBuilder.currentPromptVersion,
      schemaVersion: BookSynthesisResult.currentSchemaVersion,
      modelId: _aiService.modelConfigFingerprint,
      sourceLanguage: request.analysisData.scope.sourceLanguage,
      outputLanguage: request.analysisData.scope.outputLanguage,
      spoilerBoundaryHash: _spoilerBoundaryHash(
        request.analysisData.scope.spoilerBoundary,
      ),
    );
  }

  _BookSynthesisPromptPayload _selectPayloadForBudget(
    BookSynthesisRequest request,
  ) {
    final caps = [
      const _PayloadCaps(),
      const _PayloadCaps(
        maxChapterSummaries: 80,
        maxCharacters: 20,
        maxActionsPerCharacter: 4,
        maxEvents: 80,
        maxLocations: 30,
        maxThemes: 12,
        budgetDowngraded: true,
      ),
      const _PayloadCaps(
        maxChapterSummaries: 40,
        maxCharacters: 10,
        maxActionsPerCharacter: 3,
        maxEvents: 40,
        maxLocations: 15,
        maxThemes: 8,
        budgetDowngraded: true,
      ),
      const _PayloadCaps(
        maxChapterSummaries: 20,
        maxCharacters: 5,
        maxActionsPerCharacter: 2,
        maxEvents: 20,
        maxLocations: 8,
        maxThemes: 5,
        budgetDowngraded: true,
      ),
    ];

    var selected = _buildPayload(request, caps.first);
    for (final cap in caps) {
      var candidate = _buildPayload(request, cap);
      final prompt = _promptBuilder.buildBookSynthesis(
        candidate.toPromptRequest(request),
      );
      final estimatedTokens = request.tokenBudget.estimatePrompt(prompt);
      candidate = candidate.copyWith(estimatedInputTokens: estimatedTokens);
      if (request.tokenBudget.checkPrompt(prompt)) return candidate;
      selected = candidate;
    }
    return selected;
  }

  _BookSynthesisPromptPayload _buildPayload(
    BookSynthesisRequest request,
    _PayloadCaps caps,
  ) {
    final data = request.analysisData;
    return _BookSynthesisPromptPayload(
      chapterSummaries: _take(
        request.chapterSummaries.map((chapter) => chapter.toPromptJson()),
        caps.maxChapterSummaries,
      ),
      characterCards: _rankedCharacters(
        data.characters,
        caps,
      ).map((character) => _characterToJson(character, caps)).toList(),
      storyEvents: _take(
        data.storyEvents.map(_eventToJson),
        caps.maxEvents,
      ),
      locations: _take(data.locations.map(_locationToJson), caps.maxLocations),
      themes: _take(data.themes, caps.maxThemes),
      budgetDowngraded: caps.budgetDowngraded,
    );
  }

  List<CharacterCard> _rankedCharacters(
    List<CharacterCard> characters,
    _PayloadCaps caps,
  ) {
    final ranked = List<CharacterCard>.of(characters)
      ..sort((a, b) {
        final scoreA = a.activeChapters.length + a.actions.length;
        final scoreB = b.activeChapters.length + b.actions.length;
        final scoreOrder = scoreB.compareTo(scoreA);
        if (scoreOrder != 0) return scoreOrder;
        return a.firstChapter.compareTo(b.firstChapter);
      });
    return _take(ranked, caps.maxCharacters);
  }

  Map<String, dynamic> _characterToJson(
    CharacterCard character,
    _PayloadCaps caps,
  ) {
    return {
      'name': character.canonicalName,
      if (character.aliases.isNotEmpty) 'aliases': character.aliases.toList(),
      if (character.role != null) 'role': character.role,
      if (character.traits.isNotEmpty) 'traits': character.traits,
      if (character.actions.isNotEmpty)
        'actions': _take(character.actions, caps.maxActionsPerCharacter),
      'first_chapter': character.firstChapter,
      'last_chapter': character.lastChapter,
      'active_chapters': character.activeChapters.toList()..sort(),
      if (character.status != null) 'status': character.status,
      'confidence': character.confidence,
      if (character.anchors.isNotEmpty)
        'anchors': _take(character.anchors.map(_anchorToJson), 3),
    };
  }

  Map<String, dynamic> _eventToJson(StoryEvent event) {
    return {
      'description': event.description,
      if (event.participants.isNotEmpty) 'participants': event.participants,
      if (event.location != null) 'location': event.location,
      'chapter_index': event.chapterIndex,
      'confidence': event.confidence,
      if (event.anchors.isNotEmpty)
        'anchors': _take(event.anchors.map(_anchorToJson), 2),
    };
  }

  Map<String, dynamic> _locationToJson(LocationNode location) {
    return {
      'name': location.name,
      if (location.description != null) 'description': location.description,
      'chapters': location.chapters.toList()..sort(),
      'confidence': location.confidence,
      if (location.anchors.isNotEmpty)
        'anchors': _take(location.anchors.map(_anchorToJson), 2),
    };
  }

  Map<String, dynamic> _anchorToJson(SourceAnchor anchor) => anchor.toJson();

  Future<String> _repairStructuredJson(
    PromptBuildResult originalPrompt,
    String brokenJson,
  ) {
    final repairPrompt = PromptBuildResult(
      systemPrompt:
          'You repair malformed JSON for Flow Read. Return one strict JSON object only. '
          'Do not add Markdown, comments, or unsupported content.',
      userPrompt:
          '''## Expected JSON Shape
${_bookSynthesisJsonShape(originalPrompt.outputLanguage)}

## Broken JSON Or Text
$brokenJson''',
      promptVersion: originalPrompt.promptVersion,
      sourceLanguage: originalPrompt.sourceLanguage,
      outputLanguage: originalPrompt.outputLanguage,
      spoilerBoundary: originalPrompt.spoilerBoundary,
    );

    return _aiService.executePrompt(
      repairPrompt,
      jsonMode: true,
      debugMetadata: {
        'task': 'book_synthesis_repair',
        'promptVersion': originalPrompt.promptVersion,
      },
    );
  }
}

class BookSynthesisRequest {
  final BookAnalysisData analysisData;
  final String bookTitle;
  final String? author;
  final List<BookSynthesisChapterSummary> chapterSummaries;
  final int maxInputTokens;
  final int reservedOutputTokens;
  final TokenEstimator tokenEstimator;
  final bool useCache;

  const BookSynthesisRequest({
    required this.analysisData,
    required this.bookTitle,
    this.author,
    this.chapterSummaries = const [],
    int? maxInputTokens,
    int? reservedOutputTokens,
    this.tokenEstimator = const TokenEstimator(),
    @Deprecated('Use maxInputTokens.') int? maxInputCharacters,
    @Deprecated('Use reservedOutputTokens.') int? reservedOutputCharacters,
    this.useCache = true,
  }) : maxInputTokens =
           maxInputTokens ??
           maxInputCharacters ??
           AnalysisTokenConfig.synthesisInputMaxTokens,
       reservedOutputTokens =
           reservedOutputTokens ??
           reservedOutputCharacters ??
           AnalysisTokenConfig.synthesisOutputMaxTokens;

  TokenBudget get tokenBudget => TokenBudget(
    maxInputTokens: maxInputTokens,
    reservedOutputTokens: reservedOutputTokens,
    estimator: tokenEstimator,
  );

  @Deprecated('Use maxInputTokens.')
  int get maxInputCharacters => maxInputTokens;

  @Deprecated('Use reservedOutputTokens.')
  int get reservedOutputCharacters => reservedOutputTokens;
}

class BookSynthesisChapterSummary {
  final int chapterIndex;
  final String? title;
  final String summary;
  final List<SourceAnchor> anchors;

  BookSynthesisChapterSummary({
    required this.chapterIndex,
    this.title,
    required this.summary,
    Iterable<SourceAnchor> anchors = const [],
  }) : anchors = List.unmodifiable(anchors);

  Map<String, dynamic> toPromptJson() {
    return {
      'chapter_index': chapterIndex,
      if (title != null && title!.trim().isNotEmpty) 'title': title,
      'summary': summary,
      if (anchors.isNotEmpty)
        'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
    };
  }
}

class _BookSynthesisPromptPayload {
  final List<Map<String, dynamic>> chapterSummaries;
  final List<Map<String, dynamic>> characterCards;
  final List<Map<String, dynamic>> storyEvents;
  final List<Map<String, dynamic>> locations;
  final List<String> themes;
  final bool budgetDowngraded;
  final int? estimatedInputTokens;

  const _BookSynthesisPromptPayload({
    required this.chapterSummaries,
    required this.characterCards,
    required this.storyEvents,
    required this.locations,
    required this.themes,
    required this.budgetDowngraded,
    this.estimatedInputTokens,
  });

  _BookSynthesisPromptPayload copyWith({
    int? estimatedInputTokens,
  }) {
    return _BookSynthesisPromptPayload(
      chapterSummaries: chapterSummaries,
      characterCards: characterCards,
      storyEvents: storyEvents,
      locations: locations,
      themes: themes,
      budgetDowngraded: budgetDowngraded,
      estimatedInputTokens: estimatedInputTokens ?? this.estimatedInputTokens,
    );
  }

  BookSynthesisPromptRequest toPromptRequest(BookSynthesisRequest request) {
    final data = request.analysisData;
    return BookSynthesisPromptRequest(
      bookId: data.bookId,
      bookTitle: request.bookTitle,
      author: request.author,
      startChapterIndex: data.scope.startChapterIndex,
      endChapterIndex: data.scope.endChapterIndex,
      coverage: data.coverage,
      scopeHash: data.scope.scopeHash,
      analysisSchemaVersion: data.schemaVersion,
      sourceLanguage: SourceLanguage.fromCode(data.scope.sourceLanguage),
      outputLanguage: OutputLanguage.fromCode(data.scope.outputLanguage),
      spoilerBoundary: data.scope.spoilerBoundary,
      chapterSummaries: chapterSummaries,
      characterCards: characterCards,
      storyEvents: storyEvents,
      locations: locations,
      themes: themes,
      budgetDowngraded: budgetDowngraded,
    );
  }

  Map<String, dynamic> toJson() => {
    'chapter_summaries': chapterSummaries,
    'character_cards': characterCards,
    'story_events': storyEvents,
    'locations': locations,
    'themes': themes,
    'budget_downgraded': budgetDowngraded,
  };
}

class _PayloadCaps {
  final int? maxChapterSummaries;
  final int? maxCharacters;
  final int? maxActionsPerCharacter;
  final int? maxEvents;
  final int? maxLocations;
  final int? maxThemes;
  final bool budgetDowngraded;

  const _PayloadCaps({
    this.maxChapterSummaries,
    this.maxCharacters,
    this.maxActionsPerCharacter,
    this.maxEvents,
    this.maxLocations,
    this.maxThemes,
    this.budgetDowngraded = false,
  });
}

List<T> _take<T>(Iterable<T> items, int? limit) {
  if (limit == null) return List<T>.of(items);
  return items.take(limit).toList();
}

String _synthesisTypeFor(AnalysisScope scope) {
  return switch (scope.spoilerBoundary.scope) {
    AIContextScope.fullBook => 'full_book',
    AIContextScope.readSoFar => 'read_so_far',
    AIContextScope.currentChapter => 'current_chapter',
    AIContextScope.currentPassage => 'current_passage',
  };
}

String _spoilerBoundaryHash(SpoilerBoundary boundary) {
  return AICacheService.contentHashFor(
    [
      boundary.bookId,
      boundary.currentUnitId,
      boundary.maxReadUnitOrder,
      boundary.unitType,
      boundary.scope.promptValue,
      boundary.allowedUnits,
    ].join('|'),
  );
}

String _bookSynthesisJsonShape(OutputLanguage outputLanguage) {
  return '''{
  "fullStoryline": "storyline (${outputLanguage.promptLabel})",
  "characterGraph": {"nodes": [], "edges": []},
  "bookMindMap": {"root": {"id": "root", "label": "Book", "children": []}},
  "structure": "structure analysis (${outputLanguage.promptLabel})",
  "themeAnalysis": "theme analysis (${outputLanguage.promptLabel})",
  "keyInsights": []
}''';
}
