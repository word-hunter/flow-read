import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models/ai_action_result.dart';
import 'models/ai_assistant_action.dart';
import 'models/ai_automation_settings.dart';
import 'models/ai_chat_session.dart';
import 'models/ai_context_snapshot.dart';
import 'models/ai_summary.dart';
import 'models/ai_text_analysis.dart';
import 'models/paragraph_insight.dart';
import 'models/reading_insight_profile.dart';
import 'models/word_analysis.dart';
import 'ai_debug_trace_recorder.dart';
import 'ai_assistant_action_registry.dart';
import 'ai_cache_service.dart';
import 'ai_service.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

typedef AIAssistantContextResolver =
    FutureOr<AIContextSnapshot> Function(
      AIContextSnapshot context,
      AIAssistantActionType action,
    );

class AIAssistantController extends ChangeNotifier {
  AIAssistantController({
    required this.registry,
    required this.automationSettings,
    required this.insightProfile,
    required this.actionController,
    this.contextResolver,
  });

  static const int maxRecentSessions = 20;

  AIContextSnapshot? _currentContext;
  AIAssistantSession? _currentSession;
  List<AIAssistantSession> _recentSessions = const [];
  bool _contextLocked = false;
  int _idSeed = 0;

  AIContextSnapshot? get currentContext => _currentContext;
  AIAssistantSession? get currentSession => _currentSession;
  List<AIAssistantSession> get recentSessions => _recentSessions;
  bool get contextLocked => _contextLocked;
  final AIAssistantActionRegistry registry;
  final AIAutomationSettings automationSettings;
  final ReadingInsightProfile insightProfile;
  final AIActionController actionController;
  final AIAssistantContextResolver? contextResolver;

  List<AIAssistantActionType> get availableActions {
    final context = _currentContext;
    if (context == null) return const [];
    return registry.availableActions(context);
  }

  bool get isEmpty => _currentContext == null;

  void setContext(AIContextSnapshot context, {bool force = false}) {
    if (_contextLocked && _currentContext != null && !force) return;
    _currentContext = context;
    _currentSession = _createSession(context);
    actionController.clearResult();
    notifyListeners();
  }

  void startNewSession() {
    final context = _currentContext;
    if (context == null) return;
    _contextLocked = false;
    _currentSession = _createSession(context);
    actionController.clearResult();
    notifyListeners();
  }

  void openSession(AIAssistantSession session) {
    _currentContext = session.anchor;
    _currentSession = session;
    _recentSessions = _putRecentSession(_recentSessions, session);
    actionController.clearResult();
    notifyListeners();
  }

  void setScope(AIContextScope scope) {
    final context = _currentContext;
    final session = _currentSession;
    if (context == null || session == null || context.scope == scope) return;
    final nextContext = context.copyWith(scope: scope);
    final nextSession = session.copyWith(
      scope: scope,
      anchor: nextContext,
      updatedAt: DateTime.now(),
    );
    _currentContext = nextContext;
    _currentSession = nextSession;
    if (nextSession.messages.isNotEmpty) {
      _recentSessions = _putRecentSession(_recentSessions, nextSession);
    }
    notifyListeners();
  }

  void toggleContextLock() {
    _contextLocked = !_contextLocked;
    notifyListeners();
  }

  Future<void> executeAction(
    AIAssistantActionType action, {
    String? followUpQuestion,
  }) async {
    var context = _currentContext;
    if (context == null) return;
    final question = followUpQuestion?.trim();
    final isFollowUp = question != null && question.isNotEmpty;
    final targetAction = isFollowUp ? AIAssistantActionType.chat : action;
    context = await _resolveContext(context, targetAction);
    _currentContext = context;
    _currentSession ??= _createSession(context);
    if (_currentSession != null && _currentSession!.anchor != context) {
      _currentSession = _currentSession!.copyWith(anchor: context);
    }
    if (isFollowUp) {
      _appendMessage(
        AIChatMessageRole.user,
        question,
        action: AIAssistantActionType.chat,
        context: context,
      );
    }
    final prompt = registry.buildPrompt(
      targetAction,
      context,
      followUpQuestion: question,
    );
    await actionController.enqueue(prompt, targetAction);
    final result = actionController.lastResult;
    if (result == null || result is AIErrorResult) return;
    _appendMessage(
      AIChatMessageRole.assistant,
      _messageContentFor(result),
      action: targetAction,
      context: context,
    );
  }

  Future<AIContextSnapshot> _resolveContext(
    AIContextSnapshot context,
    AIAssistantActionType action,
  ) async {
    final resolver = contextResolver;
    if (resolver == null) return context;
    try {
      return await resolver(context, action);
    } catch (error) {
      debugPrint('[AI] context retrieval failed: $error');
      return context;
    }
  }

  void clear() {
    _currentContext = null;
    _currentSession = null;
    _contextLocked = false;
    actionController.clearResult();
    notifyListeners();
  }

  AIAssistantSession _createSession(AIContextSnapshot context) {
    final now = DateTime.now();
    return AIAssistantSession(
      id: _nextId('session'),
      bookId: context.bookId,
      chapterIndex: context.chapterIndex,
      title: _sessionTitle(context),
      scope: context.scope,
      anchor: context,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _appendMessage(
    AIChatMessageRole role,
    String content, {
    required AIAssistantActionType action,
    required AIContextSnapshot context,
  }) {
    final session = _currentSession ?? _createSession(context);
    final now = DateTime.now();
    final message = AIChatMessage(
      id: _nextId('message'),
      role: role,
      content: content.trim(),
      actionType: action,
      scope: context.scope,
      citations: role == AIChatMessageRole.assistant
          ? _citationsFor(context)
          : const [],
      createdAt: now,
    );
    final nextSession = session.copyWith(
      messages: [...session.messages, message],
      updatedAt: now,
    );
    _currentSession = nextSession;
    _recentSessions = _putRecentSession(_recentSessions, nextSession);
    notifyListeners();
  }

  List<AIAssistantSession> _putRecentSession(
    List<AIAssistantSession> sessions,
    AIAssistantSession next,
  ) {
    final merged = [
      next,
      ...sessions.where((session) => session.id != next.id),
    ];
    if (merged.length <= maxRecentSessions) return merged;
    return merged.take(maxRecentSessions).toList(growable: false);
  }

  List<AIAssistantCitation> _citationsFor(AIContextSnapshot context) {
    final quote = _citationQuote(context);
    if (quote == null || quote.isEmpty) return const [];
    return [
      AIAssistantCitation(
        sourceType: _citationSourceType(context),
        label: _citationLabel(context),
        bookId: context.bookId,
        chapterIndex: context.chapterIndex,
        quote: quote,
      ),
    ];
  }

  String? _citationQuote(AIContextSnapshot context) {
    return switch (context.source) {
      AIContextSource.readerSelectedText => context.selectedText,
      AIContextSource.readerParagraph => context.surroundingPassage,
      AIContextSource.readerWord => context.wordSentence ?? context.word,
      AIContextSource.readerChapter => context.chapterTitle,
      AIContextSource.rssArticle || AIContextSource.internalWeb =>
        context.articleTitle ?? context.articleContent,
    };
  }

  String _citationSourceType(AIContextSnapshot context) {
    return switch (context.source) {
      AIContextSource.readerSelectedText => 'selection',
      AIContextSource.readerParagraph => 'paragraph',
      AIContextSource.readerWord => 'word',
      AIContextSource.readerChapter => 'chapter',
      AIContextSource.rssArticle || AIContextSource.internalWeb => 'article',
    };
  }

  String _citationLabel(AIContextSnapshot context) {
    return switch (context.source) {
      AIContextSource.readerSelectedText => '选中文本',
      AIContextSource.readerParagraph => '当前段落',
      AIContextSource.readerWord => '当前词',
      AIContextSource.readerChapter => '本章',
      AIContextSource.rssArticle || AIContextSource.internalWeb => '当前文章',
    };
  }

  String _sessionTitle(AIContextSnapshot context) {
    final title =
        context.word ??
        context.chapterTitle ??
        context.articleTitle ??
        context.selectedText ??
        context.surroundingPassage ??
        'AI 会话';
    final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 24) return normalized;
    return '${normalized.substring(0, 24)}...';
  }

  String _messageContentFor(AIActionResult result) {
    if (result is AITranslateResult) return result.translation;
    if (result is AIArticleQAResult) return result.answer;
    if (result is AIExplainResult) return result.explanation;
    if (result is AITextAnalysisResult) {
      final analysis = result.analysis;
      final parts = <String>[
        if (analysis.translation.trim().isNotEmpty) analysis.translation,
        ...analysis.structureNotes.map((note) => note.explanation),
        ...analysis.grammarPoints.map((point) => point.explanation),
        ...analysis.vocabularyNotes.map((note) => note.contextMeaning),
        ...analysis.expressionNotes.map((note) => note.meaning),
        if (analysis.readingTip.trim().isNotEmpty) analysis.readingTip,
      ].where((part) => part.trim().isNotEmpty).toList(growable: false);
      return parts.isEmpty ? '已完成分析。' : parts.join('\n\n');
    }
    if (result is AIWordAnalysisResult) {
      final analysis = result.analysis;
      final meanings = analysis.meanings
          .map((meaning) {
            final explanation = meaning.explanation.trim();
            if (explanation.isEmpty) return meaning.meaning;
            return '${meaning.meaning}: $explanation';
          })
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
      return [
        if (analysis.pronunciation.trim().isNotEmpty)
          '发音: ${analysis.pronunciation}',
        if (meanings.isNotEmpty) meanings,
        ...analysis.usageTips,
        if (analysis.memoryTip.trim().isNotEmpty) analysis.memoryTip,
      ].join('\n\n');
    }
    if (result is AISummaryResult) {
      final summary = result.summary;
      final events = summary.events
          .map((event) => event.description)
          .where((event) => event.trim().isNotEmpty);
      final characters = summary.characterDevelopments
          .map((character) => '${character.character}: ${character.change}')
          .where((line) => line.trim().isNotEmpty);
      return [
        ...events,
        ...characters,
        if (summary.readingGuidance.trim().isNotEmpty) summary.readingGuidance,
      ].join('\n\n');
    }
    if (result is AIParagraphInsightResult) {
      return result.insight.gist;
    }
    if (result is AIPhraseExtractionResult) {
      return result.phrases
          .map((phrase) => '${phrase.phrase}: ${phrase.explanation}')
          .join('\n');
    }
    if (result is AIQuestionGenerationResult) {
      return result.questions
          .map((question) => '${question.question}\n答案: ${question.answer}')
          .join('\n\n');
    }
    if (result is AIStreamingProgress) return result.chunk;
    return '';
  }

  String _nextId(String prefix) {
    _idSeed += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idSeed';
  }

  @override
  void dispose() {
    actionController.cancel();
    clear();
    super.dispose();
  }
}

class AIActionController extends ChangeNotifier {
  AIActionController({
    required this.aiService,
    this.cacheService,
    AIDebugTraceRecorder? debugRecorder,
  }) : _debugRecorder = debugRecorder ?? AIDebugTraceRecorder.instance;

  final AIService aiService;
  final AICacheService? cacheService;
  final AIDebugTraceRecorder _debugRecorder;

  bool _isBusy = false;
  AIAssistantActionType? _currentAction;
  AIActionResult? _lastResult;
  PromptBuildResult? _lastPrompt;
  AIAssistantActionType? _lastQueuedAction;
  StreamController<String>? _streamController;
  int _generation = 0;

  bool get isBusy => _isBusy;
  AIAssistantActionType? get currentAction => _currentAction;
  AIActionResult? get lastResult => _lastResult;
  Stream<String>? get stream => _streamController?.stream;

  Future<void> enqueue(
    PromptBuildResult prompt,
    AIAssistantActionType action, {
    bool bypassCache = false,
  }) async {
    final generation = ++_generation;
    await _streamController?.close();
    _streamController = StreamController<String>.broadcast();
    _lastPrompt = prompt;
    _lastQueuedAction = action;

    final cacheKey = _cacheKeyFor(prompt, action);
    if (!bypassCache) {
      final cached = await _loadCachedResponse(cacheKey);
      if (generation != _generation) return;
      if (cached != null) {
        _debugRecorder.recordCacheHit(
          action: action.name,
          cacheKey: cacheKey.toTrace(),
          prompt: _promptTrace(prompt),
          response: cached,
          metadata: {
            'source': 'AIActionController',
          },
        );
        _streamController?.add(cached);
        _lastResult = _resultFor(action, cached);
        _isBusy = false;
        _currentAction = null;
        notifyListeners();
        return;
      }
    }

    _isBusy = true;
    _currentAction = action;
    notifyListeners();

    try {
      final raw = await aiService.executePrompt(
        prompt,
        jsonMode: _prefersJsonMode(action),
        debugMetadata: {
          'action': action.name,
          'cacheKey': cacheKey.toTrace(),
          'cacheBypassed': bypassCache,
        },
      );
      if (generation != _generation) return;
      _streamController?.add(raw);
      _lastResult = _resultFor(action, raw);
      await _saveCachedResponse(cacheKey, raw);
    } on AIClientException catch (error) {
      if (generation != _generation) return;
      _lastResult = AIErrorResult(
        message: error.message,
        isRetryable: error.type != AIClientErrorType.unauthorized,
      );
    } catch (error) {
      if (generation != _generation) return;
      _lastResult = AIErrorResult(message: error.toString());
    } finally {
      if (generation == _generation) {
        _isBusy = false;
        _currentAction = null;
        notifyListeners();
      }
    }
  }

  void cancel() {
    if (!_isBusy) return;
    _generation += 1;
    _isBusy = false;
    _currentAction = null;
    notifyListeners();
  }

  Future<void> retry() async {
    final prompt = _lastPrompt;
    final action = _lastQueuedAction;
    if (prompt == null || action == null) return;
    await enqueue(prompt, action, bypassCache: true);
  }

  void clearResult() {
    _lastResult = null;
    notifyListeners();
  }

  bool _prefersJsonMode(AIAssistantActionType action) {
    return switch (action) {
      AIAssistantActionType.translate ||
      AIAssistantActionType.articleQA ||
      AIAssistantActionType.chat => false,
      _ => true,
    };
  }

  AIActionResult _resultFor(AIAssistantActionType action, String raw) {
    final trimmed = raw.trim();
    return switch (action) {
      AIAssistantActionType.translate => AITranslateResult(
        translation: trimmed,
      ),
      AIAssistantActionType.articleQA ||
      AIAssistantActionType.chat => AIArticleQAResult(answer: trimmed),
      AIAssistantActionType.summary => AISummaryResult(
        summary:
            _parseJson(trimmed, AISummary.fromJson) ??
            AISummary.fallback(trimmed),
      ),
      AIAssistantActionType.wordAnalysis => AIWordAnalysisResult(
        analysis:
            _parseJson(trimmed, WordAnalysis.fromJson) ??
            WordAnalysis.fallback(trimmed),
      ),
      AIAssistantActionType.explain ||
      AIAssistantActionType.phraseExtraction ||
      AIAssistantActionType.pronounReference => AITextAnalysisResult(
        analysis:
            _parseJson(trimmed, AITextAnalysis.fromJson) ??
            AITextAnalysis.fallback(trimmed),
      ),
      AIAssistantActionType.questionGeneration => AIExplainResult(
        explanation: trimmed,
      ),
      AIAssistantActionType.paragraphInsight => AIParagraphInsightResult(
        insight:
            _parseJson(trimmed, ParagraphInsight.fromJson) ??
            ParagraphInsight.fallback(trimmed),
      ),
    };
  }

  T? _parseJson<T>(
    String raw,
    T Function(Map<String, dynamic> json) parser,
  ) {
    try {
      final decoded = jsonDecode(_extractJsonPayload(raw));
      if (decoded is Map<String, dynamic>) {
        return parser(decoded);
      }
    } catch (_) {}
    return null;
  }

  String _extractJsonPayload(String raw) {
    var content = raw.trim();
    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    return content.trim();
  }

  Map<String, Object?> _promptTrace(PromptBuildResult prompt) {
    return {
      'systemPrompt': prompt.systemPrompt,
      'userPrompt': prompt.userPrompt,
      'promptVersion': prompt.promptVersion,
      'sourceLanguage': prompt.sourceLanguage.code,
      'outputLanguage': prompt.outputLanguage.code,
      'spoilerBoundary': {
        'bookId': prompt.spoilerBoundary.bookId,
        'currentUnitId': prompt.spoilerBoundary.currentUnitId,
        'maxReadUnitOrder': prompt.spoilerBoundary.maxReadUnitOrder,
        'unitType': prompt.spoilerBoundary.unitType,
        'scope': prompt.spoilerBoundary.scope.promptValue,
        'allowedUnits': prompt.spoilerBoundary.allowedUnits,
      },
    };
  }

  _AssistantActionCacheKey _cacheKeyFor(
    PromptBuildResult prompt,
    AIAssistantActionType action,
  ) {
    final jsonMode = _prefersJsonMode(action);
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'action': action.name,
        'jsonMode': jsonMode,
        'systemPrompt': prompt.systemPrompt,
        'userPrompt': prompt.userPrompt,
      }),
    );
    return _AssistantActionCacheKey(
      kind: 'assistant_${action.name}',
      bookId: prompt.spoilerBoundary.bookId,
      chapterIndex: prompt.spoilerBoundary.maxReadUnitOrder,
      contentHash: contentHash,
      promptVersion: prompt.promptVersion,
      sourceLanguage: prompt.sourceLanguage.code,
      outputLanguage: prompt.outputLanguage.code,
      modelConfigFingerprint: aiService.modelConfigFingerprint,
    );
  }

  Future<String?> _loadCachedResponse(_AssistantActionCacheKey key) async {
    final cache = cacheService;
    if (cache == null) return null;
    try {
      return await cache.loadAssistantAction(
        kind: key.kind,
        bookId: key.bookId,
        chapterIndex: key.chapterIndex,
        contentHash: key.contentHash,
        promptVersion: key.promptVersion,
        sourceLanguage: key.sourceLanguage,
        outputLanguage: key.outputLanguage,
        modelConfigFingerprint: key.modelConfigFingerprint,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedResponse(
    _AssistantActionCacheKey key,
    String raw,
  ) async {
    final cache = cacheService;
    if (cache == null) return;
    try {
      await cache.saveAssistantAction(
        kind: key.kind,
        bookId: key.bookId,
        chapterIndex: key.chapterIndex,
        contentHash: key.contentHash,
        promptVersion: key.promptVersion,
        sourceLanguage: key.sourceLanguage,
        outputLanguage: key.outputLanguage,
        modelConfigFingerprint: key.modelConfigFingerprint,
        response: raw,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _streamController?.close();
    super.dispose();
  }
}

class _AssistantActionCacheKey {
  const _AssistantActionCacheKey({
    required this.kind,
    required this.bookId,
    required this.chapterIndex,
    required this.contentHash,
    required this.promptVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
    required this.modelConfigFingerprint,
  });

  final String kind;
  final String bookId;
  final int chapterIndex;
  final String contentHash;
  final int promptVersion;
  final String sourceLanguage;
  final String outputLanguage;
  final String modelConfigFingerprint;

  Map<String, Object?> toTrace() {
    return {
      'kind': kind,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'contentHash': contentHash,
      'promptVersion': promptVersion,
      'sourceLanguage': sourceLanguage,
      'outputLanguage': outputLanguage,
      'modelConfigFingerprint': modelConfigFingerprint,
    };
  }
}
