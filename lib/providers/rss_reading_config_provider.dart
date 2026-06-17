import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_font.dart';
import '../services/reading_config_service.dart';
import 'reading/reading_config_notifier.dart';
import 'reading/services_provider.dart';

class RssReadingConfigNotifier extends Notifier<ReadingConfigState> {
  int _mutationGeneration = 0;

  ReadingConfigService get _config => ref.read(rssReadingConfigServiceProvider);

  @override
  ReadingConfigState build() {
    final config = _config;
    unawaited(_refreshFromStorage(config, _mutationGeneration));
    return _stateFrom(config);
  }

  ReadingConfigState _stateFrom(ReadingConfigService config) {
    return ReadingConfigState(
      fontSize: config.fontSize,
      fontFamily: config.fontFamily,
      lineHeight: config.lineHeight,
      readingTheme: config.theme,
    );
  }

  Future<void> _refreshFromStorage(
    ReadingConfigService config,
    int generation,
  ) async {
    await config.init();
    if (!ref.mounted || generation != _mutationGeneration) return;
    state = _stateFrom(config);
  }

  void setFontSize(double size) {
    _mutationGeneration++;
    state = state.copyWith(
      fontSize: ReadingConfigService.normalizeFontSize(size),
    );
    unawaited(_config.setFontSize(size));
  }

  void setFontFamily(String family) {
    _mutationGeneration++;
    state = state.copyWith(
      fontFamily: ReadingConfigService.normalizeFontFamily(family),
    );
    unawaited(_config.setFontFamily(family));
  }

  void setLineHeight(double height) {
    _mutationGeneration++;
    state = state.copyWith(
      lineHeight: ReadingConfigService.normalizeLineHeight(height),
    );
    unawaited(_config.setLineHeight(height));
  }

  void setReadingTheme(String theme) {
    _mutationGeneration++;
    state = state.copyWith(readingTheme: theme);
    unawaited(_config.setTheme(theme));
  }

  void restoreDefaults() {
    _mutationGeneration++;
    state = const ReadingConfigState(
      fontSize: 16,
      fontFamily: ReaderFonts.defaultFamily,
      lineHeight: 2.0,
      readingTheme: 'light',
    );
    unawaited(
      Future.wait([
        _config.setFontSize(16),
        _config.setLineHeight(2.0),
        _config.setFontFamily(ReaderFonts.defaultFamily),
        _config.setTheme('light'),
      ]),
    );
  }
}

final rssReadingConfigNotifierProvider =
    NotifierProvider<RssReadingConfigNotifier, ReadingConfigState>(
      RssReadingConfigNotifier.new,
    );
