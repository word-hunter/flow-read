import 'dart:convert';

import 'package:flow_ai/flow_ai.dart';
import '../storage/repositories/character_registry_repository.dart';

class CharacterRegistry {
  CharacterRegistry({required CharacterRegistryRepository repository})
    : _repository = repository;

  final CharacterRegistryRepository _repository;

  Future<void> init() => _repository.init();

  List<CharacterRegistryEntry> getAll(String bookId) {
    return _decode(_repository.valueFor(bookId));
  }

  String? matchCanonical(String bookId, String name) {
    final entries = getAll(bookId);
    for (final entry in entries) {
      if (entry.matches(name)) return entry.canonicalName;
    }
    return null;
  }

  Future<void> addEntry(String bookId, CharacterRegistryEntry entry) async {
    final entries = getAll(bookId);
    final existing = entries.indexWhere(
      (e) => e.canonicalName == entry.canonicalName,
    );
    if (existing >= 0) {
      entries[existing] = CharacterRegistryEntry(
        canonicalName: entry.canonicalName,
        aliases: {...entries[existing].aliases, ...entry.aliases},
        userOverrides: entries[existing].userOverrides,
        firstAppearanceChapter:
            entry.firstAppearanceChapter ??
            entries[existing].firstAppearanceChapter,
        updatedAt: DateTime.now(),
      );
    } else {
      entries.add(entry);
    }
    await _save(bookId, entries);
  }

  Future<void> addAlias(
    String bookId,
    String canonicalName,
    String alias, {
    bool userOverride = false,
  }) async {
    final trimmedAlias = alias.trim();
    if (trimmedAlias.isEmpty) return;

    final entries = getAll(bookId);
    final index = entries.indexWhere(
      (e) => e.canonicalName == canonicalName,
    );
    if (index < 0) return;

    final entry = entries[index];
    if (userOverride) {
      entries[index] = CharacterRegistryEntry(
        canonicalName: entry.canonicalName,
        aliases: entry.aliases,
        userOverrides: {...entry.userOverrides, trimmedAlias},
        firstAppearanceChapter: entry.firstAppearanceChapter,
        updatedAt: DateTime.now(),
      );
    } else {
      entries[index] = CharacterRegistryEntry(
        canonicalName: entry.canonicalName,
        aliases: {...entry.aliases, trimmedAlias},
        userOverrides: entry.userOverrides,
        firstAppearanceChapter: entry.firstAppearanceChapter,
        updatedAt: DateTime.now(),
      );
    }
    await _save(bookId, entries);
  }

  Future<void> removeAlias(
    String bookId,
    String canonicalName,
    String alias,
  ) async {
    final entries = getAll(bookId);
    final index = entries.indexWhere(
      (e) => e.canonicalName == canonicalName,
    );
    if (index < 0) return;

    final entry = entries[index];
    entries[index] = CharacterRegistryEntry(
      canonicalName: entry.canonicalName,
      aliases: entry.aliases.where((a) => a != alias).toSet(),
      userOverrides: entry.userOverrides.where((a) => a != alias).toSet(),
      firstAppearanceChapter: entry.firstAppearanceChapter,
      updatedAt: DateTime.now(),
    );
    await _save(bookId, entries);
  }

  Future<void> removeEntry(String bookId, String canonicalName) async {
    final entries = getAll(bookId);
    entries.removeWhere((e) => e.canonicalName == canonicalName);
    await _save(bookId, entries);
  }

  Future<void> clearForBook(String bookId) async {
    await _repository.delete(bookId);
  }

  Future<void> _save(
    String bookId,
    List<CharacterRegistryEntry> entries,
  ) async {
    if (entries.isEmpty) {
      await _repository.delete(bookId);
      return;
    }
    await _repository.putValue(
      bookId,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<CharacterRegistryEntry> _decode(String? source) {
    if (source == null || source.isEmpty) return [];
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (e) => CharacterRegistryEntry.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
