import 'dart:convert';

import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_word_context_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test('serves bootstrapped values before async init', () {
    final repo = DriftWordContextRepository(
      db.wordContextDao,
      languageCode: 'en',
      initialValues: {
        'flow': jsonEncode([
          const WordContextExample(
            word: 'flow',
            text: 'A steady flow of ideas.',
            title: 'Book',
            url: 'file:///book',
          ).toJson(),
        ]),
      },
    );
    final service = WordContextService(repository: repo);

    expect(service.examplesFor('flow').single.title, 'Book');
  });

  test('persists and reloads word contexts from Drift', () async {
    final service = WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    );
    await service.init();

    await service.saveExamples(' Flow ', const [
      WordContextExample(
        word: 'flow',
        text: 'A steady flow of ideas.',
        title: 'Book',
        url: 'file:///book',
      ),
      WordContextExample(
        word: 'flow',
        text: 'A steady flow of ideas.',
        title: 'Duplicate',
        url: 'file:///book',
      ),
    ]);

    expect(service.examplesFor('flow'), hasLength(1));

    final reloaded = WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    );
    await reloaded.init();

    final examples = reloaded.examplesFor('flow');
    expect(examples, hasLength(1));
    expect(examples.single.title, 'Book');
  });
}
