import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_metadata.dart';
import '../models/book_glossary_entry.dart' as hive_models;
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_bookmark.dart';
import '../models/reading_config.dart';
import '../models/user_vocabulary.dart';
import 'package:flow_rss/flow_rss.dart';
import '../models/word_level.dart';
import '../services/app_logger.dart';
import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'database/app_database.dart';
import 'database/migration.dart';
import 'database/repositories/drift_book_repository.dart';
import 'database/repositories/drift_bookmark_repository.dart';
import 'database/repositories/drift_learning_item_repository.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'storage_migrations.dart';

AppDatabase? _appDatabase;
String _bootstrappedReadingConfigLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, String> _bootstrappedReadingConfigValues = const {};
String _bootstrappedBookMetadataLanguage = HiveBoxNames.defaultLanguageCode;
List<BookMetadata> _bootstrappedBookMetadataValues = const [];
String _bootstrappedReadingTimeLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, int> _bootstrappedReadingTimeValues = const {};
String _bootstrappedWordContextLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, String> _bootstrappedWordContextValues = const {};
String _bootstrappedBookmarkLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, String> _bootstrappedWordBookmarkValues = const {};
Map<String, String> _bootstrappedReadingBookmarkValues = const {};
String _bootstrappedDictionaryCacheLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, String> _bootstrappedDictionaryCacheValues = const {};
String _bootstrappedUserVocabularyLanguage = HiveBoxNames.defaultLanguageCode;
Map<String, UserWordStatus> _bootstrappedUserVocabularyValues = const {};
String _bootstrappedLearningItemLanguage = HiveBoxNames.defaultLanguageCode;
List<LearningItem> _bootstrappedLearningItemValues = const [];
String _bootstrappedLearningAnalyticsLanguage =
    HiveBoxNames.defaultLanguageCode;
Map<String, int> _bootstrappedLearningAnalyticsValues = const {};

AppDatabase? get appDatabase => _appDatabase;
String get bootstrappedReadingConfigLanguage =>
    _bootstrappedReadingConfigLanguage;
Map<String, String> get bootstrappedReadingConfigValues =>
    Map.unmodifiable(_bootstrappedReadingConfigValues);
String get bootstrappedBookMetadataLanguage =>
    _bootstrappedBookMetadataLanguage;
List<BookMetadata> get bootstrappedBookMetadataValues =>
    List.unmodifiable(_bootstrappedBookMetadataValues);
String get bootstrappedReadingTimeLanguage => _bootstrappedReadingTimeLanguage;
Map<String, int> get bootstrappedReadingTimeValues =>
    Map.unmodifiable(_bootstrappedReadingTimeValues);
String get bootstrappedWordContextLanguage => _bootstrappedWordContextLanguage;
Map<String, String> get bootstrappedWordContextValues =>
    Map.unmodifiable(_bootstrappedWordContextValues);
String get bootstrappedBookmarkLanguage => _bootstrappedBookmarkLanguage;
Map<String, String> get bootstrappedWordBookmarkValues =>
    Map.unmodifiable(_bootstrappedWordBookmarkValues);
Map<String, String> get bootstrappedReadingBookmarkValues =>
    Map.unmodifiable(_bootstrappedReadingBookmarkValues);
String get bootstrappedDictionaryCacheLanguage =>
    _bootstrappedDictionaryCacheLanguage;
Map<String, String> get bootstrappedDictionaryCacheValues =>
    Map.unmodifiable(_bootstrappedDictionaryCacheValues);
String get bootstrappedUserVocabularyLanguage =>
    _bootstrappedUserVocabularyLanguage;
Map<String, UserWordStatus> get bootstrappedUserVocabularyValues =>
    Map.unmodifiable(_bootstrappedUserVocabularyValues);
String get bootstrappedLearningItemLanguage =>
    _bootstrappedLearningItemLanguage;
List<LearningItem> get bootstrappedLearningItemValues =>
    List.unmodifiable(_bootstrappedLearningItemValues);
String get bootstrappedLearningAnalyticsLanguage =>
    _bootstrappedLearningAnalyticsLanguage;
Map<String, int> get bootstrappedLearningAnalyticsValues =>
    Map.unmodifiable(_bootstrappedLearningAnalyticsValues);

Future<void> bootstrapStorage() async {
  await Hive.initFlutter();
  registerFlowReadHiveAdapters();
  registerFlowReadLanguageModules();
  await openFlowReadHiveBoxes();
  await runStorageMigrations();
  await _bootstrapDatabase();
}

Future<void> _bootstrapDatabase() async {
  AppDatabase? db;
  var activeLang = HiveBoxNames.defaultLanguageCode;
  try {
    db = await AppDatabase.create();
    _appDatabase = db;

    activeLang = _activeSourceLanguageCode();
    final migration = HiveToDriftMigration(db);
    try {
      final result = await migration.migrateAll(activeLang);
      AppLogger.instance.event(
        'database.migration_succeeded',
        source: 'storage',
        metadata: {
          'skipped': result.skipped,
          'language': result.languageCode,
          'scannedRows': result.totalScannedRows,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'database.migration_failed',
        level: AppLogLevel.warning,
        source: 'storage',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _cacheBootstrappedBookMetadata(db, activeLang);
    await _cacheBootstrappedReadingConfig(db, activeLang);
    await _cacheBootstrappedReadingTime(db, activeLang);
    await _cacheBootstrappedWordContexts(db, activeLang);
    await _cacheBootstrappedBookmarks(db, activeLang);
    await _cacheBootstrappedDictionaryCache(db, activeLang);
    await _cacheBootstrappedUserVocabulary(db, activeLang);
    await _cacheBootstrappedLearningItems(db, activeLang);
    await _cacheBootstrappedLearningAnalytics(db, activeLang);
  } catch (error, stackTrace) {
    AppLogger.instance.event(
      'database.bootstrap_failed',
      level: AppLogLevel.warning,
      source: 'storage',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _cacheBootstrappedBookMetadata(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedBookMetadataLanguage = languageCode;
  final entries = await db.bookDao.allBooks(languageCode);
  _bootstrappedBookMetadataValues = entries
      .map(DriftBookRepository.metadataFromEntry)
      .toList(growable: false);
}

Future<void> _cacheBootstrappedReadingConfig(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedReadingConfigLanguage = languageCode;
  _bootstrappedReadingConfigValues = await db.readingConfigDao.allValues(
    languageCode,
  );
}

Future<void> _cacheBootstrappedReadingTime(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedReadingTimeLanguage = languageCode;
  _bootstrappedReadingTimeValues = await db.readingTimeDao.allValues(
    languageCode,
  );
}

Future<void> _cacheBootstrappedWordContexts(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedWordContextLanguage = languageCode;
  _bootstrappedWordContextValues = await db.wordContextDao.allValues(
    languageCode,
  );
}

Future<void> _cacheBootstrappedBookmarks(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedBookmarkLanguage = languageCode;
  final wordRows = await db.bookmarkDao.allWordBookmarksForLanguage(
    languageCode,
  );
  final readingRows = await db.bookmarkDao.allReadingBookmarksForLanguage(
    languageCode,
  );
  _bootstrappedWordBookmarkValues =
      DriftBookmarkRepository.encodedWordBookmarksByBook(wordRows);
  _bootstrappedReadingBookmarkValues =
      DriftBookmarkRepository.encodedReadingBookmarksByBook(readingRows);
}

Future<void> _cacheBootstrappedDictionaryCache(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedDictionaryCacheLanguage = languageCode;
  _bootstrappedDictionaryCacheValues = await db.dictionaryCacheDao.allValues(
    languageCode,
  );
}

Future<void> _cacheBootstrappedUserVocabulary(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedUserVocabularyLanguage = languageCode;
  final values = await db.userVocabularyDao.allWords(languageCode);
  _bootstrappedUserVocabularyValues = values.map(
    (word, status) => MapEntry(
      word,
      status == UserWordStatus.learning.name
          ? UserWordStatus.learning
          : UserWordStatus.known,
    ),
  );
}

Future<void> _cacheBootstrappedLearningItems(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedLearningItemLanguage = languageCode;
  final entries = await db.learningItemDao.allForLanguage(languageCode);
  _bootstrappedLearningItemValues = entries
      .map(DriftLearningItemRepository.itemFromEntry)
      .toList(growable: false);
}

Future<void> _cacheBootstrappedLearningAnalytics(
  AppDatabase db,
  String languageCode,
) async {
  _bootstrappedLearningAnalyticsLanguage = languageCode;
  _bootstrappedLearningAnalyticsValues = await db.learningAnalyticsDao
      .allValues(languageCode);
}

void registerFlowReadHiveAdapters() {
  _registerHiveAdapter(HiveTypeIds.bookMetadata, BookMetadataAdapter());
  _registerHiveAdapter(HiveTypeIds.bookmarkedWord, BookmarkedWordAdapter());
  _registerHiveAdapter(HiveTypeIds.readingBookmark, ReadingBookmarkAdapter());
  _registerHiveAdapter(HiveTypeIds.readingConfig, ReadingConfigAdapter());
  _registerHiveAdapter(HiveTypeIds.wordLevelInfo, WordLevelInfoAdapter());
  _registerHiveAdapter(
    HiveTypeIds.rssFeedSubscription,
    RssFeedSubscriptionAdapter(),
  );
  _registerHiveAdapter(HiveTypeIds.learningItem, LearningItemAdapter());
  _registerHiveAdapter(
    HiveTypeIds.bookGlossaryEntry,
    hive_models.BookGlossaryEntryAdapter(),
  );
}

void registerFlowReadLanguageModules() {
  final registry = LanguageRegistry.instance;
  if (registry.get('en') == null) {
    registry.register(const EnglishLanguageModule());
  }
}

Future<void> openFlowReadHiveBoxes() async {
  registerFlowReadLanguageModules();
  await Hive.openBox(HiveBoxNames.settings);
  final activeLang = _activeSourceLanguageCode();
  final module = LanguageRegistry.instance.get(activeLang);
  final languageCode = module == null
      ? HiveBoxNames.defaultLanguageCode
      : activeLang;

  await Future.wait([
    Hive.openBox<BookMetadata>(HiveBoxNames.booksFor(languageCode)),
    Hive.openBox<String>(HiveBoxNames.userVocabularyFor(languageCode)),
    Hive.openBox<String>(HiveBoxNames.wordBookmarksFor(languageCode)),
    Hive.openBox<String>(HiveBoxNames.readingBookmarksFor(languageCode)),
    Hive.openBox<String>(HiveBoxNames.readingConfigFor(languageCode)),
    Hive.openBox<int>(HiveBoxNames.readingTimeFor(languageCode)),
    Hive.openBox<WordLevelInfo>(HiveBoxNames.wordLevels),
    Hive.openBox<String>(HiveBoxNames.dictionaryCacheFor(languageCode)),
    Hive.openBox<RssFeedSubscription>(HiveBoxNames.rssSubscriptions),
    Hive.openBox<hive_models.BookGlossaryEntry>(HiveBoxNames.bookGlossary),
    Hive.openBox<String>(HiveBoxNames.characterRegistry),
    Hive.openBox<String>(HiveBoxNames.wordContextsFor(languageCode)),
    Hive.openBox<LearningItem>(HiveBoxNames.learningItemsFor(languageCode)),
    Hive.openBox<int>(HiveBoxNames.learningAnalyticsFor(languageCode)),
  ]);
}

void _registerHiveAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}

String _activeSourceLanguageCode() {
  final raw = Hive.box(HiveBoxNames.settings).get(
    HiveBoxNames.activeSourceLanguageKey,
    defaultValue: HiveBoxNames.defaultLanguageCode,
  );
  final code = raw?.toString().trim().toLowerCase();
  return code == null || code.isEmpty ? HiveBoxNames.defaultLanguageCode : code;
}
