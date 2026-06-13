import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/storage/repositories/character_registry_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../support/hive_test_storage.dart';

void main() {
  late Directory tempDir;
  late CharacterRegistry registry;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_character_test_');
    await openFlowReadTestBoxes();
    registry = CharacterRegistry(
      repository: HiveCharacterRegistryRepository(),
    );
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('getAll returns empty list for unknown book', () {
    expect(registry.getAll('unknown-book'), isEmpty);
  });

  test('matchCanonical returns null when no match', () {
    expect(registry.matchCanonical('book-1', 'Ned'), isNull);
  });

  test(
    'addEntry persists and matchCanonical finds by canonical name',
    () async {
      await registry.addEntry(
        'book-1',
        CharacterRegistryEntry(
          canonicalName: 'Eddard Stark',
          aliases: const {'Ned'},
          updatedAt: DateTime.utc(2026, 6, 1),
        ),
      );

      expect(registry.matchCanonical('book-1', 'Eddard Stark'), 'Eddard Stark');
      expect(registry.matchCanonical('book-1', 'eddard stark'), 'Eddard Stark');
    },
  );

  test('matchCanonical returns null for wrong book', () async {
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Eddard Stark',
        aliases: const {'Ned'},
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    expect(registry.matchCanonical('book-2', 'Eddard Stark'), isNull);
  });

  test('matchCanonical matches by alias', () async {
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Eddard Stark',
        aliases: const {'Ned'},
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    expect(registry.matchCanonical('book-1', 'Ned'), 'Eddard Stark');
    expect(registry.matchCanonical('book-1', 'ned'), 'Eddard Stark');
  });

  test('matchCanonical matches by user override', () async {
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Eddard Stark',
        userOverrides: const {'Lord Stark'},
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    expect(registry.matchCanonical('book-1', 'Lord Stark'), 'Eddard Stark');
  });

  test('getAll returns entries for book', () async {
    await registry.addEntry(
      'book-x',
      CharacterRegistryEntry(
        canonicalName: 'Harry Potter',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.addEntry(
      'book-x',
      CharacterRegistryEntry(
        canonicalName: 'Hermione Granger',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    final entries = registry.getAll('book-x');
    expect(entries, hasLength(2));
  });

  test('addEntry merges aliases from duplicate canonical name', () async {
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Albus Dumbledore',
        aliases: const {'Dumbledore'},
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Albus Dumbledore',
        aliases: const {'Professor Dumbledore'},
        updatedAt: DateTime.utc(2026, 6, 2),
      ),
    );

    final entries = registry.getAll('book-1');
    expect(entries, hasLength(1));
    expect(entries.first.aliases, contains('Dumbledore'));
    expect(entries.first.aliases, contains('Professor Dumbledore'));
    expect(registry.matchCanonical('book-1', 'Dumbledore'), 'Albus Dumbledore');
  });

  test('addAlias adds alias to existing entry', () async {
    await registry.addEntry(
      'book-a',
      CharacterRegistryEntry(
        canonicalName: 'Harry Potter',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.addAlias('book-a', 'Harry Potter', 'The Boy Who Lived');

    expect(
      registry.matchCanonical('book-a', 'The Boy Who Lived'),
      'Harry Potter',
    );
  });

  test('addAlias with userOverride sets userOverrides field', () async {
    await registry.addEntry(
      'book-a',
      CharacterRegistryEntry(
        canonicalName: 'Harry Potter',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.addAlias(
      'book-a',
      'Harry Potter',
      'Potter',
      userOverride: true,
    );

    final entries = registry.getAll('book-a');
    expect(entries.single.userOverrides, contains('Potter'));
    expect(entries.single.aliases, isNot(contains('Potter')));
  });

  test('removeAlias removes alias from both fields', () async {
    await registry.addEntry(
      'book-a',
      CharacterRegistryEntry(
        canonicalName: 'Harry Potter',
        aliases: const {'Boy'},
        userOverrides: const {'Potter'},
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    await registry.removeAlias('book-a', 'Harry Potter', 'Boy');
    await registry.removeAlias('book-a', 'Harry Potter', 'Potter');

    final entries = registry.getAll('book-a');
    expect(entries.single.aliases, isNot(contains('Boy')));
    expect(entries.single.userOverrides, isNot(contains('Potter')));
  });

  test('removeEntry deletes entry by canonical name', () async {
    await registry.addEntry(
      'book-a',
      CharacterRegistryEntry(
        canonicalName: 'Ron',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.removeEntry('book-a', 'Ron');

    expect(registry.getAll('book-a'), isEmpty);
  });

  test('clearForBook removes all entries for a book', () async {
    await registry.addEntry(
      'book-x',
      CharacterRegistryEntry(
        canonicalName: 'Frodo',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.addEntry(
      'book-y',
      CharacterRegistryEntry(
        canonicalName: 'Gandalf',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );

    await registry.clearForBook('book-x');

    expect(registry.getAll('book-x'), isEmpty);
    expect(registry.getAll('book-y'), hasLength(1));
  });

  test('empty entries list removes box key', () async {
    await registry.addEntry(
      'book-z',
      CharacterRegistryEntry(
        canonicalName: 'Aragorn',
        updatedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await registry.removeEntry('book-z', 'Aragorn');

    final box = Hive.box<String>('character_registry');
    expect(box.get('book-z'), isNull);
  });
}
