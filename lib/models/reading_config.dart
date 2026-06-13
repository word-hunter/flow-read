import 'reader_font.dart';

class ReadingConfig {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final String theme;

  const ReadingConfig({
    this.fontSize = 16.0,
    this.fontFamily = ReaderFonts.defaultFamily,
    this.lineHeight = 2.0,
    this.theme = 'light',
  });

  ReadingConfig copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    String? theme,
  }) {
    return ReadingConfig(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
    );
  }
}
