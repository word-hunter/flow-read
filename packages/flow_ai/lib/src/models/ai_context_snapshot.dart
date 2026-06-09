import '../prompt_builder.dart' show AIContextScope, SpoilerBoundary;

enum AIContextSource {
  readerSelectedText,
  readerParagraph,
  readerWord,
  readerChapter,
  rssArticle,
  internalWeb,
}

class AIContextSnapshot {
  AIContextSnapshot({
    required this.source,
    this.bookId,
    this.chapterIndex,
    this.chapterTitle,
    this.selectedText,
    this.surroundingPassage,
    this.word,
    this.wordSentence,
    this.chapterContent,
    this.articleTitle,
    this.articleContent,
    this.articleUrl,
    AIContextScope? scope,
    this.spoilerBoundary,
    this.sourceLanguage = 'en',
    this.outputLanguage = 'zh',
  }) : scope = scope ?? defaultScopeFor(source);

  final AIContextSource source;
  final String? bookId;
  final int? chapterIndex;
  final String? chapterTitle;
  final String? selectedText;
  final String? surroundingPassage;
  final String? word;
  final String? wordSentence;
  final String? chapterContent;
  final String? articleTitle;
  final String? articleContent;
  final String? articleUrl;
  final AIContextScope scope;
  final SpoilerBoundary? spoilerBoundary;
  final String sourceLanguage;
  final String outputLanguage;

  static AIContextScope defaultScopeFor(AIContextSource source) {
    return switch (source) {
      AIContextSource.readerSelectedText ||
      AIContextSource.readerParagraph ||
      AIContextSource.readerWord ||
      AIContextSource.internalWeb => AIContextScope.currentPassage,
      AIContextSource.readerChapter ||
      AIContextSource.rssArticle => AIContextScope.currentChapter,
    };
  }

  bool get hasPrimaryContent {
    return switch (source) {
      AIContextSource.readerSelectedText =>
        selectedText != null && selectedText!.trim().isNotEmpty,
      AIContextSource.readerParagraph =>
        surroundingPassage != null && surroundingPassage!.trim().isNotEmpty,
      AIContextSource.readerWord => word != null && word!.trim().isNotEmpty,
      AIContextSource.readerChapter =>
        chapterContent != null && chapterContent!.trim().isNotEmpty,
      AIContextSource.rssArticle || AIContextSource.internalWeb =>
        articleContent != null && articleContent!.trim().isNotEmpty,
    };
  }
}
