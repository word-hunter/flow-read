import 'language_module.dart';

class LanguageRegistry {
  static final LanguageRegistry instance = LanguageRegistry._();

  final Map<String, LanguageModule> _modules = {};

  LanguageRegistry._();

  void register(LanguageModule module) {
    _modules[module.languageCode] = module;
  }

  List<LanguageModule> get modules {
    final values = _modules.values.toList()
      ..sort((a, b) => a.languageCode.compareTo(b.languageCode));
    return List.unmodifiable(values);
  }

  LanguageModule? get(String code) => _modules[code];

  LanguageModule? get defaultModule => _modules['en'];

  static String? normalizeLanguageCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final code = raw.trim().toLowerCase();
    final primary = code.contains('-') ? code.split('-').first : code;
    const aliases = {
      'eng': 'en',
      'jpn': 'ja',
      'jp': 'ja',
      'chi': 'zh',
      'zho': 'zh',
    };
    return aliases[primary] ?? (primary.length == 2 ? primary : null);
  }
}
