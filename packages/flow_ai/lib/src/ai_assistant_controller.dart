import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models/ai_action_result.dart';
import 'models/ai_assistant_action.dart';
import 'models/ai_automation_settings.dart';
import 'models/ai_context_snapshot.dart';
import 'models/ai_summary.dart';
import 'models/ai_text_analysis.dart';
import 'models/reading_insight_profile.dart';
import 'models/word_analysis.dart';
import 'ai_assistant_action_registry.dart';
import 'ai_cache_service.dart';
import 'ai_service.dart';
import 'llm_client.dart';
import 'prompt_builder.dart';

class AIAssistantController extends ChangeNotifier {
  AIAssistantController({
    required this.registry,
    required this.automationSettings,
    required this.insightProfile,
    required this.actionController,
  });

  AIContextSnapshot? _currentContext;

  AIContextSnapshot? get currentContext => _currentContext;
  final AIAssistantActionRegistry registry;
  final AIAutomationSettings automationSettings;
  final ReadingInsightProfile insightProfile;
  final AIActionController actionController;

  List<AIAssistantActionType> get availableActions {
    final context = _currentContext;
    if (context == null) return const [];
    return registry.availableActions(context);
  }

  bool get isEmpty => _currentContext == null;

  void setContext(AIContextSnapshot context) {
    _currentContext = context;
    actionController.clearResult();
    notifyListeners();
  }

  Future<void> executeAction(
    AIAssistantActionType action, {
    String? followUpQuestion,
  }) async {
    final context = _currentContext;
    if (context == null) return;
    final prompt = registry.buildPrompt(
      action,
      context,
      followUpQuestion: followUpQuestion,
    );
    await actionController.enqueue(prompt, action);
  }

  void clear() {
    _currentContext = null;
    actionController.clearResult();
    notifyListeners();
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
  });

  final AIService aiService;
  final AICacheService? cacheService;

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
      AIAssistantActionType.articleQA => false,
      _ => true,
    };
  }

  AIActionResult _resultFor(AIAssistantActionType action, String raw) {
    final trimmed = raw.trim();
    return switch (action) {
      AIAssistantActionType.translate => AITranslateResult(
        translation: trimmed,
      ),
      AIAssistantActionType.articleQA => AIArticleQAResult(answer: trimmed),
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
}
