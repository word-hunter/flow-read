class HiveTypeIds {
  const HiveTypeIds._();

  static const bookMetadata = 0;
  static const bookmarkedWord = 1;
  static const readingBookmark = 2;
  static const readingConfig = 3;
  static const wordLevelInfo = 4;
  static const rssFeedSubscription = 10;
  static const learningItem = 11;

  static const reserved = <int>{
    bookMetadata,
    bookmarkedWord,
    readingBookmark,
    readingConfig,
    wordLevelInfo,
    rssFeedSubscription,
    learningItem,
  };
}
