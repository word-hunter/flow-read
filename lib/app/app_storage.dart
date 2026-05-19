import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_metadata.dart';
import '../models/bookmarked_word.dart';
import '../models/learning_item.dart';
import '../models/reading_bookmark.dart';
import '../models/reading_config.dart';
import '../models/rss_models.dart';
import '../models/word_level.dart';

Future<void> bootstrapStorage() async {
  await Hive.initFlutter();

  _registerHiveAdapter(0, BookMetadataAdapter());
  _registerHiveAdapter(1, BookmarkedWordAdapter());
  _registerHiveAdapter(2, ReadingBookmarkAdapter());
  _registerHiveAdapter(3, ReadingConfigAdapter());
  _registerHiveAdapter(4, WordLevelInfoAdapter());
  _registerHiveAdapter(10, RssFeedSubscriptionAdapter());
  _registerHiveAdapter(11, LearningItemAdapter());

  await Future.wait([
    Hive.openBox<BookMetadata>('books'),
    Hive.openBox<String>('user_vocabulary'),
    Hive.openBox('settings'),
    Hive.openBox<String>('word_bookmarks'),
    Hive.openBox<String>('reading_bookmarks'),
    Hive.openBox<String>('reading_config'),
    Hive.openBox<int>('reading_time'),
    Hive.openBox<WordLevelInfo>('word_levels'),
    Hive.openBox<String>('dictionary_cache'),
    Hive.openBox<RssFeedSubscription>('rss_subscriptions'),
    Hive.openBox<String>('word_contexts'),
    Hive.openBox<LearningItem>('learning_items'),
  ]);
}

void _registerHiveAdapter<T>(int typeId, TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(typeId)) {
    Hive.registerAdapter(adapter);
  }
}
