import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';
import 'settings_provider.dart';

final backupProvider = ChangeNotifierProvider<BackupService>((ref) {
  final settings = ref.read(settingsProvider);
  final service = BackupService(settings);
  unawaited(service.init());
  return service;
});

final backupEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    settingsProvider.select((settings) => settings.backupEnabled),
  );
});
