import '../models/ai_assistant_action.dart';
import '../models/ai_context_snapshot.dart';
import '../models/character_registry_entry.dart';
import '../models/reading_insight_profile.dart';
import 'prompt_builder.dart';

class AIAssistantActionRegistry {
  const AIAssistantActionRegistry({
    required this.promptBuilder,
    this.characterRegistry = const [],
    this.insightProfile,
  });

  final PromptBuilder promptBuilder;
  final List<CharacterRegistryEntry> characterRegistry;
  final ReadingInsightProfile? insightProfile;

  List<AIAssistantActionType> availableActions(AIContextSnapshot context) {
    return AIAssistantActionType.values
        .where((action) => _isAvailable(action, context))
        .toList(growable: false);
  }

  PromptBuildResult buildPrompt(
    AIAssistantActionType action,
    AIContextSnapshot context, {
    String? followUpQuestion,
  }) {
    if (!_isAvailable(action, context)) {
      throw ArgumentError('Action ${action.name} is not available.');
    }

    final sourceLanguage = SourceLanguage.fromCode(context.sourceLanguage);
    final outputLanguage = OutputLanguage.fromCode(context.outputLanguage);
    final spoilerBoundary =
        context.spoilerBoundary ?? _fallbackSpoilerBoundary(context);

    return switch (action) {
      AIAssistantActionType.explain ||
      AIAssistantActionType.phraseExtraction ||
      AIAssistantActionType.pronounReference => promptBuilder.buildTextAnalysis(
        TextAnalysisPromptRequest(
          selectedText: _selectedText(context),
          currentPassage: _passageText(context),
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      ),
      AIAssistantActionType.translate => promptBuilder.buildTranslation(
        TranslationPromptRequest(
          selectedText: _translationText(context),
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      ),
      AIAssistantActionType.questionGeneration => _buildQuestionPrompt(
        context,
        sourceLanguage,
        outputLanguage,
        spoilerBoundary,
      ),
      AIAssistantActionType.summary => _buildSummaryPrompt(
        context,
        sourceLanguage,
        outputLanguage,
        spoilerBoundary,
      ),
      AIAssistantActionType.wordAnalysis => promptBuilder.buildWordAnalysis(
        WordAnalysisPromptRequest(
          word: context.word ?? '',
          sentence: context.wordSentence ?? context.surroundingPassage ?? '',
          chapterContext: context.surroundingPassage ?? '',
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      ),
      AIAssistantActionType.articleQA => promptBuilder.buildArticleAnswer(
        ArticlePromptRequest(
          surfaceLabel: _articleSurfaceLabel(context),
          title: context.articleTitle ?? '',
          text: context.articleContent ?? '',
          url: context.articleUrl,
          question: followUpQuestion ?? '',
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      ),
    };
  }

  AIContextScope defaultScope(AIAssistantActionType action) {
    return switch (action) {
      AIAssistantActionType.summary ||
      AIAssistantActionType.questionGeneration => AIContextScope.currentChapter,
      _ => AIContextScope.currentPassage,
    };
  }

  List<String> requiredContext(AIAssistantActionType action) {
    return switch (action) {
      AIAssistantActionType.explain ||
      AIAssistantActionType.translate ||
      AIAssistantActionType.phraseExtraction ||
      AIAssistantActionType.pronounReference => const ['selectedText'],
      AIAssistantActionType.wordAnalysis => const ['word'],
      AIAssistantActionType.summary ||
      AIAssistantActionType.questionGeneration => const ['chapterContent'],
      AIAssistantActionType.articleQA => const ['articleContent'],
    };
  }

  bool _isAvailable(
    AIAssistantActionType action,
    AIContextSnapshot context,
  ) {
    final hasSelectedText = _hasText(context.selectedText);
    final hasWord = _hasText(context.word);
    final hasChapter = _hasText(context.chapterContent);
    final hasArticle = _hasText(context.articleContent);

    return switch (context.source) {
      AIContextSource.readerSelectedText =>
        hasSelectedText &&
            {
              AIAssistantActionType.explain,
              AIAssistantActionType.translate,
              AIAssistantActionType.phraseExtraction,
              AIAssistantActionType.pronounReference,
            }.contains(action),
      AIContextSource.readerParagraph =>
        _hasText(context.surroundingPassage) &&
            {
              AIAssistantActionType.explain,
              AIAssistantActionType.translate,
              AIAssistantActionType.phraseExtraction,
            }.contains(action),
      AIContextSource.readerWord =>
        hasWord && action == AIAssistantActionType.wordAnalysis,
      AIContextSource.readerChapter =>
        hasChapter &&
            {
              AIAssistantActionType.questionGeneration,
              AIAssistantActionType.summary,
            }.contains(action),
      AIContextSource.rssArticle =>
        hasArticle &&
            {
              AIAssistantActionType.translate,
              AIAssistantActionType.questionGeneration,
              AIAssistantActionType.summary,
              AIAssistantActionType.articleQA,
            }.contains(action),
      AIContextSource.internalWeb =>
        hasArticle &&
            {
              AIAssistantActionType.explain,
              AIAssistantActionType.translate,
              AIAssistantActionType.summary,
            }.contains(action),
    };
  }

  PromptBuildResult _buildQuestionPrompt(
    AIContextSnapshot context,
    SourceLanguage sourceLanguage,
    OutputLanguage outputLanguage,
    SpoilerBoundary spoilerBoundary,
  ) {
    if (context.source == AIContextSource.rssArticle) {
      return promptBuilder.buildArticleAnswer(
        ArticlePromptRequest(
          surfaceLabel: _articleSurfaceLabel(context),
          title: context.articleTitle ?? '',
          text: context.articleContent ?? '',
          url: context.articleUrl,
          question: 'Generate 3-5 reading comprehension questions.',
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      );
    }
    return promptBuilder.buildPractice(
      PracticePromptRequest(
        chapterText: context.chapterContent ?? '',
        vocabulary: const [],
        events: const [],
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary,
      ),
    );
  }

  PromptBuildResult _buildSummaryPrompt(
    AIContextSnapshot context,
    SourceLanguage sourceLanguage,
    OutputLanguage outputLanguage,
    SpoilerBoundary spoilerBoundary,
  ) {
    if (context.source == AIContextSource.rssArticle ||
        context.source == AIContextSource.internalWeb) {
      return promptBuilder.buildArticleSummary(
        ArticlePromptRequest(
          surfaceLabel: _articleSurfaceLabel(context),
          title: context.articleTitle ?? '',
          text: context.articleContent ?? '',
          url: context.articleUrl,
          sourceLanguage: sourceLanguage,
          outputLanguage: outputLanguage,
          spoilerBoundary: spoilerBoundary,
        ),
      );
    }
    return promptBuilder.buildChapterSummary(
      ChapterSummaryPromptRequest(
        chapterText: context.chapterContent ?? '',
        vocabulary: const [],
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary,
      ),
    );
  }

  SpoilerBoundary _fallbackSpoilerBoundary(AIContextSnapshot context) {
    final bookId = context.bookId;
    final chapterIndex = context.chapterIndex;
    if (bookId != null && chapterIndex != null) {
      return SpoilerBoundary.chapter(
        bookId: bookId,
        chapterIndex: chapterIndex,
        scope: context.scope,
      );
    }
    return SpoilerBoundary.currentPassage();
  }

  String _selectedText(AIContextSnapshot context) {
    return context.selectedText ?? context.surroundingPassage ?? '';
  }

  String _passageText(AIContextSnapshot context) {
    return context.surroundingPassage ??
        context.selectedText ??
        context.articleContent ??
        '';
  }

  String _translationText(AIContextSnapshot context) {
    return context.selectedText ??
        context.articleContent ??
        context.surroundingPassage ??
        '';
  }

  String _articleSurfaceLabel(AIContextSnapshot context) {
    return context.source == AIContextSource.internalWeb
        ? 'Internal Web'
        : 'RSS Article';
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
