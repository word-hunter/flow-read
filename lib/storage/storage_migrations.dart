import 'package:hive/hive.dart';

import '../models/book_metadata.dart';
import '../models/learning_item.dart';
import 'hive_box_names.dart';

class StorageSchema {
  const StorageSchema._();

  static const currentVersion = 2;
  static const versionKey = 'flow_read_storage_schema_version';
}

Future<void> runStorageMigrations() async {
  final settings = Hive.box(HiveBoxNames.settings);
  final rawVersion = settings.get(StorageSchema.versionKey);
  final storedVersion = rawVersion is int
      ? rawVersion
      : int.tryParse(rawVersion?.toString() ?? '');

  if (storedVersion == null || storedVersion < 2) {
    await _migrateV1ToV2();
    await settings.put(StorageSchema.versionKey, StorageSchema.currentVersion);
  }

  await _backfillMissingReadingConfigFromV1();
}

Future<void> migrateV1BoxesToLanguageBoxes() => _migrateV1ToV2();

Future<void> _migrateV1ToV2() async {
  const lang = HiveBoxNames.defaultLanguageCode;
  final settings = Hive.box(HiveBoxNames.settings);
  if (settings.get(HiveBoxNames.activeSourceLanguageKey) == null) {
    await settings.put(HiveBoxNames.activeSourceLanguageKey, lang);
  }

  await _copyBox<BookMetadata>(HiveBoxNames.books, HiveBoxNames.booksFor(lang));
  await _copyBox<String>(
    HiveBoxNames.userVocabulary,
    HiveBoxNames.userVocabularyFor(lang),
  );
  await _copyBox<String>(
    HiveBoxNames.wordBookmarks,
    HiveBoxNames.wordBookmarksFor(lang),
  );
  await _copyBox<String>(
    HiveBoxNames.wordContexts,
    HiveBoxNames.wordContextsFor(lang),
  );
  await _copyBox<String>(
    HiveBoxNames.readingBookmarks,
    HiveBoxNames.readingBookmarksFor(lang),
  );
  await _copyBox<String>(
    HiveBoxNames.readingConfig,
    HiveBoxNames.readingConfigFor(lang),
  );
  await _copyBox<int>(
    HiveBoxNames.readingTime,
    HiveBoxNames.readingTimeFor(lang),
  );
  await _copyBox<LearningItem>(
    HiveBoxNames.learningItems,
    HiveBoxNames.learningItemsFor(lang),
  );
  await _copyBox<int>(
    HiveBoxNames.learningAnalytics,
    HiveBoxNames.learningAnalyticsFor(lang),
  );
}

Future<void> _backfillMissingReadingConfigFromV1() async {
  final oldBox = await _openExistingBox<String>(HiveBoxNames.readingConfig);
  if (oldBox == null || oldBox.isEmpty) return;

  for (final languageCode in _readingConfigBackfillLanguages()) {
    final newBoxName = HiveBoxNames.readingConfigFor(languageCode);
    final newBox = Hive.isBoxOpen(newBoxName)
        ? Hive.box<String>(newBoxName)
        : await Hive.openBox<String>(newBoxName);

    const keys = ['fontSize', 'fontFamily', 'lineHeight', 'theme'];
    for (final key in keys) {
      if (newBox.containsKey(key)) continue;
      final value = oldBox.get(key);
      if (value != null && value.isNotEmpty) {
        await newBox.put(key, value);
      }
    }
  }
}

Set<String> _readingConfigBackfillLanguages() {
  final settings = Hive.box(HiveBoxNames.settings);
  final raw = settings.get(
    HiveBoxNames.activeSourceLanguageKey,
    defaultValue: HiveBoxNames.defaultLanguageCode,
  );
  final active = raw?.toString().trim().toLowerCase();
  return {
    HiveBoxNames.defaultLanguageCode,
    if (active != null && active.isNotEmpty) active,
  };
}

Future<void> _copyBox<T>(String oldName, String newName) async {
  final oldBox = await _openExistingBox<T>(oldName);
  if (oldBox == null || oldBox.isEmpty) return;
  final newBox = Hive.isBoxOpen(newName)
      ? Hive.box<T>(newName)
      : await Hive.openBox<T>(newName);
  for (final key in oldBox.keys) {
    final value = oldBox.get(key);
    if (value != null) {
      await newBox.put(key, value);
    }
  }
}

Future<Box<T>?> _openExistingBox<T>(String name) async {
  if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
  if (!await Hive.boxExists(name)) return null;
  return Hive.openBox<T>(name);
}
