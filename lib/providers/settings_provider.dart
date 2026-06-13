import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../services/settings_service.dart';
import '../storage/database/dao/settings_dao.dart';
import '../storage/storage_bootstrap.dart';

final settingsProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final db = appDatabase;
  if (db == null) throw StateError('Database not initialized');
  final service = SettingsService(SettingsDao(db));
  unawaited(service.init());
  return service;
});
