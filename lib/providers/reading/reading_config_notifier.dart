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
  ReadingConfigService get _config => ref.read(readingConfigServiceProvider);

  @override
  ReadingConfigState build() {
    final initial = _config;
    return ReadingConfigState(
      fontSize: initial.fontSize,
      fontFamily: initial.fontFamily,
      lineHeight: initial.lineHeight,
      readingTheme: initial.theme,
    );
  }

  void setFontSize(double size) {
    _config.setFontSize(size);
    state = state.copyWith(fontSize: size);
  }

  void setFontFamily(String family) {
    _config.setFontFamily(family);
    state = state.copyWith(fontFamily: family);
  }

  void setLineHeight(double height) {
    _config.setLineHeight(height);
    state = state.copyWith(lineHeight: height);
  }

  void setReadingTheme(String theme) {
    _config.setTheme(theme);
    state = state.copyWith(readingTheme: theme);
  }

  void restoreDefaults() {
    setFontSize(16);
    setLineHeight(2.0);
    setFontFamily(ReaderFonts.defaultFamily);
    setReadingTheme('light');
  }
}

final readingConfigNotifierProvider =
    NotifierProvider<ReadingConfigNotifier, ReadingConfigState>(
  ReadingConfigNotifier.new,
);
