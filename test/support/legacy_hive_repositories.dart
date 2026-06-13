import 'dart:convert';

import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/repositories/book_metadata_repository.dart';
import 'package:flow_read/storage/repositories/bookmark_repository.dart';
import 'package:flow_read/storage/repositories/character_registry_repository.dart';
import 'package:flow_read/storage/repositories/learning_analytics_repository.dart';
import 'package:flow_read/storage/repositories/learning_item_repository.dart';
import 'package:flow_read/storage/repositories/reading_config_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';
import 'package:flow_read/storage/repositories/word_context_repository.dart';
import 'package:flow_read/storage/repositories/word_level_repository.dart';
import 'package:flow_rss/flow_rss.dart';
import 'package:hive/hive.dart';

Box<T> _requireOpenHiveBox<T>(String name) {
  if (!Hive.isBoxOpen(name)) {
    throw StateError('Hive box "$name" is not open');
  }
  return Hive.box<T>(name);
}

String _activeHiveLanguageCode(String? override) {
  final explicit = override?.trim().toLowerCase();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  if (!Hive.isBoxOpen(HiveBoxNames.settings)) {
    return HiveBoxNames.defaultLanguageCode;
  }
  final stored = Hive.box(HiveBoxNames.settings).get(
    HiveBoxNames.activeSourceLanguageKey,
    defaultValue: HiveBoxNames.defaultLanguageCode,
  );
  final code = stored?.toString().trim().toLowerCase();
  return code == null || code.isEmpty ? HiveBoxNames.defaultLanguageCode : code;
}

class HiveBookMetadataRepository implements BookMetadataRepository {
  HiveBookMetadataRepository({Box<BookMetadata>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<BookMetadata>? _box;
  final String _languageCode;

  Box<BookMetadata> get _storage {
    return _box ??
        _requireOpenHiveBox<BookMetadata>(
          HiveBoxNames.booksFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<BookMetadata>(
      HiveBoxNames.booksFor(_languageCode),
    );
  }

  @override
  Iterable<BookMetadata> get values => _storage.values;

  @override
  BookMetadata? get(String id) => _storage.get(id);

  @override
  Future<void> put(String id, BookMetadata metadata) async {
    await _storage.put(id, metadata);
  }

  @override
  Future<void> delete(String id) async {
    await _storage.delete(id);
  }

  @override
  Future<void> close() async {}
}

class HiveBookmarkRepository implements BookmarkRepository {
  HiveBookmarkRepository({
    Box<String>? wordBox,
    Box<String>? readingBox,
    String? languageCode,
  }) : _wordBox = wordBox,
       _readingBox = readingBox,
       _languageCode = _activeHiveLanguageCode(languageCode);

  Box<String>? _wordBox;
  Box<String>? _readingBox;
  final String _languageCode;

  Box<String> get _wordStorage {
    return _wordBox ??
        _requireOpenHiveBox<String>(
          HiveBoxNames.wordBookmarksFor(_languageCode),
        );
  }

  Box<String> get _readingStorage {
    return _readingBox ??
        _requireOpenHiveBox<String>(
          HiveBoxNames.readingBookmarksFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _wordBox ??= _requireOpenHiveBox<String>(
      HiveBoxNames.wordBookmarksFor(_languageCode),
    );
    _readingBox ??= _requireOpenHiveBox<String>(
      HiveBoxNames.readingBookmarksFor(_languageCode),
    );
  }

  @override
  String? getWordBookmarks(String bookId) => _wordStorage.get(bookId);

  @override
  Future<void> putWordBookmarks(String bookId, String encodedBookmarks) async {
    await _wordStorage.put(bookId, encodedBookmarks);
  }

  @override
  Future<void> deleteWordBookmarks(String bookId) async {
    await _wordStorage.delete(bookId);
  }

  @override
  String? getReadingBookmarks(String bookId) => _readingStorage.get(bookId);

  @override
  Future<void> putReadingBookmarks(
    String bookId,
    String encodedBookmarks,
  ) async {
    await _readingStorage.put(bookId, encodedBookmarks);
  }

  @override
  Future<void> deleteReadingBookmarks(String bookId) async {
    await _readingStorage.delete(bookId);
  }

  @override
  Future<void> close() async {}
}

class HiveCharacterRegistryRepository implements CharacterRegistryRepository {
  HiveCharacterRegistryRepository({Box<String>? box}) : _box = box;

  Box<String>? _box;

  Box<String> get _storage {
    return _box ?? _requireOpenHiveBox<String>(HiveBoxNames.characterRegistry);
  }

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<String>(HiveBoxNames.characterRegistry);
  }

  @override
  String? valueFor(String key) => _storage.get(key);

  @override
  Future<void> putValue(String key, String value) async {
    await _storage.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key);
  }

  @override
  Future<void> close() async {}
}

class HiveLearningAnalyticsRepository implements LearningAnalyticsRepository {
  HiveLearningAnalyticsRepository({Box<int>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<int>? _box;
  final String _languageCode;

  Box<int> get _storage {
    return _box ??
        _requireOpenHiveBox<int>(
          HiveBoxNames.learningAnalyticsFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<int>(
      HiveBoxNames.learningAnalyticsFor(_languageCode),
    );
  }

  @override
  int countFor(String key) => _storage.get(key, defaultValue: 0) ?? 0;

  @override
  Iterable<String> get keys => _storage.keys.map((key) => key.toString());

  @override
  Future<void> putCount(String key, int count) async {
    await _storage.put(key, count);
  }

  @override
  Future<void> close() async {}
}

class HiveLearningItemRepository implements LearningItemRepository {
  HiveLearningItemRepository({Box<LearningItem>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<LearningItem>? _box;
  final String _languageCode;

  Box<LearningItem> get _storage {
    return _box ??
        _requireOpenHiveBox<LearningItem>(
          HiveBoxNames.learningItemsFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<LearningItem>(
      HiveBoxNames.learningItemsFor(_languageCode),
    );
  }

  @override
  Iterable<LearningItem> get values => _storage.values;

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  int get length => _storage.length;

  @override
  LearningItem? get(dynamic key) => _storage.get(key);

  @override
  Future<void> put(String id, LearningItem item) async {
    await _storage.put(id, item);
  }

  @override
  Future<void> delete(String id) async {
    await _storage.delete(id);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    await _storage.deleteAll(keys);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }

  @override
  Future<void> close() async {}
}

class HiveReadingConfigRepository implements ReadingConfigRepository {
  HiveReadingConfigRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      _requireOpenHiveBox<String>(
        HiveBoxNames.readingConfigFor(_languageCode),
      );

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<String>(
      HiveBoxNames.readingConfigFor(_languageCode),
    );
  }

  @override
  String getString(String key, {required String defaultValue}) {
    return _storage.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  @override
  Future<void> putString(String key, String value) async {
    await _storage.put(key, value);
  }

  @override
  Future<void> close() async {}
}

class HiveReadingTimeRepository implements ReadingTimeRepository {
  HiveReadingTimeRepository({Box<int>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<int>? _box;
  final String _languageCode;

  Box<int> get _storage =>
      _box ??
      _requireOpenHiveBox<int>(HiveBoxNames.readingTimeFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<int>(
      HiveBoxNames.readingTimeFor(_languageCode),
    );
  }

  @override
  int secondsFor(String key) => _storage.get(key, defaultValue: 0) ?? 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {
    await _storage.put(key, seconds);
  }

  @override
  Future<void> close() async {}
}

class HiveUserVocabularyRepository implements UserVocabularyRepository {
  HiveUserVocabularyRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      _requireOpenHiveBox<String>(
        HiveBoxNames.userVocabularyFor(_languageCode),
      );

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<String>(
      HiveBoxNames.userVocabularyFor(_languageCode),
    );
    await _migrateLegacyKeys();
  }

  @override
  UserWordStatus? getStatus(String word) => _entryForWord(word)?.status;

  @override
  Set<String> wordsWithStatus(UserWordStatus status) {
    return {
      for (final entry in _entries)
        if (entry.status == status) entry.key.canonical,
    };
  }

  @override
  Map<String, UserWordStatus> get allWords {
    return {
      for (final entry in _entries) entry.key.canonical: entry.status,
    };
  }

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    final canonical = _normalize(word);
    final key = UserVocabularyKey(
      languageId: _languageCode,
      canonical: canonical,
    );
    final now = DateTime.now();
    final existing = _entryForStorageKey(key.storageKey);
    final entry = UserVocabularyEntry(
      key: key,
      status: status,
      createdAt: existing?.createdAt ?? now,
      lastModifiedAt: now,
      sourceBookId: existing?.sourceBookId,
      sourceChapterIndex: existing?.sourceChapterIndex,
    );
    await _storage.put(key.storageKey, jsonEncode(entry.toJson()));
    if (_storage.containsKey(canonical)) {
      await _storage.delete(canonical);
    }
  }

  @override
  Future<void> remove(String word) async {
    final canonical = _normalize(word);
    await _storage.delete(_storageKey(canonical));
    await _storage.delete(canonical);
  }

  @override
  Future<void> close() async {}

  Iterable<UserVocabularyEntry> get _entries sync* {
    for (final rawKey in _storage.keys) {
      final key = rawKey.toString();
      final entry = _entryForStorageKey(key);
      if (entry != null && entry.key.languageId == _languageCode) {
        yield entry;
      }
    }
  }

  String _normalize(String word) => word.toLowerCase().trim();

  String _storageKey(String canonical) {
    return UserVocabularyKey(
      languageId: _languageCode,
      canonical: canonical,
    ).storageKey;
  }

  UserVocabularyEntry? _entryForWord(String word) {
    final canonical = _normalize(word);
    return _entryForStorageKey(_storageKey(canonical)) ??
        _entryForStorageKey(canonical);
  }

  UserVocabularyEntry? _entryForStorageKey(String storageKey) {
    final value = _storage.get(storageKey);
    if (value == null) return null;
    return _decodeEntry(storageKey, value);
  }

  UserVocabularyEntry _decodeEntry(String storageKey, String value) {
    if (value.trimLeft().startsWith('{')) {
      try {
        return UserVocabularyEntry.fromJson(
          (jsonDecode(value) as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      } catch (_) {
        // Fall through to legacy status decoding for corrupt entries.
      }
    }

    final key = UserVocabularyKey.fromStorageKey(
      storageKey,
      fallbackLanguageId: _languageCode,
    );
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return UserVocabularyEntry(
      key: key,
      status: value == UserWordStatus.learning.name
          ? UserWordStatus.learning
          : UserWordStatus.known,
      createdAt: now,
      lastModifiedAt: now,
    );
  }

  Future<void> _migrateLegacyKeys() async {
    final keys = _storage.keys.map((key) => key.toString()).toList();
    for (final key in keys) {
      if (_isLanguageAwareKey(key)) continue;
      final value = _storage.get(key);
      if (value == null) continue;

      final canonical = _normalize(key);
      if (canonical.isEmpty) {
        await _storage.delete(key);
        continue;
      }

      final storageKey = _storageKey(canonical);
      if (!_storage.containsKey(storageKey)) {
        final entry = _decodeEntry(key, value);
        final now = DateTime.now();
        final migrated = UserVocabularyEntry(
          key: UserVocabularyKey(
            languageId: _languageCode,
            canonical: canonical,
          ),
          status: entry.status,
          createdAt: now,
          lastModifiedAt: now,
          sourceBookId: entry.sourceBookId,
          sourceChapterIndex: entry.sourceChapterIndex,
        );
        await _storage.put(storageKey, jsonEncode(migrated.toJson()));
      }
      await _storage.delete(key);
    }
  }

  bool _isLanguageAwareKey(String key) {
    return key.startsWith('${_languageCode}_') &&
        key.length > _languageCode.length + 1;
  }
}

class HiveWordContextRepository implements WordContextRepository {
  HiveWordContextRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      _requireOpenHiveBox<String>(HiveBoxNames.wordContextsFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<String>(
      HiveBoxNames.wordContextsFor(_languageCode),
    );
  }

  @override
  String? getEncodedExamples(String word) => _storage.get(word);

  @override
  Future<void> putEncodedExamples(String word, String encodedExamples) async {
    await _storage.put(word, encodedExamples);
  }

  @override
  Future<void> close() async {}
}

class HiveWordLevelRepository implements WordLevelRepository {
  HiveWordLevelRepository({Box<WordLevelInfo>? wordBox, Box<dynamic>? metaBox})
    : _wordBox = wordBox,
      _metaBox = metaBox;

  static const _importedKey = 'word_levels_imported';

  Box<WordLevelInfo>? _wordBox;
  Box<dynamic>? _metaBox;

  Box<WordLevelInfo> get _wordStorage {
    return _wordBox ??
        _requireOpenHiveBox<WordLevelInfo>(HiveBoxNames.wordLevels);
  }

  Box<dynamic> get _metaStorage {
    return _metaBox ?? _requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Future<void> init() async {
    _wordBox ??= _requireOpenHiveBox<WordLevelInfo>(HiveBoxNames.wordLevels);
    _metaBox ??= _requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Iterable<WordLevelInfo> get values => _wordStorage.values;

  @override
  bool get isNotEmpty => _wordStorage.isNotEmpty;

  @override
  bool get imported => _metaStorage.get(_importedKey) == 'true';

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    await _wordStorage.addAll(entries);
  }

  @override
  Future<void> markImported() async {
    await _metaStorage.put(_importedKey, 'true');
  }

  @override
  Future<void> close() async {}
}

class HiveDictionaryCacheRepository implements DictionaryCacheRepository {
  HiveDictionaryCacheRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = _activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage {
    return _box ??
        _requireOpenHiveBox<String>(
          HiveBoxNames.dictionaryCacheFor(_languageCode),
        );
  }

  @override
  Future<void> init() async {
    _box ??= _requireOpenHiveBox<String>(
      HiveBoxNames.dictionaryCacheFor(_languageCode),
    );
  }

  @override
  String? get(String key) => _storage.get(key);

  @override
  Future<void> put(String key, String content) async {
    await _storage.put(key, content);
  }

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  int get length => _storage.length;

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  Future<void> delete(dynamic key) async {
    await _storage.delete(key);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }

  @override
  Future<void> close() async {}
}

class HiveRssRepository implements RssRepository {
  HiveRssRepository({Box<RssFeedSubscription>? feedBox, Box<dynamic>? metaBox})
    : _feedBox = feedBox,
      _metaBox = metaBox;

  static const _readArticlesKey = 'rss_read_articles';
  static const _favoriteArticlesKey = 'rss_favorite_articles';
  static const _readLaterArticlesKey = 'rss_read_later_articles';

  Box<RssFeedSubscription>? _feedBox;
  Box<dynamic>? _metaBox;

  Box<RssFeedSubscription> get _feedStorage {
    return _feedBox ??
        _requireOpenHiveBox<RssFeedSubscription>(
          HiveBoxNames.rssSubscriptions,
        );
  }

  Box<dynamic> get _metaStorage {
    return _metaBox ?? _requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Future<void> init() async {
    _feedBox ??= _requireOpenHiveBox<RssFeedSubscription>(
      HiveBoxNames.rssSubscriptions,
    );
    _metaBox ??= _requireOpenHiveBox<dynamic>(HiveBoxNames.settings);
  }

  @override
  Iterable<RssFeedSubscription> get subscriptions => _feedStorage.values;

  @override
  RssFeedSubscription? findSubscriptionByUrl(String url) {
    final key = _keyForUrl(url);
    return key == null ? null : _feedStorage.get(key);
  }

  @override
  Future<void> addSubscription(RssFeedSubscription subscription) async {
    await _feedStorage.add(subscription);
  }

  @override
  Future<RssFeedSubscription?> replaceSubscription(
    String originalUrl,
    RssFeedSubscription subscription,
  ) async {
    final key = _keyForUrl(originalUrl);
    if (key == null) return null;
    await _feedStorage.put(key, subscription);
    return subscription;
  }

  @override
  Future<bool> deleteSubscriptionByUrl(String url) async {
    final key = _keyForUrl(url);
    if (key == null) return false;
    await _feedStorage.delete(key);
    return true;
  }

  @override
  Future<void> cacheArticles(
    String feedUrl,
    Iterable<RssArticle> articles,
  ) async {}

  @override
  Set<String> get readArticleIds => _readStringSet(_readArticlesKey);

  @override
  Future<void> putReadArticleIds(Set<String> ids) async {
    await _writeStringSet(_readArticlesKey, ids);
  }

  @override
  Set<String> get favoriteArticleIds => _readStringSet(_favoriteArticlesKey);

  @override
  Future<void> putFavoriteArticleIds(Set<String> ids) async {
    await _writeStringSet(_favoriteArticlesKey, ids);
  }

  @override
  Set<String> get readLaterArticleIds => _readStringSet(_readLaterArticlesKey);

  @override
  Future<void> putReadLaterArticleIds(Set<String> ids) async {
    await _writeStringSet(_readLaterArticlesKey, ids);
  }

  Set<String> _readStringSet(String key) {
    final encoded = _metaStorage.get(key);
    if (encoded is! String || encoded.isEmpty) return {};
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeStringSet(String key, Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _metaStorage.put(key, jsonEncode(sorted));
  }

  @override
  Future<void> updateLastFetched(String url, DateTime fetchedAt) async {
    final key = _keyForUrl(url);
    if (key == null) return;
    final current = _feedStorage.get(key);
    if (current == null) return;

    await _feedStorage.put(
      key,
      RssFeedSubscription(
        url: current.url,
        title: current.title,
        description: current.description,
        imageUrl: current.imageUrl,
        lastFetchedAt: fetchedAt,
      ),
    );
  }

  @override
  Future<void> close() async {}

  dynamic _keyForUrl(String url) {
    for (final key in _feedStorage.keys) {
      if (_feedStorage.get(key)?.url == url) return key;
    }
    return null;
  }
}
