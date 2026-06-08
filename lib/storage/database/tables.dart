import 'package:drift/drift.dart';

const _emptyStr = '';
const _defaultLang = 'en';
const _zeroInt = 0;
const _zeroReal = 0.0;

String _nowIso() => DateTime.now().toUtc().toIso8601String();

// ---------------------------------------------------------------------------
// Table 1: books
// ---------------------------------------------------------------------------

@DataClassName('BookEntry')
@TableIndex(name: 'idx_books_language', columns: {#language})
@TableIndex(
  name: 'idx_books_last_read',
  columns: {#lastReadAt},
)
class BookEntries extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get title => text()();

  TextColumn get author => text().withDefault(const Constant(_emptyStr))();

  TextColumn get sourcePath => text().named('source_path')();

  TextColumn get coverPath => text().named('cover_path').nullable()();

  IntColumn get totalChapters =>
      integer().named('total_chapters').withDefault(const Constant(_zeroInt))();

  RealColumn get globalProgress =>
      real().named('global_progress').withDefault(const Constant(_zeroReal))();

  IntColumn get currentChapter =>
      integer().named('current_chapter').withDefault(const Constant(_zeroInt))();

  RealColumn get chapterProgress =>
      real().named('chapter_progress').withDefault(const Constant(_zeroReal))();

  TextColumn get lastReadAt => text().named('last_read_at').nullable()();

  RealColumn get chapterScrollOffset =>
      real().named('chapter_scroll_offset').nullable()();

  TextColumn get sourceLanguage =>
      text()
          .named('source_language')
          .withDefault(const Constant(_defaultLang))();

  TextColumn get sourceLanguageOverride =>
      text().named('source_language_override').nullable()();

  RealColumn get languageConfidence =>
      real().named('language_confidence').nullable()();

  TextColumn get targetExplanationLanguage =>
      text().named('target_explanation_language').nullable()();

  TextColumn get difficultyStudyWords =>
      text().named('difficulty_study_words').nullable()();

  TextColumn get difficultyRatingJson =>
      text().named('difficulty_rating_json').nullable()();

  TextColumn get difficultyVocabularySignature =>
      text().named('difficulty_vocabulary_signature').nullable()();

  TextColumn get difficultyComputedAt =>
      text().named('difficulty_computed_at').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'books';
}

// ---------------------------------------------------------------------------
// Table 2: user_vocabulary
// ---------------------------------------------------------------------------

@DataClassName('UserVocabulary')
@TableIndex(name: 'idx_user_vocab_lang_canonical', columns: {#language, #canonical})
@TableIndex(name: 'idx_user_vocab_status', columns: {#status})
class UserVocabularies extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get canonical => text()();

  TextColumn get status => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  TextColumn get lastModifiedAt =>
      text().named('last_modified_at').clientDefault(_nowIso)();

  TextColumn get sourceBookId => text().named('source_book_id').nullable()();

  IntColumn get sourceChapterIndex =>
      integer().named('source_chapter_index').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'user_vocabulary';

  @override
  List<String> get customConstraints => [
        'CHECK(status IN (\'known\', \'learning\'))',
        'FOREIGN KEY (source_book_id) REFERENCES books(id) ON DELETE SET NULL',
      ];
}

// ---------------------------------------------------------------------------
// Table 3: word_bookmarks
// ---------------------------------------------------------------------------

@DataClassName('WordBookmark')
@TableIndex(name: 'idx_word_bookmarks_book', columns: {#bookId})
@TableIndex(name: 'idx_word_bookmarks_word', columns: {#word})
class WordBookmarks extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get bookId => text().named('book_id')();

  TextColumn get word => text()();

  TextColumn get translation => text().withDefault(const Constant(_emptyStr))();

  TextColumn get context => text().withDefault(const Constant(_emptyStr))();

  TextColumn get addedAt =>
      text().named('added_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE',
      ];
}

// ---------------------------------------------------------------------------
// Table 4: reading_bookmarks
// ---------------------------------------------------------------------------

@DataClassName('ReadingBookmarkEntry')
@TableIndex(name: 'idx_reading_bookmarks_book', columns: {#bookId})
class ReadingBookmarks extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get bookId => text().named('book_id')();

  IntColumn get chapterIndex => integer().named('chapter_index')();

  RealColumn get progress => real()();

  TextColumn get chapterTitle =>
      text().named('chapter_title').withDefault(const Constant(_emptyStr))();

  TextColumn get excerpt => text().withDefault(const Constant(_emptyStr))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE',
      ];
}

// ---------------------------------------------------------------------------
// Table 5: reading_config
// ---------------------------------------------------------------------------

@DataClassName('ReadingConfigEntry')
class ReadingConfig extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get value => text().withDefault(const Constant(_emptyStr))();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 6: reading_time
// ---------------------------------------------------------------------------

@DataClassName('ReadingTimeEntry')
class ReadingTime extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  IntColumn get seconds => integer().withDefault(const Constant(_zeroInt))();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 7: dictionary_cache
// ---------------------------------------------------------------------------

@DataClassName('DictionaryCacheEntry')
class DictionaryCache extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get value => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 8: word_contexts
// ---------------------------------------------------------------------------

@DataClassName('WordContextEntry')
class WordContexts extends Table {
  TextColumn get word => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get data => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {word, language};
}

// ---------------------------------------------------------------------------
// Table 9: learning_items
// ---------------------------------------------------------------------------

@DataClassName('LearningItemEntry')
@TableIndex(name: 'idx_learning_items_type', columns: {#type})
@TableIndex(name: 'idx_learning_items_book', columns: {#bookId})
@TableIndex(name: 'idx_learning_items_next_review', columns: {#nextReviewAt})
@TableIndex(name: 'idx_learning_items_lang', columns: {#language})
class LearningItems extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  TextColumn get type => text()();

  TextColumn get canonicalKey =>
      text().named('canonical_key').withDefault(const Constant(_emptyStr))();

  TextColumn get title => text().withDefault(const Constant(_emptyStr))();

  TextColumn get content => text().withDefault(const Constant(_emptyStr))();

  TextColumn get answer => text().withDefault(const Constant(_emptyStr))();

  TextColumn get note => text().withDefault(const Constant(_emptyStr))();

  TextColumn get sourceText =>
      text().named('source_text').withDefault(const Constant(_emptyStr))();

  TextColumn get bookId =>
      text().named('book_id').withDefault(const Constant(_emptyStr))();

  IntColumn get chapterIndex =>
      integer().named('chapter_index').withDefault(const Constant(_zeroInt))();

  TextColumn get chapterTitle =>
      text().named('chapter_title').withDefault(const Constant(_emptyStr))();

  TextColumn get tags => text().withDefault(const Constant('[]'))();

  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  TextColumn get nextReviewAt => text().named('next_review_at')();

  IntColumn get reviewCount =>
      integer().named('review_count').withDefault(const Constant(_zeroInt))();

  TextColumn get lastResult =>
      text()
          .named('last_result')
          .withDefault(const Constant('newItem'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK(type IN (\'word\', \'sentence\', \'grammar\','
            ' \'expression\', \'questionMistake\'))',
        'CHECK(last_result IN (\'newItem\', \'remembered\', \'missed\'))',
        'FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE SET NULL',
      ];
}

// ---------------------------------------------------------------------------
// Table 10: learning_analytics
// ---------------------------------------------------------------------------

@DataClassName('LearningAnalyticsEntry')
class LearningAnalytics extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(_defaultLang))();

  IntColumn get value => integer().withDefault(const Constant(_zeroInt))();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 11: word_levels
// ---------------------------------------------------------------------------

@DataClassName('WordLevelEntry')
@TableIndex(name: 'idx_word_levels_level', columns: {#levelIndex})
class WordLevels extends Table {
  TextColumn get word => text()();

  TextColumn get originForm =>
      text().named('origin_form').withDefault(const Constant(_emptyStr))();

  IntColumn get levelIndex => integer().named('level_index')();

  @override
  Set<Column> get primaryKey => {word};

  @override
  List<String> get customConstraints => [
        'CHECK(level_index BETWEEN 0 AND 6)',
      ];
}

// ---------------------------------------------------------------------------
// Table 12: rss_subscriptions
// ---------------------------------------------------------------------------

@DataClassName('RssSubscriptionEntry')
@TableIndex(name: 'idx_rss_url', columns: {#url}, unique: true)
class RssSubscriptions extends Table {
  TextColumn get id => text()();

  TextColumn get url => text()();

  TextColumn get title => text().withDefault(const Constant(_emptyStr))();

  TextColumn get description => text().nullable()();

  TextColumn get imageUrl => text().named('image_url').nullable()();

  TextColumn get lastFetchedAt => text().named('last_fetched_at').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Table 13: rss_articles
// ---------------------------------------------------------------------------

@DataClassName('RssArticleEntry')
@TableIndex(name: 'idx_rss_articles_sub', columns: {#subscriptionId})
@TableIndex(name: 'idx_rss_articles_unread', columns: {#isRead, #pubDate})
@TableIndex(name: 'idx_rss_articles_fav', columns: {#isFavorite})
@TableIndex(name: 'idx_rss_articles_later', columns: {#isReadLater})
class RssArticles extends Table {
  TextColumn get id => text()();

  TextColumn get subscriptionId => text().named('subscription_id')();

  TextColumn get feedUrl => text().named('feed_url')();

  TextColumn get feedTitle =>
      text().named('feed_title').withDefault(const Constant(_emptyStr))();

  TextColumn get title => text()();

  TextColumn get link => text().nullable()();

  TextColumn get description => text().nullable()();

  TextColumn get content => text().nullable()();

  TextColumn get bodyBlocks =>
      text().named('body_blocks').withDefault(const Constant('[]'))();

  TextColumn get images => text().withDefault(const Constant('[]'))();

  TextColumn get pubDate => text().named('pub_date').nullable()();

  TextColumn get author => text().nullable()();

  BoolColumn get isRead => boolean().named('is_read')();

  BoolColumn get isFavorite => boolean().named('is_favorite')();

  BoolColumn get isReadLater => boolean().named('is_read_later')();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (subscription_id) REFERENCES rss_subscriptions(id) '
            'ON DELETE CASCADE',
      ];
}

// ---------------------------------------------------------------------------
// Table 14: book_glossary
// ---------------------------------------------------------------------------

@DataClassName('BookGlossaryEntry')
@TableIndex(name: 'idx_glossary_book', columns: {#bookId})
@TableIndex(name: 'idx_glossary_word', columns: {#word})
class BookGlossary extends Table {
  TextColumn get id => text()();

  TextColumn get bookId => text().named('book_id')();

  TextColumn get word => text()();

  TextColumn get canonicalForm => text().named('canonical_form').nullable()();

  TextColumn get explanation => text().withDefault(const Constant(_emptyStr))();

  TextColumn get sourceContext =>
      text().named('source_context').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(_nowIso)();

  TextColumn get lastAccessedAt =>
      text().named('last_accessed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE',
      ];
}

// ---------------------------------------------------------------------------
// Table 15: character_registry
// ---------------------------------------------------------------------------

@DataClassName('CharacterRegistryEntry')
class CharacterRegistry extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().withDefault(const Constant(_emptyStr))();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Table 16: settings
// ---------------------------------------------------------------------------

@DataClassName('SettingsEntry')
class Settings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().withDefault(const Constant(_emptyStr))();

  @override
  Set<Column> get primaryKey => {key};
}
