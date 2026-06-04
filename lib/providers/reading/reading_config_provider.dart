import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reader_font.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class ReadingConfigController {
  const ReadingConfigController(this._reader);

  final ReadingProvider _reader;

  double get fontSize => _reader.fontSize;
  String get fontFamily => _reader.fontFamily;
  double get lineHeight => _reader.lineHeight;
  String get readingTheme => _reader.readingTheme;

  void setFontSize(double size) => _reader.setFontSize(size);
  void setFontFamily(String family) => _reader.setFontFamily(family);
  void setLineHeight(double height) => _reader.setLineHeight(height);
  void setReadingTheme(String theme) => _reader.setReadingTheme(theme);

  void restoreDefaults() {
    setFontSize(16);
    setLineHeight(2.0);
    setFontFamily(ReaderFonts.defaultFamily);
    setReadingTheme('light');
  }
}

final readingConfigProvider = Provider<ReadingConfigController>((ref) {
  return ReadingConfigController(ref.watch(readingProvider));
});
