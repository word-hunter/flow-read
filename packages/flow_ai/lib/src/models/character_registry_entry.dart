class CharacterRegistryEntry {
  const CharacterRegistryEntry({
    required this.canonicalName,
    this.aliases = const {},
    this.userOverrides = const {},
    this.firstAppearanceChapter,
    required this.updatedAt,
  });

  final String canonicalName;
  final Set<String> aliases;
  final Set<String> userOverrides;
  final int? firstAppearanceChapter;
  final DateTime updatedAt;

  bool matches(String name) {
    final normalized = name.trim().toLowerCase();
    return canonicalName.toLowerCase() == normalized ||
        aliases.map((alias) => alias.toLowerCase()).contains(normalized) ||
        userOverrides.map((alias) => alias.toLowerCase()).contains(normalized);
  }

  Map<String, dynamic> toJson() => {
        'canonicalName': canonicalName,
        'aliases': aliases.toList(),
        'userOverrides': userOverrides.toList(),
        'firstAppearanceChapter': firstAppearanceChapter,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CharacterRegistryEntry.fromJson(Map<String, dynamic> json) {
    return CharacterRegistryEntry(
      canonicalName: json['canonicalName'] as String? ?? '',
      aliases: _toStringSet(json['aliases']),
      userOverrides: _toStringSet(json['userOverrides']),
      firstAppearanceChapter: json['firstAppearanceChapter'] as int?,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static Set<String> _toStringSet(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toSet();
    }
    return const {};
  }
}
