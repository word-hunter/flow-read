import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/character_registry_entry.dart';
import '../storage/hive_box_names.dart';

class CharacterRegistry {
  Box<String> get _box => Hive.box<String>(HiveBoxNames.characterRegistry);

  List<CharacterRegistryEntry> getAll(String bookId) {
    return _decode(_box.get(bookId));
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
        firstAppearanceChapter: entry.firstAppearanceChapter ??
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
    await _box.delete(bookId);
  }

  Future<void> _save(
    String bookId,
    List<CharacterRegistryEntry> entries,
  ) async {
    if (entries.isEmpty) {
      await _box.delete(bookId);
      return;
    }
    await _box.put(
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
          .map((e) => CharacterRegistryEntry.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
