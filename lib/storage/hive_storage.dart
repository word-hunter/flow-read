import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_metadata.dart';
import '../models/book_glossary_entry.dart';
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_bookmark.dart';
import '../models/reading_config.dart';
import '../models/rss_models.dart';
import '../models/word_level.dart';
import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'storage_migrations.dart';

Future<void> bootstrapStorage() async {
  await Hive.initFlutter();
  registerFlowReadHiveAdapters();
  registerFlowReadLanguageModules();
  await openFlowReadHiveBoxes();
  await runStorageMigrations();
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
    BookGlossaryEntryAdapter(),
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
    Hive.openBox<BookGlossaryEntry>(HiveBoxNames.bookGlossary),
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
