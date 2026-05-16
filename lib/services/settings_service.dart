import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'ai_provider_config.dart';

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
  static const experimentalFeatureRss = 'rss';
  static const experimentalFeatureBrowser = 'browser';
  static const supportedExperimentalFeatureIds = <String>{
    experimentalFeatureRss,
    experimentalFeatureBrowser,
  };
  static const _enabledExperimentalFeaturesKey = 'enabledExperimentalFeatures';

  late Box _box;

  VocabularyColorSettings _colors = VocabularyColorSettings();
  String _aiProviderId = AIProviders.deepSeek.id;
  Map<String, String> _aiApiKeys = {};
  Map<String, String> _aiBaseUrls = {};
  Map<String, String> _aiModels = {};
  AIUsageStats _aiUsage = AIUsageStats();
  ThemeMode _themeMode = ThemeMode.system;
  bool _backupEnabled = false;
  bool _includeSecretsInBackup = false;
  String _backupFolderPath = '';
  int _backupIntervalMinutes = 60;
  DateTime? _lastBackupAt;
  String? _lastBackupPath;
  String _lastSeenReleaseNotesVersion = '';
  Set<String> _enabledExperimentalFeatures = {};

  VocabularyColorSettings get colors => _colors;
  String get aiProviderId => _aiProviderId;
  AIProviderDefinition get aiProvider => AIProviders.byId(_aiProviderId);
  List<AIProviderDefinition> get aiProviders => AIProviders.all;
  String get apiKey => apiKeyFor(_aiProviderId);
  String apiKeyFor(String providerId) => _aiApiKeys[providerId] ?? '';
  String aiBaseUrlFor(String providerId) =>
      _aiBaseUrls[providerId] ?? AIProviders.byId(providerId).defaultBaseUrl;
  String aiModelFor(String providerId) =>
      _aiModels[providerId] ?? AIProviders.byId(providerId).defaultModel;
  AIProviderConfig get aiProviderConfig => providerConfigFor(_aiProviderId);
  AIProviderConfig providerConfigFor(String providerId) {
    final provider = AIProviders.byId(providerId);
    return AIProviderConfig(
      definition: provider,
      apiKey: apiKeyFor(provider.id),
      baseUrl: aiBaseUrlFor(provider.id),
      model: aiModelFor(provider.id),
    );
  }

  AIUsageStats get aiUsage => _aiUsage;
  ThemeMode get themeMode => _themeMode;
  bool get backupEnabled => _backupEnabled;
  bool get includeSecretsInBackup => _includeSecretsInBackup;
  String get backupFolderPath => _backupFolderPath;
  int get backupIntervalMinutes => _backupIntervalMinutes;
  DateTime? get lastBackupAt => _lastBackupAt;
  String? get lastBackupPath => _lastBackupPath;
  String get lastSeenReleaseNotesVersion => _lastSeenReleaseNotesVersion;
  Set<String> get enabledExperimentalFeatures =>
      Set.unmodifiable(_enabledExperimentalFeatures);
  bool get rssFeatureEnabled =>
      isExperimentalFeatureEnabled(experimentalFeatureRss);
  bool get browserFeatureEnabled =>
      isExperimentalFeatureEnabled(experimentalFeatureBrowser);

  Future<void> init() async {
    _box = Hive.box('settings');
    _load();
  }

  Future<void> reloadFromStorage() async {
    _load();
    notifyListeners();
  }

  void _load() {
    _colors = VocabularyColorSettings(
      unknownColor: Color(_box.get('unknownColor', defaultValue: 0xFFE74C3C)),
      learningColor: Color(_box.get('learningColor', defaultValue: 0xFF8E44AD)),
      knownColor: Color(_box.get('knownColor', defaultValue: 0xFF999999)),
    );
    _aiProviderId =
        _box.get('aiProviderId', defaultValue: AIProviders.deepSeek.id)
            as String;
    _aiProviderId = AIProviders.byId(_aiProviderId).id;
    _aiApiKeys = _readStringMap('aiApiKeys');
    final legacyApiKey = _box.get('apiKey', defaultValue: '') as String;
    if (legacyApiKey.isNotEmpty &&
        (_aiApiKeys[AIProviders.deepSeek.id]?.isEmpty ?? true)) {
      _aiApiKeys[AIProviders.deepSeek.id] = legacyApiKey;
    }
    _aiBaseUrls = _readStringMap('aiBaseUrls');
    _aiModels = _readStringMap('aiModels');
    _aiUsage = AIUsageStats(
      chapterSummaryCount: _box.get('aiChapterSummaryCount', defaultValue: 0),
      textAnalysisCount: _box.get('aiTextAnalysisCount', defaultValue: 0),
      practiceCount: _box.get('aiPracticeCount', defaultValue: 0),
      wordAnalysisCount: _box.get('aiWordAnalysisCount', defaultValue: 0),
    );
    final themeModeIndex = _box.get('themeMode', defaultValue: 0) as int;
    _themeMode =
        ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
    _backupEnabled = _box.get('backupEnabled', defaultValue: false) as bool;
    _includeSecretsInBackup =
        _box.get('includeSecretsInBackup', defaultValue: false) as bool;
    _backupFolderPath =
        _box.get('backupFolderPath', defaultValue: '') as String;
    _backupIntervalMinutes =
        _box.get('backupIntervalMinutes', defaultValue: 60) as int;
    final lastBackupAtValue = _box.get('lastBackupAt') as String?;
    _lastBackupAt = lastBackupAtValue == null
        ? null
        : DateTime.tryParse(lastBackupAtValue);
    _lastBackupPath = _box.get('lastBackupPath') as String?;
    _lastSeenReleaseNotesVersion =
        _box.get('lastSeenReleaseNotesVersion', defaultValue: '') as String;
    _enabledExperimentalFeatures = _readStringSet(
      _enabledExperimentalFeaturesKey,
    );
  }

  Map<String, String> _readStringMap(String key) {
    final raw = _box.get(key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      } catch (_) {
        return {};
      }
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  Set<String> _readStringSet(String key) {
    final raw = _box.get(key);
    Object? decoded = raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return {};
      }
    }
    if (decoded is Iterable) {
      return decoded
          .map((value) => value.toString())
          .where(supportedExperimentalFeatureIds.contains)
          .toSet();
    }
    if (decoded is Map) {
      return decoded.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .where(supportedExperimentalFeatureIds.contains)
          .toSet();
    }
    return {};
  }

  Future<void> _writeStringMap(String key, Map<String, String> value) async {
    await _box.put(key, jsonEncode(value));
  }

  Future<void> _writeStringSet(String key, Set<String> value) async {
    final sorted = value.toList()..sort();
    await _box.put(key, jsonEncode(sorted));
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

  Future<void> setAIProvider(String providerId) async {
    _aiProviderId = AIProviders.byId(providerId).id;
    await _box.put('aiProviderId', _aiProviderId);
    notifyListeners();
  }

  Future<void> setApiKey(String key, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiApiKeys = {..._aiApiKeys, id: key};
    await _writeStringMap('aiApiKeys', _aiApiKeys);
    if (id == AIProviders.deepSeek.id) {
      await _box.put('apiKey', key);
    }
    notifyListeners();
  }

  Future<void> setAIBaseUrl(String baseUrl, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiBaseUrls = {..._aiBaseUrls, id: baseUrl};
    await _writeStringMap('aiBaseUrls', _aiBaseUrls);
    notifyListeners();
  }

  Future<void> setAIModel(String model, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiModels = {..._aiModels, id: model};
    await _writeStringMap('aiModels', _aiModels);
    notifyListeners();
  }

  Future<void> setBackupEnabled(bool enabled) async {
    _backupEnabled = enabled;
    await _box.put('backupEnabled', enabled);
    notifyListeners();
  }

  Future<void> setIncludeSecretsInBackup(bool enabled) async {
    _includeSecretsInBackup = enabled;
    await _box.put('includeSecretsInBackup', enabled);
    notifyListeners();
  }

  Future<void> setBackupFolderPath(String path) async {
    _backupFolderPath = path;
    await _box.put('backupFolderPath', path);
    notifyListeners();
  }

  Future<void> setBackupIntervalMinutes(int minutes) async {
    _backupIntervalMinutes = minutes.clamp(15, 60 * 24 * 7).toInt();
    await _box.put('backupIntervalMinutes', _backupIntervalMinutes);
    notifyListeners();
  }

  Future<void> setLastBackup(DateTime at, String path) async {
    _lastBackupAt = at;
    _lastBackupPath = path;
    await _box.put('lastBackupAt', at.toIso8601String());
    await _box.put('lastBackupPath', path);
    notifyListeners();
  }

  bool shouldShowReleaseNotes(String version) {
    return _lastSeenReleaseNotesVersion != version;
  }

  Future<void> markReleaseNotesSeen(String version) async {
    _lastSeenReleaseNotesVersion = version;
    await _box.put('lastSeenReleaseNotesVersion', version);
    notifyListeners();
  }

  bool isExperimentalFeatureEnabled(String featureId) {
    return _enabledExperimentalFeatures.contains(featureId);
  }

  Future<void> setExperimentalFeatureEnabled(
    String featureId,
    bool enabled,
  ) async {
    if (!supportedExperimentalFeatureIds.contains(featureId)) {
      throw ArgumentError.value(
        featureId,
        'featureId',
        'Unsupported experimental feature',
      );
    }
    final next = {..._enabledExperimentalFeatures};
    if (enabled) {
      next.add(featureId);
    } else {
      next.remove(featureId);
    }
    _enabledExperimentalFeatures = next;
    await _writeStringSet(
      _enabledExperimentalFeaturesKey,
      _enabledExperimentalFeatures,
    );
    notifyListeners();
  }

  Future<void> setRssFeatureEnabled(bool enabled) {
    return setExperimentalFeatureEnabled(experimentalFeatureRss, enabled);
  }

  Future<void> setBrowserFeatureEnabled(bool enabled) {
    return setExperimentalFeatureEnabled(experimentalFeatureBrowser, enabled);
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
