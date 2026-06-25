import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flow_ai/flow_ai.dart';
import '../../models/learning_item.dart';
import '../../services/app_logger.dart';
import '../../services/book_insight_chapter_catalog.dart';
import '../../services/learning_item_service.dart';
import '../../services/settings_service.dart';
import '../../storage/repositories/ai_usage_repository.dart';
import '../ai_usage_provider.dart';
import '../settings_provider.dart';
import 'bookshelf_notifier.dart';
import 'current_book_notifier.dart';
import 'services_provider.dart';
import 'text_selection_notifier.dart';

@immutable
class AIState {
  const AIState({
    this.aiTextAnalysis,
    this.isAnalyzingText = false,
    this.aiTranslation,
    this.isTranslatingText = false,
    this.aiSummary,
    this.isGeneratingSummary = false,
    this.aiChapterPreview,
    this.isGeneratingChapterPreview = false,
    this.chapterAIStatus,
    this.chapterAISummaryCoverage,
    this.isLoadingChapterAISummaryCoverage = false,
    this.summaryLanguage = 'zh',
    this.aiPractice,
    this.isGeneratingPractice = false,
    this.aiWordAnalysis,
    this.isAnalyzingWord = false,
    this.errorMessage,
  });

  final AITextAnalysis? aiTextAnalysis;
  final bool isAnalyzingText;
  final String? aiTranslation;
  final bool isTranslatingText;
  final AISummary? aiSummary;
  final bool isGeneratingSummary;
  final AIChapterPreview? aiChapterPreview;
  final bool isGeneratingChapterPreview;
  final ChapterAIStatus? chapterAIStatus;
  final ChapterAISummaryCoverage? chapterAISummaryCoverage;
  final bool isLoadingChapterAISummaryCoverage;
  final String summaryLanguage;
  final AIPracticeSet? aiPractice;
  final bool isGeneratingPractice;
  final WordAnalysis? aiWordAnalysis;
  final bool isAnalyzingWord;
  final String? errorMessage;

  AIState copyWith({
    AITextAnalysis? aiTextAnalysis,
    bool? isAnalyzingText,
    String? aiTranslation,
    bool? isTranslatingText,
    AISummary? aiSummary,
    bool? isGeneratingSummary,
    AIChapterPreview? aiChapterPreview,
    bool? isGeneratingChapterPreview,
    ChapterAIStatus? chapterAIStatus,
    ChapterAISummaryCoverage? chapterAISummaryCoverage,
    bool? isLoadingChapterAISummaryCoverage,
    String? summaryLanguage,
    AIPracticeSet? aiPractice,
    bool? isGeneratingPractice,
    WordAnalysis? aiWordAnalysis,
    bool? isAnalyzingWord,
    String? errorMessage,
    bool clearAIResults = false,
    bool clearError = false,
  }) {
    if (clearAIResults) {
      return AIState(
        summaryLanguage: summaryLanguage ?? this.summaryLanguage,
      );
    }
    return AIState(
      aiTextAnalysis: aiTextAnalysis ?? this.aiTextAnalysis,
      isAnalyzingText: isAnalyzingText ?? this.isAnalyzingText,
      aiTranslation: aiTranslation ?? this.aiTranslation,
      isTranslatingText: isTranslatingText ?? this.isTranslatingText,
      aiSummary: aiSummary ?? this.aiSummary,
      isGeneratingSummary: isGeneratingSummary ?? this.isGeneratingSummary,
      aiChapterPreview: aiChapterPreview ?? this.aiChapterPreview,
      isGeneratingChapterPreview:
          isGeneratingChapterPreview ?? this.isGeneratingChapterPreview,
      chapterAIStatus: chapterAIStatus ?? this.chapterAIStatus,
      chapterAISummaryCoverage:
          chapterAISummaryCoverage ?? this.chapterAISummaryCoverage,
      isLoadingChapterAISummaryCoverage:
          isLoadingChapterAISummaryCoverage ??
          this.isLoadingChapterAISummaryCoverage,
      summaryLanguage: summaryLanguage ?? this.summaryLanguage,
      aiPractice: aiPractice ?? this.aiPractice,
      isGeneratingPractice: isGeneratingPractice ?? this.isGeneratingPractice,
      aiWordAnalysis: aiWordAnalysis ?? this.aiWordAnalysis,
      isAnalyzingWord: isAnalyzingWord ?? this.isAnalyzingWord,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AINotifier extends Notifier<AIState> {
  static const _chapterPreviewMaxLength = 1400;

  AIService? get _aiService => ref.read(aiServiceProvider);
  AICacheService? get _aiCache => ref.read(aiCacheServiceProvider);
  SettingsService get _settings => ref.read(settingsProvider);
  LearningItemService? get _learningItemService =>
      ref.read(learningItemServiceProvider);

  String? get _activeBookId => ref.read(bookshelfNotifierProvider).activeBookId;
  int get _currentChapter =>
      ref.read(currentBookNotifierProvider).currentChapter;

  @override
  AIState build() => const AIState();

  bool get aiFeaturesEnabled =>
      _aiService != null && _settings.aiFeaturesEnabled;

  String get aiFeatureDisabledReason => _settings.aiFeatureDisabledReason;

  String get effectiveTargetExplanationLanguage {
    final activeBookId = _activeBookId;
    var globalLanguage = _settings.targetExplanationLanguage;
    if (activeBookId != null) {
      final bookService = ref.read(bookServiceProvider);
      final active = bookService.books
          .where((b) => b.id == activeBookId)
          .firstOrNull;
      final lang = active?.effectiveTargetExplanationLanguage(globalLanguage);
      if (lang != null) return lang;
    }
    return globalLanguage;
  }

  bool _ensureAIReady() {
    if (_aiService == null) {
      state = state.copyWith(errorMessage: 'AI 服务未初始化');
      return false;
    }
    if (!aiFeaturesEnabled) {
      state = state.copyWith(errorMessage: aiFeatureDisabledReason);
      return false;
    }
    return true;
  }

  // ---- Text Analysis & Translation ----

  Future<void> analyzeSelectedTextAI(String text, {String? sourceText}) async {
    if (!_ensureAIReady()) return;
    final ai = _aiService;
    if (ai == null) return;
    final currentResult = ref.read(currentBookNotifierProvider).result;
    final request = PassageRequestBuilder().buildSelectedTextAnalysis(
      selectedText: text,
      sourceText: sourceText ?? currentResult?.passageText ?? text,
    );

    state = state.copyWith(
      isAnalyzingText: true,
      aiTextAnalysis: null,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final result = await ai.analyzeTextWithResult(
        selectedText: request.selectedText,
        currentPassage: request.currentPassage,
        sourceLanguage: request.sourceLanguage,
        outputLanguage: OutputLanguage.fromCode(
          effectiveTargetExplanationLanguage,
        ),
        spoilerBoundary: request.spoilerBoundary,
      );
      final analysis = result.value;
      _settings.incrementAIUsage(textAnalysis: true);
      await _recordAIUsage(
        result: result,
        operation: AIUsageOperation.textAnalysis,
      );
      if (state.isAnalyzingText) {
        state = state.copyWith(
          aiTextAnalysis: analysis,
          isAnalyzingText: false,
        );
      }
    } catch (e) {
      debugPrint('[AI] analyzeText failed: $e');
      state = state.copyWith(
        errorMessage: 'AI 解析失败: $e',
        isAnalyzingText: false,
      );
    }
  }

  Future<void> translateSelectedTextAI(String text) async {
    if (!_ensureAIReady()) return;
    final ai = _aiService;
    if (ai == null) return;
    state = state.copyWith(
      isTranslatingText: true,
      aiTranslation: null,
      clearError: true,
    );
    try {
      final result = await ai.translateTextWithResult(
        text,
        sourceLanguage: SourceLanguage.inferFromText(text),
        outputLanguage: OutputLanguage.fromCode(
          effectiveTargetExplanationLanguage,
        ),
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      final translation = result.value;
      await _recordAIUsage(
        result: result,
        operation: AIUsageOperation.translation,
      );
      if (state.isTranslatingText) {
        state = state.copyWith(
          aiTranslation: translation,
          isTranslatingText: false,
        );
      }
    } catch (e) {
      debugPrint('[AI] translateText failed: $e');
      state = state.copyWith(
        errorMessage: '翻译失败: $e',
        isTranslatingText: false,
      );
    }
  }

  Future<LearningItemSaveResult?> addAIGrammarLearningItem(
    GrammarPoint point,
  ) async {
    final service = _learningItemService;
    final selectedText = ref
        .read(textSelectionNotifierProvider)
        .selectedText
        ?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.grammarPoint(
        point: point,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  Future<LearningItemSaveResult?> addAIVocabularyLearningItem(
    VocabularyNote note,
  ) async {
    final service = _learningItemService;
    final selectedText = ref
        .read(textSelectionNotifierProvider)
        .selectedText
        ?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.vocabularyNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  Future<LearningItemSaveResult?> addAIExpressionLearningItem(
    ExpressionNote note,
  ) async {
    final service = _learningItemService;
    final selectedText = ref
        .read(textSelectionNotifierProvider)
        .selectedText
        ?.trim();
    if (service == null || selectedText == null || selectedText.isEmpty) {
      return null;
    }
    return service.saveDraft(
      LearningItemDraft.expressionNote(
        note: note,
        selectedText: selectedText,
        source: _currentLearningItemSource(),
      ),
    );
  }

  // ---- Practice ----

  Future<void> generatePractice() async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingPractice: true,
      aiPractice: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob().generatePractice(
        ChapterPracticeJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: currentResult.passageText,
          vocabulary: currentResult.vocabulary.map((v) => v.word).toList(),
          events: state.aiSummary?.events ?? const [],
        ),
      );
      state = state.copyWith(
        aiPractice: result.practice,
        chapterAIStatus: result.status,
        isGeneratingPractice: false,
      );
    } catch (e) {
      debugPrint('[AI] generatePractice failed: $e');
      state = state.copyWith(
        errorMessage: '生成练习题失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.practice,
          '练习题生成失败：$e',
        ),
        isGeneratingPractice: false,
      );
    }
  }

  // ---- Word Analysis ----

  Future<void> analyzeWordAI(String word, String sentence) async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final chapterText = currentResult.passageText;
    final sourceLanguage = SourceLanguage.inferFromText(
      '$sentence $chapterText',
    );
    final outputLanguage = OutputLanguage.fromCode(
      effectiveTargetExplanationLanguage,
    );
    final contentHash = AICacheService.contentHashFor(
      jsonEncode({
        'word': word.trim().toLowerCase(),
        'sentence': sentence.trim(),
        'chapterText': chapterText,
      }),
    );
    const cacheBookId = 'word-analysis';
    final cacheChapterIndex = _currentChapter;

    final aiForCache = _aiService;
    final cacheForLookup = _aiCache;
    if (aiForCache != null && cacheForLookup != null) {
      try {
        final cacheJson = await cacheForLookup.loadWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          contentHash: contentHash,
          promptVersion: aiForCache.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
        if (cacheJson != null) {
          state = state.copyWith(
            aiWordAnalysis: WordAnalysis.fromJson(
              jsonDecode(cacheJson) as Map<String, dynamic>,
            ),
            isAnalyzingWord: false,
          );
          return;
        }
      } catch (_) {
        debugPrint('[AI] word analysis cache lookup failed');
      }
    }

    final ai = _aiService;
    if (ai == null) return;
    state = state.copyWith(isAnalyzingWord: true, aiWordAnalysis: null);
    try {
      final result = await ai.analyzeWordWithResult(
        word: word,
        sentence: sentence,
        chapterContext: chapterText,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.currentPassage(),
      );
      final analysis = result.value;
      _settings.incrementAIUsage(wordAnalysis: true);
      await _recordAIUsage(
        result: result,
        operation: AIUsageOperation.wordAnalysis,
      );
      state = state.copyWith(
        aiWordAnalysis: analysis,
        isAnalyzingWord: false,
      );
      if (cacheForLookup != null) {
        await cacheForLookup.saveWordAnalysis(
          cacheBookId,
          cacheChapterIndex,
          jsonEncode(analysis.toJson()),
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      debugPrint('[AI] analyzeWord failed: $e');
      state = state.copyWith(
        errorMessage: 'AI 单词解析失败: $e',
        isAnalyzingWord: false,
      );
    }
  }

  // ---- Chapter AI ----

  Future<void> generateSummary() async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    if (currentResult == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingSummary: true,
      aiSummary: null,
      chapterAIStatus: null,
    );
    try {
      final result = await _createChapterAIJob().generateSummary(
        ChapterSummaryJobRequest(
          bookId: bookId,
          chapterIndex: _currentChapter,
          chapterText: currentResult.passageText,
          vocabulary: currentResult.vocabulary.map((v) => v.word).toList(),
          outputLanguage: OutputLanguage.fromCode(state.summaryLanguage),
        ),
      );
      if (_isPersistableChapterSummary(result.summary)) {
        await _saveChapterSummarySourceScope(
          bookId: bookId,
          chapterIndex: _currentChapter,
          summary: result.summary,
        );
      }
      state = state.copyWith(
        aiSummary: result.summary,
        chapterAIStatus: result.status,
        isGeneratingSummary: false,
      );
      await _refreshChapterAISummaryCoverage();
    } catch (e) {
      debugPrint('[AI] generateSummary failed: $e');
      state = state.copyWith(
        errorMessage: '生成总结失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.summary,
          '章节总结生成失败：$e',
        ),
        isGeneratingSummary: false,
      );
    }
  }

  Future<int> generateSummaryForChapter(int chapterIndex) async {
    return generateSummariesForReadChapters([chapterIndex]);
  }

  Future<int> generateSummariesForReadChapters(
    Iterable<int> chapterIndexes,
  ) async {
    final book = ref.read(bookshelfNotifierProvider).book;
    final bookId = _activeBookId;
    if (book == null || bookId == null || !_ensureAIReady()) return 0;

    final maxReadChapter = _currentChapter;
    final chapterCatalog = BookInsightChapterCatalog.fromBook(book);
    final targets =
        chapterIndexes
            .where(
              (chapterIndex) =>
                  chapterIndex >= 0 &&
                  chapterIndex < book.chapters.length &&
                  chapterIndex <= maxReadChapter &&
                  chapterCatalog.containsRawChapter(chapterIndex),
            )
            .toSet()
            .toList()
          ..sort();
    if (targets.isEmpty) {
      state = state.copyWith(
        chapterAIStatus: const ChapterAIStatus.failed(
          ChapterAIFeature.summary,
          '该目录项不是可分析的正文章节。',
        ),
        clearError: true,
      );
      return 0;
    }

    state = state.copyWith(
      isGeneratingSummary: true,
      chapterAIStatus: null,
      clearError: true,
    );

    var completed = 0;
    AISummary? currentChapterSummary;
    ChapterAIStatus? lastStatus;
    try {
      final job = _createChapterAIJob();
      for (final chapterIndex in targets) {
        final chapter = book.chapters[chapterIndex];
        final chapterText = chapter.plainText.trim();
        if (chapterText.isEmpty) {
          lastStatus = const ChapterAIStatus.failed(
            ChapterAIFeature.summary,
            '该章节没有可分析的正文。',
          );
          continue;
        }

        final result = await job.generateSummary(
          ChapterSummaryJobRequest(
            bookId: bookId,
            chapterIndex: chapterIndex,
            chapterText: chapterText,
            vocabulary: const [],
            outputLanguage: OutputLanguage.fromCode(state.summaryLanguage),
          ),
        );
        final persistable = _isPersistableChapterSummary(result.summary);
        if (persistable) {
          await _saveChapterSummarySourceScope(
            bookId: bookId,
            chapterIndex: chapterIndex,
            summary: result.summary,
          );
          completed += 1;
        }
        lastStatus = result.status;
        if (chapterIndex == _currentChapter) {
          currentChapterSummary = result.summary;
        }
      }
      state = state.copyWith(
        aiSummary: currentChapterSummary,
        chapterAIStatus: lastStatus,
        isGeneratingSummary: false,
      );
      await _refreshChapterAISummaryCoverage();
    } catch (e) {
      debugPrint('[AI] generateSummariesForReadChapters failed: $e');
      state = state.copyWith(
        errorMessage: '补齐章节总结失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.summary,
          '章节总结补齐失败：$e',
        ),
        isGeneratingSummary: false,
      );
    }
    return completed;
  }

  Future<void> generateChapterPreview() async {
    final currentResult = ref.read(currentBookNotifierProvider).result;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (currentResult == null || book == null || !_ensureAIReady()) return;
    final bookId = _activeBookId;
    if (bookId == null) return;

    state = state.copyWith(
      isGeneratingChapterPreview: true,
      aiChapterPreview: null,
      chapterAIStatus: null,
    );
    try {
      final chapter = book.chapters[_currentChapter];
      final chapterText = currentResult.passageText;
      final openingText = _chapterPreviewOpening(chapterText);
      final sourceLanguage = SourceLanguage.inferFromText(openingText);
      final outputLanguage = OutputLanguage.fromCode(
        effectiveTargetExplanationLanguage,
      );
      final vocabulary = currentResult.vocabulary.map((v) => v.word).toList();
      final contentHash = AICacheService.contentHashFor(
        jsonEncode({
          'title': chapter.title,
          'openingText': openingText,
          'vocabulary': vocabulary.take(20).toList(),
        }),
      );

      final ai = _aiService;
      final cache = _aiCache;
      if (ai != null && cache != null) {
        final cacheJson = await cache.loadChapterPreview(
          bookId,
          _currentChapter,
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
        if (cacheJson != null) {
          state = state.copyWith(
            aiChapterPreview: AIChapterPreview.fromJson(
              jsonDecode(cacheJson) as Map<String, dynamic>,
            ),
            chapterAIStatus: const ChapterAIStatus.cacheHit(
              ChapterAIFeature.preview,
              '已读取缓存的读前预览。',
            ),
            isGeneratingChapterPreview: false,
          );
          return;
        }
      }

      if (ai == null) return;
      final result = await ai.generateChapterPreviewWithResult(
        chapterTitle: chapter.title,
        openingText: openingText,
        vocabulary: vocabulary,
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: SpoilerBoundary.chapter(
          bookId: bookId,
          chapterIndex: _currentChapter,
        ),
      );
      final preview = result.value;
      await _recordAIUsage(
        result: result,
        operation: AIUsageOperation.chapterPreview,
        bookId: bookId,
        chapterIndex: _currentChapter,
      );
      state = state.copyWith(
        aiChapterPreview: preview,
        chapterAIStatus: ChapterAIStatus.fromPreview(preview),
        isGeneratingChapterPreview: false,
      );
      if (cache != null) {
        await cache.saveChapterPreview(
          bookId,
          _currentChapter,
          jsonEncode(preview.toJson()),
          contentHash: contentHash,
          promptVersion: ai.promptVersion,
          sourceLanguage: sourceLanguage.code,
          outputLanguage: outputLanguage.code,
        );
      }
    } catch (e) {
      debugPrint('[AI] generateChapterPreview failed: $e');
      state = state.copyWith(
        errorMessage: '生成读前预览失败: $e',
        chapterAIStatus: ChapterAIStatus.failed(
          ChapterAIFeature.preview,
          '读前预览生成失败：$e',
        ),
        isGeneratingChapterPreview: false,
      );
    }
  }

  void toggleSummaryLanguage() {
    state = state.copyWith(
      summaryLanguage: state.summaryLanguage == 'zh' ? 'en' : 'zh',
      aiSummary: null,
      chapterAIStatus: null,
    );
  }

  void clearAIResults() {
    state = state.copyWith(clearAIResults: true);
  }

  Future<void> clearAICache() async {
    await _aiCache?.clearAllCache();
    final totalChapters = ref
        .read(bookshelfNotifierProvider)
        .book
        ?.chapters
        .length;
    state = state.copyWith(
      chapterAISummaryCoverage: totalChapters == null
          ? null
          : ChapterAISummaryCoverage(
              totalChapters: totalChapters,
              generatedChapterIndexes: const [],
            ),
    );
  }

  Future<void> refreshChapterAISummaryCoverage() async {
    await _refreshChapterAISummaryCoverage(notify: true);
  }

  // ---- Internal ----

  ChapterAIJob _createChapterAIJob() {
    final ai = _aiService;
    if (ai == null) throw StateError('AI service not initialized');
    return ChapterAIJob.fromServices(
      aiService: ai,
      cache: _aiCache,
      usageAdapter: CallbackChapterAIUsageAdapter(
        onSummaryGenerated:
            ({
              required String bookId,
              required int chapterIndex,
              AIResult<AISummary>? result,
            }) async {
              _settings.incrementAIUsage(chapterSummary: true);
              await _recordAIUsage(
                result: result,
                operation: AIUsageOperation.chapterSummary,
                bookId: bookId,
                chapterIndex: chapterIndex,
              );
            },
        onPracticeGenerated:
            ({
              required String bookId,
              required int chapterIndex,
              AIResult<AIPracticeSet>? result,
            }) async {
              _settings.incrementAIUsage(practice: true);
              await _recordAIUsage(
                result: result,
                operation: AIUsageOperation.chapterPractice,
                bookId: bookId,
                chapterIndex: chapterIndex,
              );
            },
      ),
    );
  }

  Future<void> _recordAIUsage<T>({
    required AIResult<T>? result,
    required AIUsageOperation operation,
    String? bookId,
    int? chapterIndex,
  }) async {
    if (result == null || result.cacheHit) return;
    final resolvedBookId = bookId ?? _activeBookId;
    final resolvedChapterIndex = chapterIndex ?? _currentChapter;
    try {
      final repository = await ref.read(aiUsageRepositoryProvider.future);
      await repository.recordCall(
        sourceType: resolvedBookId == null
            ? AIUsageSourceType.global
            : AIUsageSourceType.book,
        sourceId: resolvedBookId,
        bookId: resolvedBookId,
        chapterIndex: resolvedBookId == null ? null : resolvedChapterIndex,
        providerId: result.providerId,
        model: result.model,
        operation: operation,
        usage: result.usage,
        durationMs: result.durationMs,
        promptVersion: result.promptVersion,
      );
      ref.invalidate(globalAIUsageProvider);
      if (resolvedBookId != null) {
        ref.invalidate(bookAIUsageProvider(resolvedBookId));
      }
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'ai.usage_record_failed',
        level: AppLogLevel.warning,
        source: 'ai',
        metadata: {
          'operation': operation.value,
          'bookId': resolvedBookId,
          'chapterIndex': resolvedChapterIndex,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveChapterSummarySourceScope({
    required String bookId,
    required int chapterIndex,
    required AISummary summary,
  }) async {
    try {
      final book = ref.read(bookshelfNotifierProvider).book;
      await ref
          .read(chapterSummarySourceScopeCacheProvider)
          .saveChapterSummary(
            bookId: bookId,
            bookTitle: book?.title ?? bookId,
            author: book?.author,
            languageCode: book?.language,
            chapterIndex: chapterIndex,
            summary: summary,
            outputLanguage: state.summaryLanguage,
          );
    } catch (e, stackTrace) {
      AppLogger.instance.event(
        'reading_memory.chapter_summary_source_cache_failed',
        level: AppLogLevel.warning,
        source: 'reading_memory',
        metadata: {
          'bookId': bookId,
          'chapterIndex': chapterIndex,
        },
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isPersistableChapterSummary(AISummary summary) {
    return !summary.isEmpty && !ChapterAIStatus.isSummaryFallback(summary);
  }

  String _chapterPreviewOpening(String chapterText) {
    final trimmed = chapterText.trim();
    if (trimmed.length <= _chapterPreviewMaxLength) return trimmed;
    return trimmed.substring(0, _chapterPreviewMaxLength).trim();
  }

  LearningItemSource _currentLearningItemSource() {
    final bookId = _activeBookId;
    final book = ref.read(bookshelfNotifierProvider).book;
    if (bookId == null || book == null) {
      return const LearningItemSource.unknown();
    }
    final chapter = _currentChapter < book.chapters.length
        ? book.chapters[_currentChapter]
        : null;
    return LearningItemSource(
      bookId: bookId,
      bookTitle: book.title,
      chapterIndex: _currentChapter,
      chapterTitle: chapter?.title ?? '',
    );
  }

  Future<void> _refreshChapterAISummaryCoverage({
    bool notify = true,
  }) async {
    final aiCache = _aiCache;
    final bookId = _activeBookId;
    final totalChapters = ref
        .read(bookshelfNotifierProvider)
        .book
        ?.chapters
        .length;
    if (aiCache == null || bookId == null || totalChapters == null) {
      state = state.copyWith(
        chapterAISummaryCoverage: null,
        isLoadingChapterAISummaryCoverage: false,
      );
      return;
    }

    if (notify) {
      state = state.copyWith(isLoadingChapterAISummaryCoverage: true);
    }

    try {
      final coverage = await aiCache.summaryCoverageFor(
        bookId,
        totalChapters: totalChapters,
      );
      if (_activeBookId == bookId &&
          ref.read(bookshelfNotifierProvider).book?.chapters.length ==
              totalChapters) {
        state = state.copyWith(
          chapterAISummaryCoverage: coverage,
          isLoadingChapterAISummaryCoverage: false,
        );
      } else {
        state = state.copyWith(isLoadingChapterAISummaryCoverage: false);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.event(
        'ai.summary_coverage_failed',
        level: AppLogLevel.warning,
        source: 'ai',
        metadata: {'bookId': bookId},
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isLoadingChapterAISummaryCoverage: false);
    }
  }
}

final aiNotifierProvider = NotifierProvider<AINotifier, AIState>(
  AINotifier.new,
);
