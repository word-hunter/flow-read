import 'dart:io';

import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initHiveTestStorage('flow_read_storage_services_test_');
    await openFlowReadTestBoxes();
  });

  tearDown(() async {
    await disposeHiveTestStorage(tempDir);
  });

  test('user vocabulary persists normalized word status', () async {
    final service = UserVocabularyService();
    await service.init();

    await service.setKnown(' Flow ');
    await service.setLearning('Migrating');

    expect(service.getStatus('flow'), UserWordStatus.known);
    expect(service.getStatus(' migrating '), UserWordStatus.learning);
    expect(service.knownWords, contains('flow'));
    expect(service.learningWords, contains('migrating'));

    await service.setUnknown('FLOW');

    expect(service.getStatus('flow'), isNull);
  });

  test('reading config persists clamped display settings', () async {
    final service = ReadingConfigService();
    await service.init();

    await service.setFontSize(30);
    await service.setLineHeight(1);
    await service.setFontFamily('Sans');
    await service.setTheme('sepia');

    final reloaded = ReadingConfigService();
    await reloaded.init();

    expect(reloaded.fontSize, 24);
    expect(reloaded.lineHeight, 1.4);
    expect(reloaded.fontFamily, 'Sans');
    expect(reloaded.theme, 'sepia');
  });

  test('reading time accumulates global and per-book seconds', () async {
    var now = DateTime.utc(2026, 5, 19, 8);
    final service = ReadingTimeService(clock: () => now);
    await service.init();

    service.start('book-1');
    now = now.add(const Duration(seconds: 125));
    await service.stop();

    expect(service.totalSeconds, 125);
    expect(service.secondsForBook('book-1'), 125);
    expect(service.displayText, '2 分钟');

    final reloaded = ReadingTimeService(clock: () => now);
    await reloaded.init();

    expect(reloaded.totalSeconds, 125);
    expect(reloaded.secondsForBook('book-1'), 125);
  });

  test('word context examples are merged and deduplicated', () async {
    final service = WordContextService();
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

    final reloaded = WordContextService();
    await reloaded.init();
    final examples = reloaded.examplesFor('flow');

    expect(examples, hasLength(1));
    expect(examples.single.title, 'Book');
  });
}
