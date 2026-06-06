enum UserWordStatus { known, learning }

class UserVocabularyKey {
  const UserVocabularyKey({
    required this.languageId,
    required this.canonical,
  });

  final String languageId;
  final String canonical;

  String get storageKey => '${_normalize(languageId)}_${_normalize(canonical)}';

  Map<String, dynamic> toJson() => {
    'languageId': _normalize(languageId),
    'canonical': _normalize(canonical),
  };

  factory UserVocabularyKey.fromJson(Map<String, dynamic> json) {
    return UserVocabularyKey(
      languageId: json['languageId']?.toString() ?? 'en',
      canonical: json['canonical']?.toString() ?? '',
    );
  }

  static UserVocabularyKey fromStorageKey(
    String storageKey, {
    required String fallbackLanguageId,
  }) {
    final normalizedLanguage = _normalize(fallbackLanguageId);
    final prefix = '${normalizedLanguage}_';
    if (storageKey.startsWith(prefix) && storageKey.length > prefix.length) {
      return UserVocabularyKey(
        languageId: normalizedLanguage,
        canonical: storageKey.substring(prefix.length),
      );
    }
    return UserVocabularyKey(
      languageId: normalizedLanguage,
      canonical: storageKey,
    );
  }

  static String _normalize(String value) => value.toLowerCase().trim();
}

class UserVocabularyEntry {
  const UserVocabularyEntry({
    required this.key,
    required this.status,
    required this.createdAt,
    required this.lastModifiedAt,
    this.sourceBookId,
    this.sourceChapterIndex,
  });

  final UserVocabularyKey key;
  final UserWordStatus status;
  final DateTime createdAt;
  final DateTime lastModifiedAt;
  final String? sourceBookId;
  final int? sourceChapterIndex;

  Map<String, dynamic> toJson() => {
    'key': key.toJson(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'lastModifiedAt': lastModifiedAt.toIso8601String(),
    if (sourceBookId != null) 'sourceBookId': sourceBookId,
    if (sourceChapterIndex != null) 'sourceChapterIndex': sourceChapterIndex,
  };

  factory UserVocabularyEntry.fromJson(Map<String, dynamic> json) {
    final rawKey = json['key'];
    final key = rawKey is Map
        ? UserVocabularyKey.fromJson(
            rawKey.map((key, value) => MapEntry(key.toString(), value)),
          )
        : UserVocabularyKey(
            languageId: json['languageId']?.toString() ?? 'en',
            canonical: json['canonical']?.toString() ?? '',
          );
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final lastModifiedAt = DateTime.tryParse(
      json['lastModifiedAt']?.toString() ?? '',
    );
    return UserVocabularyEntry(
      key: key,
      status: _statusFromString(json['status']?.toString()),
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastModifiedAt:
          lastModifiedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      sourceBookId: json['sourceBookId']?.toString(),
      sourceChapterIndex: json['sourceChapterIndex'] is num
          ? (json['sourceChapterIndex'] as num).toInt()
          : null,
    );
  }

  static UserWordStatus _statusFromString(String? value) {
    return value == UserWordStatus.learning.name
        ? UserWordStatus.learning
        : UserWordStatus.known;
  }
}
