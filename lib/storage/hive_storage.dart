import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_metadata.dart';
import '../models/book_glossary_entry.dart' as hive_models;
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_bookmark.dart';
import '../models/reading_config.dart';
import '../models/user_vocabulary.dart';
import '../models/word_level.dart';
import 'database/app_database.dart';
import 'database/bootstrap.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'storage_migrations.dart';

AppDatabase? _appDatabase;
DatabaseBootstrapSnapshot _bootstrappedSnapshot =
    const DatabaseBootstrapSnapshot.empty();

AppDatabase? get appDatabase => _appDatabase;
String get bootstrappedReadingConfigLanguage =>
    _bootstrappedSnapshot.readingConfigLanguage;
Map<String, String> get bootstrappedReadingConfigValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingConfigValues);
String get bootstrappedBookMetadataLanguage =>
    _bootstrappedSnapshot.bookMetadataLanguage;
List<BookMetadata> get bootstrappedBookMetadataValues =>
    List.unmodifiable(_bootstrappedSnapshot.bookMetadataValues);
String get bootstrappedReadingTimeLanguage =>
    _bootstrappedSnapshot.readingTimeLanguage;
Map<String, int> get bootstrappedReadingTimeValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingTimeValues);
String get bootstrappedWordContextLanguage =>
    _bootstrappedSnapshot.wordContextLanguage;
Map<String, String> get bootstrappedWordContextValues =>
    Map.unmodifiable(_bootstrappedSnapshot.wordContextValues);
String get bootstrappedBookmarkLanguage =>
    _bootstrappedSnapshot.bookmarkLanguage;
Map<String, String> get bootstrappedWordBookmarkValues =>
    Map.unmodifiable(_bootstrappedSnapshot.wordBookmarkValues);
Map<String, String> get bootstrappedReadingBookmarkValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingBookmarkValues);
String get bootstrappedDictionaryCacheLanguage =>
    _bootstrappedSnapshot.dictionaryCacheLanguage;
Map<String, String> get bootstrappedDictionaryCacheValues =>
    Map.unmodifiable(_bootstrappedSnapshot.dictionaryCacheValues);
Map<String, String> get bootstrappedCharacterRegistryValues =>
    Map.unmodifiable(_bootstrappedSnapshot.characterRegistryValues);
String get bootstrappedUserVocabularyLanguage =>
    _bootstrappedSnapshot.userVocabularyLanguage;
Map<String, UserWordStatus> get bootstrappedUserVocabularyValues =>
    Map.unmodifiable(_bootstrappedSnapshot.userVocabularyValues);
String get bootstrappedLearningItemLanguage =>
    _bootstrappedSnapshot.learningItemLanguage;
List<LearningItem> get bootstrappedLearningItemValues =>
    List.unmodifiable(_bootstrappedSnapshot.learningItemValues);
String get bootstrappedLearningAnalyticsLanguage =>
    _bootstrappedSnapshot.learningAnalyticsLanguage;
Map<String, int> get bootstrappedLearningAnalyticsValues =>
    Map.unmodifiable(_bootstrappedSnapshot.learningAnalyticsValues);

Future<void> bootstrapStorage() async {
  await Hive.initFlutter();
  registerFlowReadHiveAdapters();
  registerFlowReadLanguageModules();
  await openFlowReadHiveBoxes();
  await runStorageMigrations();
  await _bootstrapDatabase();
}

Future<void> _bootstrapDatabase() async {
  final activeLang = _activeSourceLanguageCode();
  final result = await bootstrapDatabaseStorage(activeLang);
  if (result == null) return;
  _appDatabase = result.database;
  _bootstrappedSnapshot = result.snapshot;
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
