import 'package:hive/hive.dart';

import 'reader_font.dart';

part 'reading_config.g.dart';

@HiveType(typeId: 3)
class ReadingConfig {
  @HiveField(0)
  final double fontSize;

  @HiveField(1)
  final String fontFamily;

  @HiveField(2)
  final double lineHeight;

  @HiveField(3)
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
