import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/user_vocabulary.dart';
import '../hive_box_names.dart';
import 'hive_repository_box.dart';

abstract class UserVocabularyRepository {
  Future<void> init();
  UserWordStatus? getStatus(String word);
  Set<String> wordsWithStatus(UserWordStatus status);
  Map<String, UserWordStatus> get allWords;
  Future<void> setStatus(String word, UserWordStatus status);
  Future<void> remove(String word);
  Future<void> close();
}

class HiveUserVocabularyRepository implements UserVocabularyRepository {
  HiveUserVocabularyRepository({Box<String>? box, String? languageCode})
    : _box = box,
      _languageCode = activeHiveLanguageCode(languageCode);

  Box<String>? _box;
  final String _languageCode;

  Box<String> get _storage =>
      _box ??
      requireOpenHiveBox<String>(HiveBoxNames.userVocabularyFor(_languageCode));

  @override
  Future<void> init() async {
    _box ??= requireOpenHiveBox<String>(
      HiveBoxNames.userVocabularyFor(_languageCode),
    );
    await _migrateLegacyKeys();
  }

  @override
  UserWordStatus? getStatus(String word) {
    return _entryForWord(word)?.status;
  }

  @override
  Set<String> wordsWithStatus(UserWordStatus status) {
    final result = <String>{};
    for (final entry in _entries) {
      if (entry.status == status) result.add(entry.key.canonical);
    }
    return result;
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
