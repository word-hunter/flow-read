import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_word_level_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'imports built-in word levels into Drift and reuses persisted data',
    () async {
      var importCount = 0;
      final service = WordLevelService(
        repository: DriftWordLevelRepository(db.wordLevelDao, db.settingsDao),
        assetLoader: (_) async {
          importCount += 1;
          return 'flow\tflow\t4\nideas\tidea\t6\n';
        },
      );

      await service.init();

      expect(service.getLevel('flow'), LevelKey.cet4);
      expect(service.getOriginForm('ideas'), 'idea');
      expect(importCount, 1);
      expect(await db.settingsDao.valueFor('word_levels_imported'), 'true');

      final reloaded = WordLevelService(
        repository: DriftWordLevelRepository(db.wordLevelDao, db.settingsDao),
        assetLoader: (_) async {
          throw StateError('should not import again');
        },
      );
      await reloaded.init();

      expect(reloaded.getLevel('ideas'), LevelKey.cet6);
      expect(reloaded.wordCount, 3);
    },
  );
}
