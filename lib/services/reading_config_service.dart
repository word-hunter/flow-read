import '../models/reader_font.dart';
import '../storage/repositories/reading_config_repository.dart';

class ReadingConfigService {
  ReadingConfigService({
    required ReadingConfigRepository repository,
    bool loadImmediately = false,
  }) : _repository = repository {
    if (loadImmediately) {
      _load();
    }
  }

  final ReadingConfigRepository _repository;
  Future<void>? _initFuture;
  bool _initialized = false;

  double fontSize = 16.0;
  String fontFamily = ReaderFonts.defaultFamily;
  double lineHeight = 2.0;
  String theme = 'light';

  static double normalizeFontSize(double value) {
    return value.clamp(12.0, 24.0).toDouble();
  }

  static double normalizeLineHeight(double value) {
    return value.clamp(1.4, 2.8).toDouble();
  }

  static String normalizeFontFamily(String value) {
    return ReaderFonts.normalizeFamily(value);
  }

  Future<void> init() {
    if (_initialized) return Future.value();
    final pending = _initFuture;
    if (pending != null) return pending;
    final future = _init();
    _initFuture = future;
    return future;
  }

  Future<void> _init() async {
    try {
      await _repository.init();
      _load();
      _initialized = true;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  void _load() {
    fontSize =
        double.tryParse(
          _repository.getString('fontSize', defaultValue: '16.0'),
        ) ??
        16.0;
    fontFamily = normalizeFontFamily(
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
    await init();
    fontSize = normalizeFontSize(value);
    await _repository.putString('fontSize', fontSize.toString());
  }

  Future<void> setFontFamily(String value) async {
    await init();
    fontFamily = normalizeFontFamily(value);
    await _repository.putString('fontFamily', fontFamily);
  }

  Future<void> setLineHeight(double value) async {
    await init();
    lineHeight = normalizeLineHeight(value);
    await _repository.putString('lineHeight', lineHeight.toString());
  }

  Future<void> setTheme(String value) async {
    await init();
    theme = value;
    await _repository.putString('theme', value);
  }

  Future<void> close() async {
    await _repository.close();
  }
}
