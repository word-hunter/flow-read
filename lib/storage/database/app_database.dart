import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'dao/book_dao.dart';
import 'dao/book_glossary_dao.dart';
import 'dao/bookmark_dao.dart';
import 'dao/character_registry_dao.dart';
import 'dao/dictionary_cache_dao.dart';
import 'dao/learning_analytics_dao.dart';
import 'dao/learning_item_dao.dart';
import 'dao/reading_config_dao.dart';
import 'dao/reading_time_dao.dart';
import 'dao/rss_dao.dart';
import 'dao/settings_dao.dart';
import 'dao/user_vocabulary_dao.dart';
import 'dao/word_context_dao.dart';
import 'dao/word_level_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

const _dbFileName = 'flow_read.db';

const _schemaVersion = 1;

@DriftDatabase(
  tables: [
    BookEntries,
    UserVocabularies,
    WordBookmarks,
    ReadingBookmarks,
    ReadingConfig,
    ReadingTime,
    DictionaryCache,
    WordContexts,
    LearningItems,
    LearningAnalytics,
    WordLevels,
    RssSubscriptions,
    RssArticles,
    BookGlossary,
    CharacterRegistry,
    Settings,
  ],
  daos: [
    BookDao,
    BookGlossaryDao,
    BookmarkDao,
    CharacterRegistryDao,
    DictionaryCacheDao,
    LearningAnalyticsDao,
    LearningItemDao,
    ReadingConfigDao,
    ReadingTimeDao,
    RssDao,
    SettingsDao,
    UserVocabularyDao,
    WordContextDao,
    WordLevelDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.e);

  static Future<AppDatabase> create() async {
    final dbPath = await _databasePath();
    final db = AppDatabase._(
      NativeDatabase.createInBackground(
        File(dbPath),
      ),
    );
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.customStatement('PRAGMA journal_mode = WAL');
    return db;
  }

  static Future<AppDatabase> createInMemory() async {
    return AppDatabase._(
      NativeDatabase.memory(),
    );
  }

  static Future<String> _databasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_dbFileName';
  }

  @override
  int get schemaVersion => _schemaVersion;
}
