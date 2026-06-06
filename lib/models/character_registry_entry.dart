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
}
