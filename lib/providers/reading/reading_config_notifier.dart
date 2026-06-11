import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reader_font.dart';
import '../../services/reading_config_service.dart';
import 'services_provider.dart';

@immutable
class ReadingConfigState {
  const ReadingConfigState({
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.readingTheme,
  });

  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final String readingTheme;

  ReadingConfigState copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    String? readingTheme,
  }) {
    return ReadingConfigState(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      readingTheme: readingTheme ?? this.readingTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingConfigState &&
        other.fontSize == fontSize &&
        other.fontFamily == fontFamily &&
        other.lineHeight == lineHeight &&
        other.readingTheme == readingTheme;
  }

  @override
  int get hashCode =>
      Object.hash(fontSize, fontFamily, lineHeight, readingTheme);
}

class ReadingConfigNotifier extends Notifier<ReadingConfigState> {
  int _mutationGeneration = 0;

  ReadingConfigService get _config => ref.read(readingConfigServiceProvider);

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

final readingConfigNotifierProvider =
    NotifierProvider<ReadingConfigNotifier, ReadingConfigState>(
      ReadingConfigNotifier.new,
    );
