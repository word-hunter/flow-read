import 'dart:convert';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide CharacterRegistryEntry;
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('serves bootstrapped character entries and persists updates', () async {
    final registry = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(
        db.characterRegistryDao,
        initialValues: {
          'book-1': jsonEncode([
            CharacterRegistryEntry(
              canonicalName: 'Eddard Stark',
              aliases: const {'Ned'},
              updatedAt: DateTime.utc(2026, 6, 13),
            ).toJson(),
          ]),
        },
      ),
    );

    expect(registry.matchCanonical('book-1', 'Ned'), 'Eddard Stark');

    await registry.addAlias('book-1', 'Eddard Stark', 'Lord Stark');
    await registry.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Arya Stark',
        aliases: const {'Arya'},
        updatedAt: DateTime.utc(2026, 6, 13),
      ),
    );

    final reloaded = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await reloaded.init();

    expect(reloaded.matchCanonical('book-1', 'Lord Stark'), 'Eddard Stark');
    expect(reloaded.matchCanonical('book-1', 'Arya'), 'Arya Stark');

    await reloaded.clearForBook('book-1');

    final cleared = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await cleared.init();

    expect(cleared.getAll('book-1'), isEmpty);
  });
}
