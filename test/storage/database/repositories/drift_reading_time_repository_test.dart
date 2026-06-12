import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/storage/database/app_database.dart';
import 'package:flow_read/storage/database/repositories/drift_reading_time_repository.dart';
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
    final repo = DriftReadingTimeRepository(
      db.readingTimeDao,
      languageCode: 'en',
      initialValues: const {
        ReadingTimeService.globalStorageKey: 90,
        'book-1': 30,
      },
    );

    expect(repo.secondsFor(ReadingTimeService.globalStorageKey), 90);
    expect(repo.secondsFor('book-1'), 30);
  });

  test('persists and reloads reading time from Drift', () async {
    final repo = DriftReadingTimeRepository(
      db.readingTimeDao,
      languageCode: 'en',
    );
    await repo.init();

    await repo.putSeconds(ReadingTimeService.globalStorageKey, 120);
    await repo.putSeconds('book-1', 45);

    expect(repo.secondsFor(ReadingTimeService.globalStorageKey), 120);
    expect(repo.secondsFor('book-1'), 45);

    final reloaded = DriftReadingTimeRepository(
      db.readingTimeDao,
      languageCode: 'en',
    );
    await reloaded.init();

    expect(reloaded.secondsFor(ReadingTimeService.globalStorageKey), 120);
    expect(reloaded.secondsFor('book-1'), 45);
  });

  test(
    'reading time service preserves bootstrapped total while recording',
    () async {
      var now = DateTime.utc(2026, 6, 12, 8);
      final repo = DriftReadingTimeRepository(
        db.readingTimeDao,
        languageCode: 'en',
        initialValues: const {
          ReadingTimeService.globalStorageKey: 120,
        },
      );
      final service = ReadingTimeService(
        repository: repo,
        clock: () => now,
        initialTotalSeconds: 120,
      );

      expect(service.totalSeconds, 120);
      expect(service.displayText, '2 分钟');

      service.start('book-1', 0);
      now = now.add(const Duration(seconds: 60));
      await service.stop();

      expect(service.totalSeconds, 180);
      expect(repo.secondsFor(ReadingTimeService.globalStorageKey), 180);
      expect(repo.secondsFor('book-1'), 60);

      final reloaded = DriftReadingTimeRepository(
        db.readingTimeDao,
        languageCode: 'en',
      );
      await reloaded.init();

      expect(reloaded.secondsFor(ReadingTimeService.globalStorageKey), 180);
      expect(reloaded.secondsFor('book-1'), 60);
    },
  );
}
