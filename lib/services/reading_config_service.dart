import 'package:hive/hive.dart';

import '../storage/hive_box_names.dart';

class ReadingConfigService {
  late Box<String> _box;

  double fontSize = 16.0;
  String fontFamily = 'Serif';
  double lineHeight = 2.0;
  String theme = 'light';

  Future<void> init() async {
    _box = Hive.box<String>(HiveBoxNames.readingConfig);
    _load();
  }

  void _load() {
    fontSize =
        double.tryParse(_box.get('fontSize', defaultValue: '16.0')!) ?? 16.0;
    fontFamily = _box.get('fontFamily', defaultValue: 'Serif')!;
    lineHeight =
        double.tryParse(_box.get('lineHeight', defaultValue: '2.0')!) ?? 2.0;
    theme = _box.get('theme', defaultValue: 'light')!;
  }

  Future<void> setFontSize(double value) async {
    fontSize = value.clamp(12.0, 24.0);
    await _box.put('fontSize', fontSize.toString());
  }

  Future<void> setFontFamily(String value) async {
    fontFamily = value;
    await _box.put('fontFamily', value);
  }

  Future<void> setLineHeight(double value) async {
    lineHeight = value.clamp(1.4, 2.8);
    await _box.put('lineHeight', lineHeight.toString());
  }

  Future<void> setTheme(String value) async {
    theme = value;
    await _box.put('theme', value);
  }

  Future<void> close() async {
    await _box.close();
  }
}
