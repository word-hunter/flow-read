import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

final settingsProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final service = SettingsService();
  unawaited(service.init());
  return service;
});
