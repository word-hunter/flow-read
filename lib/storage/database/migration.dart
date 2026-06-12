import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';

import '../../models/book_glossary_entry.dart' as hive_models;
import '../../models/book_metadata.dart';
import '../../models/learning_item.dart';
import 'package:flow_rss/flow_rss.dart';
import '../../models/user_vocabulary.dart';
import '../../models/word_level.dart';
import '../hive_box_names.dart';
import '../storage_migrations.dart';
import 'app_database.dart';

final class HiveToDriftMigration {
  final AppDatabase _db;

  HiveToDriftMigration(this._db);

  static const completedAtKey = 'legacy_hive_to_drift_completed_at';
  static const sourceSchemaVersionKey =
      'legacy_hive_to_drift_source_schema_version';
  static const sourceLanguageKey = 'legacy_hive_to_drift_source_language';

  Future<HiveToDriftMigrationResult> migrateAll(
    String languageCode, {
    bool force = false,
  }) async {
    final existingCompletedAt = await _completedAt();
    if (!force && existingCompletedAt != null) {
      return HiveToDriftMigrationResult.skipped(
        languageCode: languageCode,
        completedAt: existingCompletedAt,
      );
    }

    final scannedRows = <String, int>{};
    Future<void> migrate(
      String tableName,
      Future<int> Function() run,
    ) async {
      scannedRows[tableName] = await run();
    }

    await migrate('books', () => _migrateBooks(languageCode));
    await migrate(
      'user_vocabulary',
      () => _migrateUserVocabulary(languageCode),
    );
    await migrate('word_bookmarks', () => _migrateWordBookmarks(languageCode));
    await migrate(
      'reading_bookmarks',
      () => _migrateReadingBookmarks(languageCode),
    );
    await migrate('reading_config', () => _migrateReadingConfig(languageCode));
    await migrate('reading_time', () => _migrateReadingTime(languageCode));
    await migrate(
      'dictionary_cache',
      () => _migrateDictionaryCache(languageCode),
    );
    await migrate('word_contexts', () => _migrateWordContexts(languageCode));
    await migrate('learning_items', () => _migrateLearningItems(languageCode));
    await migrate(
      'learning_analytics',
      () => _migrateLearningAnalytics(languageCode),
    );
    await migrate('word_levels', _migrateWordLevels);
    await migrate('rss_subscriptions', _migrateRssSubscriptions);
    await migrate('rss_articles', _migrateRssArticles);
    await migrate('book_glossary', _migrateBookGlossary);
    await migrate('character_registry', _migrateCharacterRegistry);
    await migrate('settings', _migrateSettings);

    final completedAt = DateTime.now().toUtc();
    await _markCompleted(completedAt, languageCode);

    return HiveToDriftMigrationResult.completed(
      languageCode: languageCode,
      completedAt: completedAt,
      scannedRows: scannedRows,
    );
  }

  // -----------------------------------------------------------------------
  // 1. books
  // -----------------------------------------------------------------------

  Future<int> _migrateBooks(String lang) async {
    final boxName = HiveBoxNames.booksFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<BookMetadata>(boxName);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final meta in box.values) {
        b.insert(
          _db.bookEntries,
          BookEntriesCompanion.insert(
            id: meta.id,
            title: meta.title,
            sourcePath: meta.sourcePath,
            language: Value(meta.effectiveSourceLanguage),
            author: Value(meta.author),
            coverPath: Value(meta.coverPath),
            totalChapters: Value(meta.totalChapters),
            globalProgress: Value(meta.globalProgress),
            currentChapter: Value(meta.currentChapter),
            chapterProgress: Value(meta.chapterProgress),
            lastReadAt: Value(_dt(meta.lastReadAt)),
            chapterScrollOffset: Value(meta.chapterScrollOffset),
            sourceLanguage: Value(meta.sourceLanguage ?? lang),
            sourceLanguageOverride: Value(meta.sourceLanguageOverride),
            languageConfidence: Value(meta.languageConfidence),
            targetExplanationLanguage: Value(
              meta.targetExplanationLanguage,
            ),
            difficultyStudyWords: Value(
              meta.difficultyStudyWords?.let(jsonEncode),
            ),
            difficultyRatingJson: Value(
              meta.difficultyRatingJson?.let(jsonEncode),
            ),
            difficultyVocabularySignature: Value(
              meta.difficultyVocabularySignature,
            ),
            difficultyComputedAt: Value(_dt(meta.difficultyComputedAt)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 2. user_vocabulary
  // -----------------------------------------------------------------------

  Future<int> _migrateUserVocabulary(String lang) async {
    final boxName = HiveBoxNames.userVocabularyFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        final rawValue = box.get(key);
        if (rawValue == null || rawValue.isEmpty) continue;
        scanned++;

        UserVocabularyEntry? entry;
        try {
          final decoded = jsonDecode(rawValue);
          if (decoded is Map) {
            entry = UserVocabularyEntry.fromJson(
              decoded.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
        } catch (_) {}

        if (entry != null) {
          b.insert(
            _db.userVocabularies,
            UserVocabulariesCompanion.insert(
              id: entry.key.storageKey,
              canonical: entry.key.canonical,
              status: entry.status.name,
              language: Value(entry.key.languageId),
              createdAt: Value(_dt(entry.createdAt) ?? ''),
              lastModifiedAt: Value(_dt(entry.lastModifiedAt) ?? ''),
              sourceBookId: Value(entry.sourceBookId),
              sourceChapterIndex: Value(entry.sourceChapterIndex),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        } else {
          // Legacy format: raw status string
          final keyStr = key.toString();
          final idx = keyStr.indexOf('_');
          final canonical = idx > 0 ? keyStr.substring(idx + 1) : keyStr;
          b.insert(
            _db.userVocabularies,
            UserVocabulariesCompanion.insert(
              id: '${lang}_$canonical',
              canonical: canonical,
              status: rawValue,
              language: Value(lang),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 3. word_bookmarks
  // -----------------------------------------------------------------------

  Future<int> _migrateWordBookmarks(String lang) async {
    final boxName = HiveBoxNames.wordBookmarksFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final bookId in box.keys) {
        final encodedJson = box.get(bookId);
        if (encodedJson == null || encodedJson.isEmpty) continue;

        try {
          final decoded = jsonDecode(encodedJson);
          if (decoded is! List) continue;

          for (final item in decoded) {
            if (item is! Map) continue;
            final map = item.map((k, v) => MapEntry(k.toString(), v));
            final word = map['word']?.toString();
            if (word == null || word.isEmpty) continue;
            scanned++;
            b.insert(
              _db.wordBookmarks,
              WordBookmarksCompanion.insert(
                id: map['id']?.toString() ?? _generateId(),
                word: word,
                bookId: bookId.toString(),
                language: Value(lang),
                translation: Value(map['translation']?.toString() ?? ''),
                context: Value(map['context']?.toString() ?? ''),
                addedAt: Value(
                  _dt(DateTime.tryParse(map['addedAt']?.toString() ?? '')) ??
                      '',
                ),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        } catch (_) {}
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 4. reading_bookmarks
  // -----------------------------------------------------------------------

  Future<int> _migrateReadingBookmarks(String lang) async {
    final boxName = HiveBoxNames.readingBookmarksFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final bookId in box.keys) {
        final encodedJson = box.get(bookId);
        if (encodedJson == null || encodedJson.isEmpty) continue;

        try {
          final decoded = jsonDecode(encodedJson);
          if (decoded is! List) continue;

          for (final item in decoded) {
            if (item is! Map) continue;
            final map = item.map((k, v) => MapEntry(k.toString(), v));
            scanned++;
            b.insert(
              _db.readingBookmarks,
              ReadingBookmarksCompanion.insert(
                id: map['id']?.toString() ?? _generateId(),
                bookId: bookId.toString(),
                chapterIndex:
                    int.tryParse(
                      map['chapterIndex']?.toString() ?? '',
                    ) ??
                    0,
                progress:
                    double.tryParse(
                      map['progress']?.toString() ?? '',
                    ) ??
                    0.0,
                language: Value(lang),
                chapterTitle: Value(map['chapterTitle']?.toString() ?? ''),
                excerpt: Value(map['excerpt']?.toString() ?? ''),
                createdAt: Value(
                  _dt(DateTime.tryParse(map['createdAt']?.toString() ?? '')) ??
                      '',
                ),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        } catch (_) {}
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 5. reading_config
  // -----------------------------------------------------------------------

  Future<int> _migrateReadingConfig(String lang) async {
    final boxName = HiveBoxNames.readingConfigFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        final stringKey = key.toString();
        final value = box.get(key);
        if (value != null) {
          scanned++;
          b.insert(
            _db.readingConfig,
            ReadingConfigCompanion.insert(
              key: stringKey,
              language: Value(lang),
              value: Value(value),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 6. reading_time
  // -----------------------------------------------------------------------

  Future<int> _migrateReadingTime(String lang) async {
    final boxName = HiveBoxNames.readingTimeFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<int>(boxName);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        b.insert(
          _db.readingTime,
          ReadingTimeCompanion.insert(
            key: key.toString(),
            language: Value(lang),
            seconds: Value(box.get(key) ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 7. dictionary_cache
  // -----------------------------------------------------------------------

  Future<int> _migrateDictionaryCache(String lang) async {
    final boxName = HiveBoxNames.dictionaryCacheFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          scanned++;
          b.insert(
            _db.dictionaryCache,
            DictionaryCacheCompanion.insert(
              key: key.toString(),
              language: Value(lang),
              value: value,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 8. word_contexts
  // -----------------------------------------------------------------------

  Future<int> _migrateWordContexts(String lang) async {
    final boxName = HiveBoxNames.wordContextsFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<String>(boxName);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          scanned++;
          b.insert(
            _db.wordContexts,
            WordContextsCompanion.insert(
              word: key.toString(),
              language: Value(lang),
              data: data,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // 9. learning_items
  // -----------------------------------------------------------------------

  Future<int> _migrateLearningItems(String lang) async {
    final boxName = HiveBoxNames.learningItemsFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<LearningItem>(boxName);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final item in box.values) {
        b.insert(
          _db.learningItems,
          LearningItemsCompanion.insert(
            id: item.id,
            type: item.type.name,
            nextReviewAt: item.nextReviewAt.toUtc().toIso8601String(),
            language: Value(lang),
            canonicalKey: Value(item.canonicalKey),
            title: Value(item.title),
            content: Value(item.content),
            answer: Value(item.answer),
            note: Value(item.note),
            sourceText: Value(item.sourceText),
            bookId: Value(item.bookId),
            chapterIndex: Value(item.chapterIndex),
            chapterTitle: Value(item.chapterTitle),
            tags: Value(jsonEncode(item.tags)),
            metadata: Value(jsonEncode(item.metadata)),
            reviewCount: Value(item.reviewCount),
            lastResult: Value(item.lastResult.name),
            createdAt: Value(_dt(item.createdAt) ?? ''),
            updatedAt: Value(_dt(item.updatedAt) ?? ''),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 10. learning_analytics
  // -----------------------------------------------------------------------

  Future<int> _migrateLearningAnalytics(String lang) async {
    final boxName = HiveBoxNames.learningAnalyticsFor(lang);
    if (!_isBoxOpen(boxName)) return 0;

    final box = Hive.box<int>(boxName);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        b.insert(
          _db.learningAnalytics,
          LearningAnalyticsCompanion.insert(
            key: key.toString(),
            language: Value(lang),
            value: Value(box.get(key) ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 11. word_levels (global)
  // -----------------------------------------------------------------------

  Future<int> _migrateWordLevels() async {
    if (!_isBoxOpen(HiveBoxNames.wordLevels)) return 0;

    final box = Hive.box<WordLevelInfo>(HiveBoxNames.wordLevels);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final entry in box.values) {
        b.insert(
          _db.wordLevels,
          WordLevelsCompanion.insert(
            word: entry.word,
            levelIndex: entry.levelIndex,
            originForm: Value(entry.originForm),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 12. rss_subscriptions (global)
  // -----------------------------------------------------------------------

  Future<int> _migrateRssSubscriptions() async {
    if (!_isBoxOpen(HiveBoxNames.rssSubscriptions)) return 0;

    final box = Hive.box<RssFeedSubscription>(HiveBoxNames.rssSubscriptions);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final sub in box.values) {
        b.insert(
          _db.rssSubscriptions,
          RssSubscriptionsCompanion.insert(
            id: sub.key.toString(),
            url: sub.url,
            title: Value(sub.title),
            description: Value(sub.description),
            imageUrl: Value(sub.imageUrl),
            lastFetchedAt: Value(_dt(sub.lastFetchedAt)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 13. rss_articles — migrate read/fav/later IDs from settings
  // -----------------------------------------------------------------------

  Future<int> _migrateRssArticles() async {
    if (!_isBoxOpen(HiveBoxNames.settings)) return 0;

    final settingsBox = Hive.box(HiveBoxNames.settings);
    final readIds = _getStringSet(settingsBox, 'rss_read_articles');
    final favIds = _getStringSet(settingsBox, 'rss_favorite_articles');
    final laterIds = _getStringSet(settingsBox, 'rss_read_later_articles');

    final allIds = <String, _RssIdStatus>{};
    for (final id in readIds) {
      (allIds[id] ??= _RssIdStatus()).isRead = true;
    }
    for (final id in favIds) {
      (allIds[id] ??= _RssIdStatus()).isFavorite = true;
    }
    for (final id in laterIds) {
      (allIds[id] ??= _RssIdStatus()).isReadLater = true;
    }

    if (allIds.isEmpty) return 0;

    // Legacy settings only store article IDs, not the subscription foreign key
    // required by the Drift table. Keep this as scanned-but-deferred until the
    // RSS repository cutover can import statuses with full article context.
    return allIds.length;
  }

  // -----------------------------------------------------------------------
  // 14. book_glossary (global)
  // -----------------------------------------------------------------------

  Future<int> _migrateBookGlossary() async {
    if (!_isBoxOpen(HiveBoxNames.bookGlossary)) return 0;

    final box = Hive.box<hive_models.BookGlossaryEntry>(
      HiveBoxNames.bookGlossary,
    );
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final entry in box.values) {
        b.insert(
          _db.bookGlossary,
          BookGlossaryCompanion.insert(
            id: entry.id,
            bookId: entry.bookId,
            word: entry.word,
            canonicalForm: Value(entry.canonicalForm),
            explanation: Value(entry.explanation),
            sourceContext: Value(entry.sourceContext),
            createdAt: Value(_dt(entry.createdAt) ?? ''),
            lastAccessedAt: Value(_dt(entry.lastAccessedAt)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 15. character_registry (global)
  // -----------------------------------------------------------------------

  Future<int> _migrateCharacterRegistry() async {
    if (!_isBoxOpen(HiveBoxNames.characterRegistry)) return 0;

    final box = Hive.box<String>(HiveBoxNames.characterRegistry);
    if (box.isEmpty) return 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        b.insert(
          _db.characterRegistry,
          CharacterRegistryCompanion.insert(
            key: key.toString(),
            value: Value(box.get(key) ?? ''),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return box.length;
  }

  // -----------------------------------------------------------------------
  // 16. settings (global)
  // -----------------------------------------------------------------------

  Future<int> _migrateSettings() async {
    if (!_isBoxOpen(HiveBoxNames.settings)) return 0;

    final box = Hive.box(HiveBoxNames.settings);
    if (box.isEmpty) return 0;
    var scanned = 0;

    await _db.batch((b) {
      for (final key in box.keys) {
        final keyStr = key.toString();

        // RSS article ID arrays — migrated separately
        if (keyStr == 'rss_read_articles' ||
            keyStr == 'rss_favorite_articles' ||
            keyStr == 'rss_read_later_articles') {
          continue;
        }

        final rawValue = box.get(key);
        final value = _encodeSettingValue(rawValue);
        scanned++;

        b.insert(
          _db.settings,
          SettingsCompanion.insert(key: keyStr, value: Value(value)),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return scanned;
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  static String _encodeSettingValue(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is bool || raw is int || raw is double) return raw.toString();
    if (raw is Map || raw is List) return jsonEncode(raw);
    return raw.toString();
  }

  static String? _dt(DateTime? dt) => dt?.toUtc().toIso8601String();

  static bool _isBoxOpen(String name) => Hive.isBoxOpen(name);

  Future<DateTime?> _completedAt() async {
    final raw = await _db.settingsDao.valueFor(completedAtKey);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _markCompleted(DateTime completedAt, String languageCode) async {
    await _db.settingsDao.putValue(
      completedAtKey,
      completedAt.toIso8601String(),
    );
    await _db.settingsDao.putValue(
      sourceSchemaVersionKey,
      StorageSchema.currentVersion.toString(),
    );
    await _db.settingsDao.putValue(sourceLanguageKey, languageCode);
  }

  static Set<String> _getStringSet(Box box, String key) {
    final raw = box.get(key);
    if (raw == null) return const {};
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toSet();
        }
      } catch (_) {}
    }
    return const {};
  }

  static int _idCounter = 0;
  static String _generateId() {
    _idCounter++;
    return 'migrated_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }
}

class _RssIdStatus {
  bool isRead = false;
  bool isFavorite = false;
  bool isReadLater = false;
}

extension _Let<T> on T {
  R let<R>(R Function(T it) transform) => transform(this);
}

final class HiveToDriftMigrationResult {
  const HiveToDriftMigrationResult._({
    required this.languageCode,
    required this.completedAt,
    required this.scannedRows,
    required this.skipped,
  });

  factory HiveToDriftMigrationResult.completed({
    required String languageCode,
    required DateTime completedAt,
    required Map<String, int> scannedRows,
  }) {
    return HiveToDriftMigrationResult._(
      languageCode: languageCode,
      completedAt: completedAt,
      scannedRows: Map.unmodifiable(scannedRows),
      skipped: false,
    );
  }

  factory HiveToDriftMigrationResult.skipped({
    required String languageCode,
    required DateTime completedAt,
  }) {
    return HiveToDriftMigrationResult._(
      languageCode: languageCode,
      completedAt: completedAt,
      scannedRows: const {},
      skipped: true,
    );
  }

  final String languageCode;
  final DateTime completedAt;
  final Map<String, int> scannedRows;
  final bool skipped;

  int get totalScannedRows =>
      scannedRows.values.fold(0, (total, value) => total + value);
}
