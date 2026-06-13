import 'dart:convert';

import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/services/wordhunter_import_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_user_vocabulary_repository.dart';
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

  test('imports Word Hunter vocabulary and examples into Drift', () async {
    final vocabulary = UserVocabularyService(
      repository: DriftUserVocabularyRepository(
        db.userVocabularyDao,
        languageCode: 'en',
      ),
      languageCode: 'en',
    );
    final contexts = WordContextService(
      repository: DriftWordContextRepository(
        db.wordContextDao,
        languageCode: 'en',
      ),
    );
    await vocabulary.init();
    await contexts.init();
    await vocabulary.setKnown('agenda');
    await contexts.saveExamples(
      'agenda',
      const [
        WordContextExample(word: 'agenda', text: 'Existing example.'),
      ],
      merge: false,
    );

    final service = WordHunterImportService(
      vocabularyService: vocabulary,
      wordContextService: contexts,
    );

    final result = await service.importPayload({
      'known': {'Flow': 'o', 'the': 'o'},
      'learning': ['migrate'],
      'context': {
        'Agenda': [
          {
            'word': 'Agenda',
            'text': 'Let us see what is on the agenda today.',
            'title': 'Sapiens',
            'url': 'file:///book',
            'timestamp': 1696336821349,
          },
        ],
        'Partition': [
          {'text': 'function partition(nums, l, r) {', 'title': 'LeetCode'},
        ],
      },
    });

    expect(result.knownCount, 2);
    expect(result.learningCount, 2);
    expect(result.exampleCount, 2);

    final words = await db.userVocabularyDao.allWords('en');
    expect(words['flow'], 'known');
    expect(words['the'], 'known');
    expect(words['agenda'], 'known');
    expect(words['migrate'], 'learning');
    expect(words['partition'], 'learning');

    final agendaExamples =
        jsonDecode((await db.wordContextDao.dataFor('agenda', 'en'))!)
            as List<dynamic>;
    expect(agendaExamples, hasLength(2));
    expect(
      agendaExamples.last['text'],
      'Let us see what is on the agenda today.',
    );
    expect(agendaExamples.last['title'], 'Sapiens');

    final partitionExamples =
        jsonDecode((await db.wordContextDao.dataFor('partition', 'en'))!)
            as List<dynamic>;
    expect(
      partitionExamples.single['text'],
      'function partition(nums, l, r) {',
    );
  });
}
