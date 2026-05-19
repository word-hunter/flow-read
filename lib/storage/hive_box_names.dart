class HiveBoxNames {
  const HiveBoxNames._();

  static const books = 'books';
  static const userVocabulary = 'user_vocabulary';
  static const settings = 'settings';
  static const wordBookmarks = 'word_bookmarks';
  static const readingBookmarks = 'reading_bookmarks';
  static const readingConfig = 'reading_config';
  static const readingTime = 'reading_time';
  static const wordLevels = 'word_levels';
  static const dictionaryCache = 'dictionary_cache';
  static const rssSubscriptions = 'rss_subscriptions';
  static const wordContexts = 'word_contexts';
  static const learningItems = 'learning_items';

  static const bootstrapBoxes = <String>[
    books,
    userVocabulary,
    settings,
    wordBookmarks,
    readingBookmarks,
    readingConfig,
    readingTime,
    wordLevels,
    dictionaryCache,
    rssSubscriptions,
    wordContexts,
    learningItems,
  ];

  static const backupIncludedBoxes = <String>[
    books,
    userVocabulary,
    settings,
    wordBookmarks,
    readingBookmarks,
    readingConfig,
    readingTime,
    dictionaryCache,
    rssSubscriptions,
    wordContexts,
    learningItems,
  ];
}
