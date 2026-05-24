import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_metadata.dart';
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_bookmark.dart';
import '../models/reading_config.dart';
import '../models/rss_models.dart';
import '../models/word_level.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'storage_migrations.dart';

Future<void> bootstrapStorage() async {
  await Hive.initFlutter();
  registerFlowReadHiveAdapters();
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
}

Future<void> openFlowReadHiveBoxes() async {
  await Future.wait([
    Hive.openBox<BookMetadata>(HiveBoxNames.books),
    Hive.openBox<String>(HiveBoxNames.userVocabulary),
    Hive.openBox(HiveBoxNames.settings),
    Hive.openBox<String>(HiveBoxNames.wordBookmarks),
    Hive.openBox<String>(HiveBoxNames.readingBookmarks),
    Hive.openBox<String>(HiveBoxNames.readingConfig),
    Hive.openBox<int>(HiveBoxNames.readingTime),
    Hive.openBox<WordLevelInfo>(HiveBoxNames.wordLevels),
    Hive.openBox<String>(HiveBoxNames.dictionaryCache),
    Hive.openBox<RssFeedSubscription>(HiveBoxNames.rssSubscriptions),
    Hive.openBox<String>(HiveBoxNames.wordContexts),
    Hive.openBox<LearningItem>(HiveBoxNames.learningItems),
    Hive.openBox<int>(HiveBoxNames.learningAnalytics),
  ]);
}

void _registerHiveAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}
