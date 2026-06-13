class LegacyBackupBoxNames {
  const LegacyBackupBoxNames._();

  static const defaultLanguageCode = 'en';
  static const activeSourceLanguageKey = 'active_source_language';

  // v1 boxes are kept for migrations and rollback safety.
  static const books = 'books';
  static const userVocabulary = 'user_vocabulary';
  static const wordBookmarks = 'word_bookmarks';
  static const readingBookmarks = 'reading_bookmarks';
  static const readingConfig = 'reading_config';
  static const readingTime = 'reading_time';
  static const dictionaryCache = 'dictionary_cache';
  static const wordContexts = 'word_contexts';
  static const learningItems = 'learning_items';
  static const learningAnalytics = 'learning_analytics';

  // Global boxes.
  static const settings = 'settings';
  static const wordLevels = 'word_levels';
  static const rssSubscriptions = 'rss_subscriptions';
  static const bookGlossary = 'book_glossary';
  static const characterRegistry = 'character_registry';

  static String booksFor(String lang) => 'books_${_normalize(lang)}';
  static String userVocabularyFor(String lang) =>
      'user_vocabulary_${_normalize(lang)}';
  static String wordBookmarksFor(String lang) =>
      'word_bookmarks_${_normalize(lang)}';
  static String wordContextsFor(String lang) =>
      'word_contexts_${_normalize(lang)}';
  static String dictionaryCacheFor(String lang) =>
      'dictionary_cache_${_normalize(lang)}';
  static String readingBookmarksFor(String lang) =>
      'reading_bookmarks_${_normalize(lang)}';
  static String readingConfigFor(String lang) =>
      'reading_config_${_normalize(lang)}';
  static String readingTimeFor(String lang) =>
      'reading_time_${_normalize(lang)}';
  static String learningItemsFor(String lang) =>
      'learning_items_${_normalize(lang)}';
  static String learningAnalyticsFor(String lang) =>
      'learning_analytics_${_normalize(lang)}';

  static List<String> languageScopedBoxesFor(String lang) {
    return [
      booksFor(lang),
      userVocabularyFor(lang),
      wordBookmarksFor(lang),
      readingBookmarksFor(lang),
      readingConfigFor(lang),
      readingTimeFor(lang),
      dictionaryCacheFor(lang),
      wordContextsFor(lang),
      learningItemsFor(lang),
      learningAnalyticsFor(lang),
    ];
  }

  static List<String> bootstrapBoxesFor(String lang) {
    return [
      settings,
      ...languageScopedBoxesFor(lang),
      wordLevels,
      rssSubscriptions,
      bookGlossary,
      characterRegistry,
    ];
  }

  static const bootstrapBoxes = <String>[
    settings,
    'books_en',
    'user_vocabulary_en',
    'word_bookmarks_en',
    'reading_bookmarks_en',
    'reading_config_en',
    'reading_time_en',
    'dictionary_cache_en',
    'word_contexts_en',
    'learning_items_en',
    'learning_analytics_en',
    wordLevels,
    rssSubscriptions,
    bookGlossary,
    characterRegistry,
  ];

  static String _normalize(String lang) {
    final normalized = lang.trim().toLowerCase();
    return normalized.isEmpty ? defaultLanguageCode : normalized;
  }
}
