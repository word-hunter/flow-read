import 'dart:io';

import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/providers/reading/reading_config_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/storage/database/dao/reading_config_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_config_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await initTestStorage('flow_read_reading_config_test_');
    await openFlowReadTestStorage();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  test(
    'notifier restores migrated Drift reading settings after app restart',
    () async {
      final db = await createTestAppDatabase();
      final dao = ReadingConfigDao(db);
      await dao.putValue('fontSize', 'en', '21');
      await dao.putValue('fontFamily', 'en', ReaderFonts.literata);
      await dao.putValue('lineHeight', 'en', '2.4');
      await dao.putValue('theme', 'en', 'dark');

      final service = ReadingConfigService(
        repository: DriftReadingConfigRepository(dao, languageCode: 'en'),
      );
      final container = ProviderContainer(
        overrides: [readingConfigServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      container.read(readingConfigNotifierProvider);
      final state = await _waitForReadingConfig(
        container,
        (state) => state.fontSize == 21,
      );

      expect(state.fontSize, 21);
      expect(state.fontFamily, ReaderFonts.literata);
      expect(state.lineHeight, 2.4);
      expect(state.readingTheme, 'dark');
    },
  );

  test(
    'service writes updated reading settings to Drift storage',
    () async {
      final db = await createTestAppDatabase();
      final dao = ReadingConfigDao(db);
      await dao.putValue('fontSize', 'en', '21');

      final service = ReadingConfigService(
        repository: DriftReadingConfigRepository(dao, languageCode: 'en'),
      );
      await service.init();
      await service.setFontSize(20);

      expect(await dao.valueFor('fontSize', 'en'), '20.0');
    },
  );
}

Future<ReadingConfigState> _waitForReadingConfig(
  ProviderContainer container,
  bool Function(ReadingConfigState state) predicate,
) async {
  for (var i = 0; i < 30; i++) {
    final state = container.read(readingConfigNotifierProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return container.read(readingConfigNotifierProvider);
}
