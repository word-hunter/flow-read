import 'dart:io';

import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_reading_provider_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('marking a word known emits a mastery celebration event once', () async {
    final userVocabulary = UserVocabularyService();
    await userVocabulary.init();
    final provider = ReadingProvider()..setUserVocabulary(userVocabulary);
    addTearDown(provider.dispose);

    expect(provider.wordMasteredCelebrationTick, 0);
    expect(provider.wordMasteredCelebrationWord, isNull);

    const firstOrigin = Offset(12, 34);
    await provider.markWordKnown(' Flow ', celebrationOrigin: firstOrigin);

    expect(userVocabulary.getStatus('flow'), UserWordStatus.known);
    expect(provider.wordMasteredCelebrationTick, 1);
    expect(provider.wordMasteredCelebrationWord, 'flow');
    expect(provider.wordMasteredCelebrationOrigin, firstOrigin);

    await provider.markWordKnown('flow');

    expect(provider.wordMasteredCelebrationTick, 1);
    expect(provider.wordMasteredCelebrationOrigin, firstOrigin);

    await provider.markWordLearning('flow');
    const secondOrigin = Offset(56, 78);
    await provider.markWordKnown('flow', celebrationOrigin: secondOrigin);

    expect(provider.wordMasteredCelebrationTick, 2);
    expect(provider.wordMasteredCelebrationWord, 'flow');
    expect(provider.wordMasteredCelebrationOrigin, secondOrigin);
  });
}
