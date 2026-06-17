import '../../models/book_metadata.dart';
import '../../models/learning_item.dart';
import '../../models/user_vocabulary.dart';
import '../../services/app_logger.dart';
import 'app_database.dart';
import 'repositories/drift_book_repository.dart';
import 'repositories/drift_bookmark_repository.dart';
import 'repositories/drift_learning_item_repository.dart';
import '../legacy_backup_box_names.dart';

typedef AppDatabaseFactory = Future<AppDatabase> Function();

final class DatabaseBootstrapResult {
  const DatabaseBootstrapResult({
    required this.database,
    required this.snapshot,
  });

  final AppDatabase database;
  final DatabaseBootstrapSnapshot snapshot;
}

final class DatabaseBootstrapSnapshot {
  const DatabaseBootstrapSnapshot({
    required this.settingsValues,
    required this.bookMetadataLanguage,
    required this.bookMetadataValues,
    required this.readingConfigLanguage,
    required this.readingConfigValues,
    required this.readingTimeLanguage,
    required this.readingTimeValues,
    required this.wordContextLanguage,
    required this.wordContextValues,
    required this.bookmarkLanguage,
    required this.wordBookmarkValues,
    required this.readingBookmarkValues,
    required this.dictionaryCacheLanguage,
    required this.dictionaryCacheValues,
    required this.characterRegistryValues,
    required this.userVocabularyLanguage,
    required this.userVocabularyValues,
    required this.learningItemLanguage,
    required this.learningItemValues,
    required this.learningAnalyticsLanguage,
    required this.learningAnalyticsValues,
  });

  const DatabaseBootstrapSnapshot.empty({
    String languageCode = LegacyBackupBoxNames.defaultLanguageCode,
  }) : settingsValues = const {},
       bookMetadataLanguage = languageCode,
       bookMetadataValues = const [],
       readingConfigLanguage = languageCode,
       readingConfigValues = const {},
       readingTimeLanguage = languageCode,
       readingTimeValues = const {},
       wordContextLanguage = languageCode,
       wordContextValues = const {},
       bookmarkLanguage = languageCode,
       wordBookmarkValues = const {},
       readingBookmarkValues = const {},
       dictionaryCacheLanguage = languageCode,
       dictionaryCacheValues = const {},
       characterRegistryValues = const {},
       userVocabularyLanguage = languageCode,
       userVocabularyValues = const {},
       learningItemLanguage = languageCode,
       learningItemValues = const [],
       learningAnalyticsLanguage = languageCode,
       learningAnalyticsValues = const {};

  final Map<String, String> settingsValues;
  final String bookMetadataLanguage;
  final List<BookMetadata> bookMetadataValues;
  final String readingConfigLanguage;
  final Map<String, String> readingConfigValues;
  final String readingTimeLanguage;
  final Map<String, int> readingTimeValues;
  final String wordContextLanguage;
  final Map<String, String> wordContextValues;
  final String bookmarkLanguage;
  final Map<String, String> wordBookmarkValues;
  final Map<String, String> readingBookmarkValues;
  final String dictionaryCacheLanguage;
  final Map<String, String> dictionaryCacheValues;
  final Map<String, String> characterRegistryValues;
  final String userVocabularyLanguage;
  final Map<String, UserWordStatus> userVocabularyValues;
  final String learningItemLanguage;
  final List<LearningItem> learningItemValues;
  final String learningAnalyticsLanguage;
  final Map<String, int> learningAnalyticsValues;

  static Future<DatabaseBootstrapSnapshot> load(
    AppDatabase db,
    String languageCode,
  ) async {
    final results = await Future.wait<Object>([
      db.settingsDao.allEntries(),
      _loadBookMetadata(db, languageCode),
      db.readingConfigDao.allValues(languageCode),
      db.readingTimeDao.allValues(languageCode),
      db.wordContextDao.allValues(languageCode),
      _loadBookmarks(db, languageCode),
      db.dictionaryCacheDao.allValues(languageCode),
      db.characterRegistryDao.allEntries(),
      _loadUserVocabulary(db, languageCode),
      _loadLearningItems(db, languageCode),
      db.learningAnalyticsDao.allValues(languageCode),
    ]);

    final bookmarks = results[5] as _BookmarkSnapshot;
    return DatabaseBootstrapSnapshot(
      settingsValues: results[0] as Map<String, String>,
      bookMetadataLanguage: languageCode,
      bookMetadataValues: results[1] as List<BookMetadata>,
      readingConfigLanguage: languageCode,
      readingConfigValues: results[2] as Map<String, String>,
      readingTimeLanguage: languageCode,
      readingTimeValues: results[3] as Map<String, int>,
      wordContextLanguage: languageCode,
      wordContextValues: results[4] as Map<String, String>,
      bookmarkLanguage: languageCode,
      wordBookmarkValues: bookmarks.wordBookmarks,
      readingBookmarkValues: bookmarks.readingBookmarks,
      dictionaryCacheLanguage: languageCode,
      dictionaryCacheValues: results[6] as Map<String, String>,
      characterRegistryValues: results[7] as Map<String, String>,
      userVocabularyLanguage: languageCode,
      userVocabularyValues: results[8] as Map<String, UserWordStatus>,
      learningItemLanguage: languageCode,
      learningItemValues: results[9] as List<LearningItem>,
      learningAnalyticsLanguage: languageCode,
      learningAnalyticsValues: results[10] as Map<String, int>,
    );
  }

  static Future<List<BookMetadata>> _loadBookMetadata(
    AppDatabase db,
    String languageCode,
  ) async {
    final entries = await db.bookDao.allBooks(languageCode);
    return entries
        .map(DriftBookRepository.metadataFromEntry)
        .toList(growable: false);
  }

  static Future<_BookmarkSnapshot> _loadBookmarks(
    AppDatabase db,
    String languageCode,
  ) async {
    final wordRowsFuture = db.bookmarkDao.allWordBookmarksForLanguage(
      languageCode,
    );
    final readingRowsFuture = db.bookmarkDao.allReadingBookmarksForLanguage(
      languageCode,
    );
    final wordRows = await wordRowsFuture;
    final readingRows = await readingRowsFuture;
    return _BookmarkSnapshot(
      wordBookmarks: DriftBookmarkRepository.encodedWordBookmarksByBook(
        wordRows,
      ),
      readingBookmarks: DriftBookmarkRepository.encodedReadingBookmarksByBook(
        readingRows,
      ),
    );
  }

  static Future<Map<String, UserWordStatus>> _loadUserVocabulary(
    AppDatabase db,
    String languageCode,
  ) async {
    final values = await db.userVocabularyDao.allWords(languageCode);
    return values.map(
      (word, status) => MapEntry(
        word,
        status == UserWordStatus.learning.name
            ? UserWordStatus.learning
            : UserWordStatus.known,
      ),
    );
  }

  static Future<List<LearningItem>> _loadLearningItems(
    AppDatabase db,
    String languageCode,
  ) async {
    final entries = await db.learningItemDao.allForLanguage(languageCode);
    return entries
        .map(DriftLearningItemRepository.itemFromEntry)
        .toList(growable: false);
  }
}

Future<DatabaseBootstrapResult?> bootstrapDatabaseStorage({
  AppDatabaseFactory databaseFactory = AppDatabase.create,
}) async {
  final AppDatabase db;
  try {
    db = await databaseFactory();
  } catch (error, stackTrace) {
    AppLogger.instance.event(
      'database.bootstrap_failed',
      level: AppLogLevel.warning,
      source: 'storage',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }

  var activeLanguageCode = LegacyBackupBoxNames.defaultLanguageCode;
  try {
    activeLanguageCode = await _activeSourceLanguageCode(db);
    return DatabaseBootstrapResult(
      database: db,
      snapshot: await DatabaseBootstrapSnapshot.load(db, activeLanguageCode),
    );
  } catch (error, stackTrace) {
    AppLogger.instance.event(
      'database.bootstrap_failed',
      level: AppLogLevel.warning,
      source: 'storage',
      error: error,
      stackTrace: stackTrace,
    );
    return DatabaseBootstrapResult(
      database: db,
      snapshot: DatabaseBootstrapSnapshot.empty(
        languageCode: activeLanguageCode,
      ),
    );
  }
}

Future<String> _activeSourceLanguageCode(AppDatabase db) async {
  final raw = await db.settingsDao.valueFor(
    LegacyBackupBoxNames.activeSourceLanguageKey,
  );
  final code = raw.trim().toLowerCase();
  return code.isEmpty ? LegacyBackupBoxNames.defaultLanguageCode : code;
}

final class _BookmarkSnapshot {
  const _BookmarkSnapshot({
    required this.wordBookmarks,
    required this.readingBookmarks,
  });

  final Map<String, String> wordBookmarks;
  final Map<String, String> readingBookmarks;
}
