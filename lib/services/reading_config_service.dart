import '../models/reader_font.dart';
import '../storage/repositories/reading_config_repository.dart';

class ReadingConfigService {
  ReadingConfigService({ReadingConfigRepository? repository})
    : _repository = repository ?? HiveReadingConfigRepository();

  final ReadingConfigRepository _repository;

  double fontSize = 16.0;
  String fontFamily = ReaderFonts.defaultFamily;
  double lineHeight = 2.0;
  String theme = 'light';

  Future<void> init() async {
    await _repository.init();
    _load();
  }

  void _load() {
    fontSize =
        double.tryParse(
          _repository.getString('fontSize', defaultValue: '16.0'),
        ) ??
        16.0;
    fontFamily = ReaderFonts.normalizeFamily(
      _repository.getString(
        'fontFamily',
        defaultValue: ReaderFonts.defaultFamily,
      ),
    );
    lineHeight =
        double.tryParse(
          _repository.getString('lineHeight', defaultValue: '2.0'),
        ) ??
        2.0;
    theme = _repository.getString('theme', defaultValue: 'light');
  }

  Future<void> setFontSize(double value) async {
    fontSize = value.clamp(12.0, 24.0);
    await _repository.putString('fontSize', fontSize.toString());
  }

  Future<void> setFontFamily(String value) async {
    fontFamily = ReaderFonts.normalizeFamily(value);
    await _repository.putString('fontFamily', fontFamily);
  }

  Future<void> setLineHeight(double value) async {
    lineHeight = value.clamp(1.4, 2.8);
    await _repository.putString('lineHeight', lineHeight.toString());
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await _repository.putString('theme', value);
  }

  Future<void> close() async {
    await _repository.close();
  }
}
