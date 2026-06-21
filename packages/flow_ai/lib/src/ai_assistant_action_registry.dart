import 'models/ai_assistant_action.dart';
import 'models/ai_context_snapshot.dart';
import 'models/character_registry_entry.dart';
import 'models/reading_insight_profile.dart';
import 'explanation_context_selector.dart';
import 'prompt_builder.dart';

class AIAssistantActionRegistry {
  const AIAssistantActionRegistry({
    required this.promptBuilder,
    this.characterRegistry = const [],
    this.insightProfile,
    this.contextSelector,
  });

  final PromptBuilder promptBuilder;
  final List<CharacterRegistryEntry> characterRegistry;
  final ReadingInsightProfile? insightProfile;
  final ExplanationContextSelector? contextSelector;

  List<AIAssistantActionType> availableActions(AIContextSnapshot context) {
    return AIAssistantActionType.values
        .where((action) => action != AIAssistantActionType.chat)
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
          contextBundle: context.contextBundle?.formatForPrompt(),
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
          contextBundle: context.contextBundle?.formatForPrompt(),
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
      AIAssistantActionType.chat => _buildChatPrompt(
        context,
        followUpQuestion,
        sourceLanguage,
        outputLanguage,
        spoilerBoundary,
      ),
      AIAssistantActionType.paragraphInsight =>
        promptBuilder.buildParagraphInsight(
          ParagraphInsightPromptRequest(
            paragraphText:
                context.surroundingPassage ?? context.selectedText ?? '',
            sourceLanguage: sourceLanguage,
            outputLanguage: outputLanguage,
            spoilerBoundary: spoilerBoundary,
            contextBundle: context.contextBundle?.formatForPrompt(),
          ),
        ),
    };
  }

  AIContextScope defaultScope(AIAssistantActionType action) {
    return switch (action) {
      AIAssistantActionType.summary ||
      AIAssistantActionType.questionGeneration ||
      AIAssistantActionType.paragraphInsight => AIContextScope.currentChapter,
      AIAssistantActionType.chat => AIContextScope.currentPassage,
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
      AIAssistantActionType.paragraphInsight => const ['surroundingPassage'],
      AIAssistantActionType.chat => const ['context'],
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
              AIAssistantActionType.paragraphInsight,
              AIAssistantActionType.chat,
            }.contains(action),
      AIContextSource.readerParagraph =>
        _hasText(context.surroundingPassage) &&
            {
              AIAssistantActionType.explain,
              AIAssistantActionType.translate,
              AIAssistantActionType.phraseExtraction,
              AIAssistantActionType.pronounReference,
              AIAssistantActionType.paragraphInsight,
              AIAssistantActionType.chat,
            }.contains(action),
      AIContextSource.readerWord =>
        hasWord &&
            {
              AIAssistantActionType.wordAnalysis,
              AIAssistantActionType.chat,
            }.contains(action),
      AIContextSource.readerChapter =>
        hasChapter &&
            {
              AIAssistantActionType.questionGeneration,
              AIAssistantActionType.summary,
              AIAssistantActionType.chat,
            }.contains(action),
      AIContextSource.rssArticle =>
        hasArticle &&
            {
              AIAssistantActionType.translate,
              AIAssistantActionType.questionGeneration,
              AIAssistantActionType.summary,
              AIAssistantActionType.articleQA,
              AIAssistantActionType.chat,
            }.contains(action),
      AIContextSource.internalWeb =>
        hasArticle &&
            {
              AIAssistantActionType.explain,
              AIAssistantActionType.translate,
              AIAssistantActionType.summary,
              AIAssistantActionType.articleQA,
              AIAssistantActionType.chat,
            }.contains(action),
    };
  }

  PromptBuildResult _buildChatPrompt(
    AIContextSnapshot context,
    String? followUpQuestion,
    SourceLanguage sourceLanguage,
    OutputLanguage outputLanguage,
    SpoilerBoundary spoilerBoundary,
  ) {
    return promptBuilder.buildArticleAnswer(
      ArticlePromptRequest(
        surfaceLabel: _chatSurfaceLabel(context),
        title: _chatTitle(context),
        text: [
          _chatContextText(context),
          if (context.contextBundle?.isEmpty == false)
            'Personal Learning Memory Context:\n${context.contextBundle!.formatForPrompt()}',
        ].where((part) => part.trim().isNotEmpty).join('\n\n'),
        question: followUpQuestion ?? '',
        sourceLanguage: sourceLanguage,
        outputLanguage: outputLanguage,
        spoilerBoundary: spoilerBoundary,
      ),
    );
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

  String _chatSurfaceLabel(AIContextSnapshot context) {
    return switch (context.source) {
      AIContextSource.readerSelectedText => 'Reader Selection',
      AIContextSource.readerParagraph => 'Reader Paragraph',
      AIContextSource.readerWord => 'Reader Word',
      AIContextSource.readerChapter => 'Reader Chapter',
      AIContextSource.rssArticle => 'RSS Article',
      AIContextSource.internalWeb => 'Internal Web',
    };
  }

  String _chatTitle(AIContextSnapshot context) {
    return context.chapterTitle ??
        context.articleTitle ??
        context.word ??
        context.source.name;
  }

  String _chatContextText(AIContextSnapshot context) {
    final parts = <String>[];
    if (_hasText(context.word)) {
      parts.add('Word: ${context.word}');
    }
    if (_hasText(context.selectedText)) {
      parts.add('Selected Text: ${context.selectedText}');
    }
    if (_hasText(context.wordSentence)) {
      parts.add('Sentence: ${context.wordSentence}');
    }
    if (_hasText(context.surroundingPassage)) {
      parts.add('Current Passage: ${context.surroundingPassage}');
    }
    if (_hasText(context.chapterContent)) {
      parts.add('Chapter Content: ${context.chapterContent}');
    }
    if (_hasText(context.articleContent)) {
      parts.add('Article Content: ${context.articleContent}');
    }
    return parts.join('\n\n');
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
