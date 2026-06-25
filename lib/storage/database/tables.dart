import 'package:drift/drift.dart';

const kEmptyStr = '';
const kDefaultLang = 'en';
const kZeroInt = 0;
const kZeroReal = 0.0;

String nowIso() => DateTime.now().toUtc().toIso8601String();

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

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get title => text()();

  TextColumn get author => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get sourcePath => text().named('source_path')();

  TextColumn get coverPath => text().named('cover_path').nullable()();

  IntColumn get totalChapters =>
      integer().named('total_chapters').withDefault(const Constant(kZeroInt))();

  RealColumn get globalProgress =>
      real().named('global_progress').withDefault(const Constant(kZeroReal))();

  IntColumn get currentChapter => integer()
      .named('current_chapter')
      .withDefault(const Constant(kZeroInt))();

  RealColumn get chapterProgress =>
      real().named('chapter_progress').withDefault(const Constant(kZeroReal))();

  TextColumn get lastReadAt => text().named('last_read_at').nullable()();

  RealColumn get chapterScrollOffset =>
      real().named('chapter_scroll_offset').nullable()();

  TextColumn get sourceLanguage => text()
      .named('source_language')
      .withDefault(const Constant(kDefaultLang))();

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
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'books';
}

// ---------------------------------------------------------------------------
// Table 2: user_vocabulary
// ---------------------------------------------------------------------------

@DataClassName('UserVocabulary')
@TableIndex(
  name: 'idx_user_vocab_lang_canonical',
  columns: {#language, #canonical},
)
@TableIndex(name: 'idx_user_vocab_status', columns: {#status})
class UserVocabularies extends Table {
  TextColumn get id => text()();

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get canonical => text()();

  TextColumn get status => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get lastModifiedAt =>
      text().named('last_modified_at').clientDefault(nowIso)();

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

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get bookId => text().named('book_id')();

  TextColumn get word => text()();

  TextColumn get translation => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get context => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get addedAt => text().named('added_at').clientDefault(nowIso)();

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

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get bookId => text().named('book_id')();

  IntColumn get chapterIndex => integer().named('chapter_index')();

  RealColumn get progress => real()();

  TextColumn get chapterTitle =>
      text().named('chapter_title').withDefault(const Constant(kEmptyStr))();

  TextColumn get excerpt => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

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

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get value => text().withDefault(const Constant(kEmptyStr))();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 6: reading_time
// ---------------------------------------------------------------------------

@DataClassName('ReadingTimeEntry')
class ReadingTime extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  IntColumn get seconds => integer().withDefault(const Constant(kZeroInt))();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 7: dictionary_cache
// ---------------------------------------------------------------------------

@DataClassName('DictionaryCacheEntry')
class DictionaryCache extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get value => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {key, language};
}

// ---------------------------------------------------------------------------
// Table 8: word_contexts
// ---------------------------------------------------------------------------

@DataClassName('WordContextEntry')
class WordContexts extends Table {
  TextColumn get word => text()();

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get data => text()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

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

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  TextColumn get type => text()();

  TextColumn get canonicalKey =>
      text().named('canonical_key').withDefault(const Constant(kEmptyStr))();

  TextColumn get title => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get content => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get answer => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get note => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get sourceText =>
      text().named('source_text').withDefault(const Constant(kEmptyStr))();

  TextColumn get bookId =>
      text().named('book_id').withDefault(const Constant(kEmptyStr))();

  IntColumn get chapterIndex =>
      integer().named('chapter_index').withDefault(const Constant(kZeroInt))();

  TextColumn get chapterTitle =>
      text().named('chapter_title').withDefault(const Constant(kEmptyStr))();

  TextColumn get tags => text().withDefault(const Constant('[]'))();

  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  TextColumn get nextReviewAt => text().named('next_review_at')();

  IntColumn get reviewCount =>
      integer().named('review_count').withDefault(const Constant(kZeroInt))();

  TextColumn get lastResult =>
      text().named('last_result').withDefault(const Constant('newItem'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(type IN (\'word\', \'sentence\', \'grammar\','
        ' \'expression\', \'questionMistake\'))',
    'CHECK(last_result IN (\'newItem\', \'forgotten\', \'vague\','
        ' \'remembered\', \'mastered\', \'missed\'))',
    'FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE SET NULL',
  ];
}

// ---------------------------------------------------------------------------
// Table 10: learning_analytics
// ---------------------------------------------------------------------------

@DataClassName('LearningAnalyticsEntry')
class LearningAnalytics extends Table {
  TextColumn get key => text()();

  TextColumn get language => text().withDefault(const Constant(kDefaultLang))();

  IntColumn get value => integer().withDefault(const Constant(kZeroInt))();

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
      text().named('origin_form').withDefault(const Constant(kEmptyStr))();

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

  TextColumn get title => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get description => text().nullable()();

  TextColumn get imageUrl => text().named('image_url').nullable()();

  TextColumn get lastFetchedAt => text().named('last_fetched_at').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

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
      text().named('feed_title').withDefault(const Constant(kEmptyStr))();

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
      text().named('created_at').clientDefault(nowIso)();

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

  TextColumn get explanation => text().withDefault(const Constant(kEmptyStr))();

  TextColumn get sourceContext => text().named('source_context').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

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

  TextColumn get value => text().withDefault(const Constant(kEmptyStr))();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Table 16: source_records
// ---------------------------------------------------------------------------

@DataClassName('SourceRecordEntry')
@TableIndex(name: 'idx_source_records_kind', columns: {#sourceKind})
@TableIndex(name: 'idx_source_records_availability', columns: {#availability})
class SourceRecords extends Table {
  TextColumn get id => text()();

  TextColumn get sourceKind => text().named('source_kind')();

  TextColumn get titleSnapshot => text().named('title_snapshot')();

  TextColumn get authorSnapshot => text().named('author_snapshot').nullable()();

  TextColumn get language =>
      text().named('language_id').withDefault(const Constant(kDefaultLang))();

  TextColumn get fingerprint => text().nullable()();

  TextColumn get availability =>
      text().withDefault(const Constant('available'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  TextColumn get deletedAt => text().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(source_kind IN (\'book\', \'rss\', \'browser\', \'manual\','
        ' \'ai\'))',
    'CHECK(availability IN (\'available\', \'archived\', \'deleted\'))',
  ];
}

// ---------------------------------------------------------------------------
// Table 17: knowledge_entities
// ---------------------------------------------------------------------------

@DataClassName('KnowledgeEntityEntry')
@TableIndex(
  name: 'idx_knowledge_entity_key',
  columns: {#language, #type, #canonicalKey},
  unique: true,
)
@TableIndex(name: 'idx_knowledge_entity_type', columns: {#type})
class KnowledgeEntities extends Table {
  TextColumn get id => text()();

  TextColumn get language =>
      text().named('language_id').withDefault(const Constant(kDefaultLang))();

  TextColumn get type => text()();

  TextColumn get canonicalKey => text().named('canonical_key')();

  TextColumn get displayText => text().named('display_text')();

  TextColumn get normalizedText => text().named('normalized_text')();

  TextColumn get masteryState =>
      text().named('mastery_state').withDefault(const Constant('unknown'))();

  RealColumn get confidence => real().withDefault(const Constant(kZeroReal))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  TextColumn get lastAccessedAt =>
      text().named('last_accessed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(type IN (\'word\', \'phrase\', \'pattern\', \'grammar\','
        ' \'concept\', \'character\', \'book_term\', \'sentence\'))',
    'CHECK(mastery_state IN (\'unknown\', \'learning\', \'mastered\'))',
  ];
}

// ---------------------------------------------------------------------------
// Table 18: knowledge_explanations
// ---------------------------------------------------------------------------

@DataClassName('KnowledgeExplanationEntry')
@TableIndex(
  name: 'idx_knowledge_explanations_entity',
  columns: {#entityId},
)
class KnowledgeExplanations extends Table {
  TextColumn get id => text()();

  TextColumn get entityId => text().named('entity_id')();

  TextColumn get explanation => text()();

  TextColumn get explanationSource => text().named('explanation_source')();

  TextColumn get targetLanguage =>
      text().named('target_language').withDefault(const Constant('zh'))();

  TextColumn get promptVersion => text().named('prompt_version').nullable()();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(explanation_source IN (\'ai\', \'user\', \'dictionary\','
        ' \'generated\'))',
    'FOREIGN KEY (entity_id) REFERENCES knowledge_entities(id) '
        'ON DELETE CASCADE',
  ];
}

// ---------------------------------------------------------------------------
// Table 19: knowledge_evidences
// ---------------------------------------------------------------------------

@DataClassName('KnowledgeEvidenceEntry')
@TableIndex(name: 'idx_knowledge_evidences_entity', columns: {#entityId})
@TableIndex(name: 'idx_knowledge_evidences_source', columns: {#sourceId})
class KnowledgeEvidences extends Table {
  TextColumn get id => text()();

  TextColumn get entityId => text().named('entity_id')();

  TextColumn get sourceId => text().named('source_id').nullable()();

  TextColumn get sourceKind => text().named('source_kind')();

  TextColumn get bookId => text().named('book_id').nullable()();

  IntColumn get chapterIndex => integer().named('chapter_index').nullable()();

  TextColumn get locationLocator =>
      text().named('location_locator').nullable()();

  TextColumn get shortExcerpt =>
      text().named('short_excerpt').withDefault(const Constant(kEmptyStr))();

  TextColumn get excerptHash => text().named('excerpt_hash').nullable()();

  TextColumn get sourceTitleSnapshot => text()
      .named('source_title_snapshot')
      .withDefault(
        const Constant(kEmptyStr),
      )();

  TextColumn get sourceAvailability => text()
      .named('source_availability')
      .withDefault(const Constant('available'))();

  TextColumn get retentionPolicy => text()
      .named('retention_policy')
      .withDefault(const Constant('keepSnippet'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(source_kind IN (\'book\', \'rss\', \'browser\', \'manual\','
        ' \'ai\'))',
    'CHECK(source_availability IN (\'available\', \'archived\','
        ' \'deleted\'))',
    'CHECK(retention_policy IN (\'deleteWithSource\', \'keepSnippet\','
        ' \'keepMetadataOnly\'))',
    'FOREIGN KEY (entity_id) REFERENCES knowledge_entities(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (source_id) REFERENCES source_records(id) '
        'ON DELETE SET NULL',
  ];
}

// ---------------------------------------------------------------------------
// Table 20: memory_events
// ---------------------------------------------------------------------------

@DataClassName('MemoryEventEntry')
@TableIndex(
  name: 'idx_memory_events_canonical',
  columns: {#language, #canonicalKey},
)
@TableIndex(name: 'idx_memory_events_source', columns: {#sourceId})
@TableIndex(name: 'idx_memory_events_created', columns: {#createdAt})
class MemoryEvents extends Table {
  TextColumn get id => text()();

  TextColumn get eventType => text().named('event_type')();

  TextColumn get language =>
      text().named('language_id').withDefault(const Constant(kDefaultLang))();

  TextColumn get sourceId => text().named('source_id').nullable()();

  TextColumn get entityId => text().named('entity_id').nullable()();

  TextColumn get targetText =>
      text().named('target_text').withDefault(const Constant(kEmptyStr))();

  TextColumn get canonicalKey =>
      text().named('canonical_key').withDefault(const Constant(kEmptyStr))();

  TextColumn get sourceRefJson =>
      text().named('source_ref_json').withDefault(const Constant('{}'))();

  TextColumn get metadataJson =>
      text().named('metadata_json').withDefault(const Constant('{}'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(event_type IN (\'lookup\', \'ai_analyze\','
        ' \'save_explanation\', \'mark_learning\', \'mark_known\','
        ' \'mark_unknown\', \'review\', \'bookmark\'))',
    'FOREIGN KEY (source_id) REFERENCES source_records(id) '
        'ON DELETE SET NULL',
    'FOREIGN KEY (entity_id) REFERENCES knowledge_entities(id) '
        'ON DELETE SET NULL',
  ];
}

// ---------------------------------------------------------------------------
// Table 21: source_scope_cache
// ---------------------------------------------------------------------------

@DataClassName('SourceScopeCacheEntry')
@TableIndex(name: 'idx_source_scope_cache_source', columns: {#sourceId})
class SourceScopeCache extends Table {
  TextColumn get id => text()();

  TextColumn get sourceId => text().named('source_id')();

  TextColumn get cacheType => text().named('cache_type')();

  TextColumn get payload => text()();

  TextColumn get retentionPolicy => text()
      .named('retention_policy')
      .withDefault(const Constant('deleteWithSource'))();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(retention_policy IN (\'deleteWithSource\', \'keepSnippet\','
        ' \'keepMetadataOnly\'))',
    'FOREIGN KEY (source_id) REFERENCES source_records(id) '
        'ON DELETE CASCADE',
  ];
}

// ---------------------------------------------------------------------------
// Table 22: review_candidates
// ---------------------------------------------------------------------------

@DataClassName('ReviewCandidateEntry')
@TableIndex(name: 'idx_review_candidates_entity', columns: {#entityId})
@TableIndex(name: 'idx_review_candidates_status', columns: {#status})
class ReviewCandidates extends Table {
  TextColumn get id => text()();

  TextColumn get entityId => text().named('entity_id')();

  TextColumn get entityType => text().named('entity_type')();

  TextColumn get targetText => text().named('target_text')();

  TextColumn get explanationId => text().named('explanation_id').nullable()();

  TextColumn get evidenceId => text().named('evidence_id').nullable()();

  TextColumn get suggestedQuestionType =>
      text().named('suggested_question_type').nullable()();

  RealColumn get priority => real().withDefault(const Constant(kZeroReal))();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get createdAt =>
      text().named('created_at').clientDefault(nowIso)();

  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(nowIso)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(entity_type IN (\'word\', \'phrase\', \'pattern\','
        ' \'grammar\', \'concept\', \'character\', \'book_term\','
        ' \'sentence\'))',
    'CHECK(status IN (\'pending\', \'accepted\', \'dismissed\','
        ' \'converted\'))',
    'FOREIGN KEY (entity_id) REFERENCES knowledge_entities(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (explanation_id) REFERENCES knowledge_explanations(id) '
        'ON DELETE SET NULL',
    'FOREIGN KEY (evidence_id) REFERENCES knowledge_evidences(id) '
        'ON DELETE SET NULL',
  ];
}

// ---------------------------------------------------------------------------
// Table 23: settings
// ---------------------------------------------------------------------------

@DataClassName('SettingsEntry')
class Settings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().withDefault(const Constant(kEmptyStr))();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Table 24: ai_usage_events
// ---------------------------------------------------------------------------

@DataClassName('AIUsageEvent')
@TableIndex(name: 'idx_ai_usage_book_time', columns: {#bookId, #createdAt})
@TableIndex(name: 'idx_ai_usage_operation', columns: {#operation})
@TableIndex(
  name: 'idx_ai_usage_model_time',
  columns: {#providerId, #model, #createdAt},
)
@TableIndex(name: 'idx_ai_usage_source', columns: {#sourceType, #sourceId})
class AiUsageEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceType => text().named('source_type')();

  TextColumn get sourceId => text().named('source_id').nullable()();

  TextColumn get bookId => text().named('book_id').nullable()();

  IntColumn get chapterIndex => integer().named('chapter_index').nullable()();

  TextColumn get providerId => text().named('provider_id')();

  TextColumn get model => text()();

  TextColumn get operation => text()();

  IntColumn get promptTokens => integer().named('prompt_tokens').nullable()();

  IntColumn get completionTokens =>
      integer().named('completion_tokens').nullable()();

  IntColumn get totalTokens => integer().named('total_tokens').nullable()();

  IntColumn get durationMs => integer().named('duration_ms').nullable()();

  BoolColumn get billable => boolean().withDefault(const Constant(true))();

  IntColumn get promptVersion => integer().named('prompt_version').nullable()();

  TextColumn get requestId => text().named('request_id').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  String get tableName => 'ai_usage_events';
}
