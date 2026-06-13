import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/backup_service.dart';
import '../services/user_vocabulary_service.dart';
import '../services/word_context_service.dart';
import '../services/wordhunter_import_service.dart';
import '../storage/database/repositories/drift_user_vocabulary_repository.dart';
import '../storage/database/repositories/drift_word_context_repository.dart';
import '../storage/hive_storage.dart';
import 'settings_provider.dart';

final backupProvider = ChangeNotifierProvider<BackupService>((ref) {
  final settings = ref.read(settingsProvider);
  final db = appDatabase;
  if (db == null) {
    throw StateError(
      'AppDatabase must be initialized by bootstrapStorage() before reading '
      'backupProvider.',
    );
  }
  final service = BackupService(
    settings,
    database: db,
    wordHunterImportServiceFactory: () {
      final languageCode = settings.activeSourceLanguage;
      return WordHunterImportService(
        vocabularyService: UserVocabularyService(
          repository: DriftUserVocabularyRepository(
            db.userVocabularyDao,
            languageCode: languageCode,
          ),
          languageCode: languageCode,
        ),
        wordContextService: WordContextService(
          repository: DriftWordContextRepository(
            db.wordContextDao,
            languageCode: languageCode,
          ),
        ),
      );
    },
  );
  unawaited(service.init());
  return service;
});

final backupEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    settingsProvider.select((settings) => settings.backupEnabled),
  );
});
