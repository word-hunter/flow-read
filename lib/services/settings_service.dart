import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AIUsageStats {
  int chapterSummaryCount;
  int textAnalysisCount;
  int practiceCount;
  int wordAnalysisCount;

  AIUsageStats({
    this.chapterSummaryCount = 0,
    this.textAnalysisCount = 0,
    this.practiceCount = 0,
    this.wordAnalysisCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'chapterSummaryCount': chapterSummaryCount,
    'textAnalysisCount': textAnalysisCount,
    'practiceCount': practiceCount,
    'wordAnalysisCount': wordAnalysisCount,
  };

  factory AIUsageStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AIUsageStats();
    return AIUsageStats(
      chapterSummaryCount: json['chapterSummaryCount'] as int? ?? 0,
      textAnalysisCount: json['textAnalysisCount'] as int? ?? 0,
      practiceCount: json['practiceCount'] as int? ?? 0,
      wordAnalysisCount: json['wordAnalysisCount'] as int? ?? 0,
    );
  }

  int get totalCalls =>
      chapterSummaryCount +
      textAnalysisCount +
      practiceCount +
      wordAnalysisCount;
}

class VocabularyColorSettings {
  Color unknownColor;
  Color learningColor;
  Color knownColor;

  VocabularyColorSettings({
    this.unknownColor = const Color(0xFFE74C3C),
    this.learningColor = const Color(0xFF8E44AD),
    this.knownColor = const Color(0xFF999999),
  });

  Map<String, dynamic> toJson() => {
    'unknownColor': unknownColor.toARGB32(),
    'learningColor': learningColor.toARGB32(),
    'knownColor': knownColor.toARGB32(),
  };

  factory VocabularyColorSettings.fromJson(Map<String, dynamic> json) {
    return VocabularyColorSettings(
      unknownColor: Color(json['unknownColor'] as int? ?? 0xFFE74C3C),
      learningColor: Color(json['learningColor'] as int? ?? 0xFF8E44AD),
      knownColor: Color(json['knownColor'] as int? ?? 0xFF999999),
    );
  }
}

class SettingsService extends ChangeNotifier {
  late Box _box;

  VocabularyColorSettings _colors = VocabularyColorSettings();
  String _apiKey = '';
  AIUsageStats _aiUsage = AIUsageStats();
  ThemeMode _themeMode = ThemeMode.system;

  VocabularyColorSettings get colors => _colors;
  String get apiKey => _apiKey;
  AIUsageStats get aiUsage => _aiUsage;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    _box = Hive.box('settings');
    _load();
  }

  void _load() {
    _colors = VocabularyColorSettings(
      unknownColor: Color(_box.get('unknownColor', defaultValue: 0xFFE74C3C)),
      learningColor: Color(_box.get('learningColor', defaultValue: 0xFF8E44AD)),
      knownColor: Color(_box.get('knownColor', defaultValue: 0xFF999999)),
    );
    _apiKey = _box.get('apiKey', defaultValue: '') as String;
    _aiUsage = AIUsageStats(
      chapterSummaryCount: _box.get('aiChapterSummaryCount', defaultValue: 0),
      textAnalysisCount: _box.get('aiTextAnalysisCount', defaultValue: 0),
      practiceCount: _box.get('aiPracticeCount', defaultValue: 0),
      wordAnalysisCount: _box.get('aiWordAnalysisCount', defaultValue: 0),
    );
    final themeModeIndex = _box.get('themeMode', defaultValue: 0) as int;
    _themeMode =
        ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box.put('themeMode', mode.index);
    notifyListeners();
  }

  void toggleThemeMode() {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(next);
  }

  Future<void> setUnknownColor(Color color) async {
    _colors.unknownColor = color;
    await _box.put('unknownColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setLearningColor(Color color) async {
    _colors.learningColor = color;
    await _box.put('learningColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setKnownColor(Color color) async {
    _colors.knownColor = color;
    await _box.put('knownColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    await _box.put('apiKey', key);
    notifyListeners();
  }

  Future<void> incrementAIUsage({
    bool chapterSummary = false,
    bool textAnalysis = false,
    bool practice = false,
    bool wordAnalysis = false,
  }) async {
    if (chapterSummary) {
      _aiUsage.chapterSummaryCount++;
      await _box.put('aiChapterSummaryCount', _aiUsage.chapterSummaryCount);
    }
    if (textAnalysis) {
      _aiUsage.textAnalysisCount++;
      await _box.put('aiTextAnalysisCount', _aiUsage.textAnalysisCount);
    }
    if (practice) {
      _aiUsage.practiceCount++;
      await _box.put('aiPracticeCount', _aiUsage.practiceCount);
    }
    if (wordAnalysis) {
      _aiUsage.wordAnalysisCount++;
      await _box.put('aiWordAnalysisCount', _aiUsage.wordAnalysisCount);
    }
    notifyListeners();
  }

  Future<void> clearAIUsage() async {
    _aiUsage = AIUsageStats();
    await _box.put('aiChapterSummaryCount', 0);
    await _box.put('aiTextAnalysisCount', 0);
    await _box.put('aiPracticeCount', 0);
    await _box.put('aiWordAnalysisCount', 0);
    notifyListeners();
  }

  Future<void> close() async {
    await _box.close();
  }
}
