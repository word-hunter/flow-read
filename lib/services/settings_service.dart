import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../storage/hive_box_names.dart';
import '../theme/app_theme.dart';
import 'ai_provider_config.dart';
import 'dictionary/dictionary_source_config.dart';

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
  static const defaultDailyReadingGoalMinutes = 60;
  static const minDailyReadingGoalMinutes = 15;
  static const maxDailyReadingGoalMinutes = 240;
  static const dailyReadingGoalStepMinutes = 15;
  static const defaultBackupIntervalMinutes = 1440;
  static const experimentalFeatureRss = 'rss';
  static const experimentalFeatureReview = 'review';
  static const experimentalFeatureV2 = 'v2';
  static const supportedExperimentalFeatureIds = <String>{
    experimentalFeatureRss,
    experimentalFeatureReview,
    experimentalFeatureV2,
  };
  static const _dailyReadingGoalMinutesKey = 'dailyReadingGoalMinutes';
  static const _enabledExperimentalFeaturesKey = 'enabledExperimentalFeatures';
  static const _dictionarySourcesKey = 'dictionarySources';
  static const _activeSourceLanguageKey = HiveBoxNames.activeSourceLanguageKey;
  static const _targetExplanationLanguageKey = 'target_explanation_language';
  static const _themeModeCycle = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  late Box _box;

  VocabularyColorSettings _colors = VocabularyColorSettings();
  String _aiProviderId = AIProviders.deepSeek.id;
  Map<String, String> _aiApiKeys = {};
  Map<String, String> _aiBaseUrls = {};
  Map<String, String> _aiModels = {};
  AIUsageStats _aiUsage = AIUsageStats();
  AppThemeId _appThemeId = AppThemeId.classic;
  ThemeMode _themeMode = ThemeMode.system;
  int _dailyReadingGoalMinutes = defaultDailyReadingGoalMinutes;
  bool _backupEnabled = false;
  bool _includeSecretsInBackup = false;
  String _backupFolderPath = '';
  String _backupFolderBookmark = '';
  int _backupIntervalMinutes = defaultBackupIntervalMinutes;
  DateTime? _lastBackupAt;
  String? _lastBackupPath;
  String _lastSeenReleaseNotesVersion = '';
  String _activeSourceLanguage = 'en';
  String _targetExplanationLanguage = 'zh';
  Set<String> _enabledExperimentalFeatures = {};
  List<DictionarySourceConfig> _dictionarySources =
      DictionarySourceConfig.defaults;

  VocabularyColorSettings get colors => _colors;
  String get aiProviderId => _aiProviderId;
  AIProviderDefinition get aiProvider => AIProviders.byId(_aiProviderId);
  List<AIProviderDefinition> get aiProviders => AIProviders.all;
  String get apiKey => apiKeyFor(_aiProviderId);
  String apiKeyFor(String providerId) => _aiApiKeys[providerId] ?? '';
  bool get aiFeaturesEnabled => apiKey.trim().isNotEmpty;
  String get aiFeatureDisabledReason => '请先在设置中配置 ${aiProvider.label} API Key';
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
  AppThemeId get appThemeId => _appThemeId;
  ThemeMode get themeMode => _themeMode;
  int get dailyReadingGoalMinutes => _dailyReadingGoalMinutes;
  int get dailyReadingGoalSeconds => _dailyReadingGoalMinutes * 60;
  ThemeMode get nextThemeMode {
    final currentIndex = _themeModeCycle.indexOf(_themeMode);
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    return _themeModeCycle[(safeIndex + 1) % _themeModeCycle.length];
  }

  bool get backupEnabled => _backupEnabled;
  bool get includeSecretsInBackup => _includeSecretsInBackup;
  String get backupFolderPath => _backupFolderPath;
  String get backupFolderBookmark => _backupFolderBookmark;
  int get backupIntervalMinutes => _backupIntervalMinutes;
  DateTime? get lastBackupAt => _lastBackupAt;
  String? get lastBackupPath => _lastBackupPath;
  String get lastSeenReleaseNotesVersion => _lastSeenReleaseNotesVersion;
  String get activeSourceLanguage => _activeSourceLanguage;
  String get targetExplanationLanguage => _targetExplanationLanguage;
  Set<String> get enabledExperimentalFeatures =>
      Set.unmodifiable(_enabledExperimentalFeatures);
  List<DictionarySourceConfig> get dictionarySources =>
      List.unmodifiable(_dictionarySources);
  bool get collinsDictionaryEnabled => _dictionarySources.any(
    (config) => config.type == DictionarySourceType.collins && config.enabled,
  );
  bool get rssFeatureEnabled =>
      isExperimentalFeatureEnabled(experimentalFeatureRss);
  bool get reviewFeatureEnabled =>
      isExperimentalFeatureEnabled(experimentalFeatureReview);
  bool get v2FeatureEnabled =>
      isExperimentalFeatureEnabled(experimentalFeatureV2);

  Future<void> init() async {
    _box = Hive.box(HiveBoxNames.settings);
    _load();
    await _writeDictionarySources(_dictionarySources);
  }

  Future<void> reloadFromStorage() async {
    _load();
    notifyListeners();
  }

  void _load() {
    _colors = VocabularyColorSettings(
      unknownColor: Color(
        _box.get('unknownColor', defaultValue: 0xFFE74C3C) as int,
      ),
      learningColor: Color(
        _box.get('learningColor', defaultValue: 0xFF8E44AD) as int,
      ),
      knownColor: Color(
        _box.get('knownColor', defaultValue: 0xFF999999) as int,
      ),
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
      chapterSummaryCount:
          _box.get('aiChapterSummaryCount', defaultValue: 0) as int,
      textAnalysisCount:
          _box.get('aiTextAnalysisCount', defaultValue: 0) as int,
      practiceCount: _box.get('aiPracticeCount', defaultValue: 0) as int,
      wordAnalysisCount:
          _box.get('aiWordAnalysisCount', defaultValue: 0) as int,
    );
    final themeModeIndex = _box.get('themeMode', defaultValue: 0) as int;
    _themeMode =
        ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
    final appThemeIdValue = _box.get(
      'appThemeId',
      defaultValue: AppThemeId.classic.name,
    );
    _appThemeId = AppTheme.themeIdFromName(appThemeIdValue.toString());
    _dailyReadingGoalMinutes = _normalizeDailyReadingGoalMinutes(
      _box.get(
        _dailyReadingGoalMinutesKey,
        defaultValue: defaultDailyReadingGoalMinutes,
      ),
    );
    _backupEnabled = _box.get('backupEnabled', defaultValue: false) as bool;
    _includeSecretsInBackup =
        _box.get('includeSecretsInBackup', defaultValue: false) as bool;
    _backupFolderPath =
        _box.get('backupFolderPath', defaultValue: '') as String;
    _backupFolderBookmark =
        _box.get('backupFolderBookmark', defaultValue: '') as String;
    _backupIntervalMinutes =
        _box.get(
              'backupIntervalMinutes',
              defaultValue: defaultBackupIntervalMinutes,
            )
            as int;
    final lastBackupAtValue = _box.get('lastBackupAt') as String?;
    _lastBackupAt = lastBackupAtValue == null
        ? null
        : DateTime.tryParse(lastBackupAtValue);
    _lastBackupPath = _box.get('lastBackupPath') as String?;
    _lastSeenReleaseNotesVersion =
        _box.get('lastSeenReleaseNotesVersion', defaultValue: '') as String;
    _activeSourceLanguage = _readLanguageCode(
      _activeSourceLanguageKey,
      defaultValue: 'en',
    );
    _targetExplanationLanguage = _readLanguageCode(
      _targetExplanationLanguageKey,
      defaultValue: 'zh',
    );
    _enabledExperimentalFeatures = _readStringSet(
      _enabledExperimentalFeaturesKey,
    );
    _dictionarySources = _readDictionarySources();
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

  List<DictionarySourceConfig> _readDictionarySources() {
    final raw = _box.get(_dictionarySourcesKey);
    Object? decoded = raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return DictionarySourceConfig.defaults;
      }
    }
    if (decoded is Iterable) {
      final configs = decoded
          .whereType<Map>()
          .map(
            (item) => DictionarySourceConfig.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
      return DictionarySourceConfig.migrateLegacyOrder(configs);
    }
    return DictionarySourceConfig.defaults;
  }

  String _readLanguageCode(String key, {required String defaultValue}) {
    final value = _box.get(key, defaultValue: defaultValue).toString().trim();
    return value.isEmpty ? defaultValue : value.toLowerCase();
  }

  Future<void> _writeStringMap(String key, Map<String, String> value) async {
    await _box.put(key, jsonEncode(value));
  }

  Future<void> _writeStringSet(String key, Set<String> value) async {
    final sorted = value.toList()..sort();
    await _box.put(key, jsonEncode(sorted));
  }

  Future<void> _writeDictionarySources(
    List<DictionarySourceConfig> value,
  ) async {
    await _box.put(
      _dictionarySourcesKey,
      jsonEncode(value.map((config) => config.toJson()).toList()),
    );
  }

  Future<void> setAppThemeId(AppThemeId themeId) async {
    if (_appThemeId == themeId) return;
    _appThemeId = themeId;
    await _box.put('appThemeId', themeId.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _box.put('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> toggleThemeMode() {
    return setThemeMode(nextThemeMode);
  }

  Future<void> setDailyReadingGoalMinutes(int minutes) async {
    final normalized = _normalizeDailyReadingGoalMinutes(minutes);
    if (_dailyReadingGoalMinutes == normalized) return;
    _dailyReadingGoalMinutes = normalized;
    await _box.put(_dailyReadingGoalMinutesKey, normalized);
    notifyListeners();
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

  Future<void> setBackupFolderPath(String path, {String? bookmark}) async {
    _backupFolderPath = path;
    _backupFolderBookmark = bookmark ?? '';
    await _box.put('backupFolderPath', path);
    if (_backupFolderBookmark.isEmpty) {
      await _box.delete('backupFolderBookmark');
    } else {
      await _box.put('backupFolderBookmark', _backupFolderBookmark);
    }
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

  Future<void> setActiveSourceLanguage(String code) async {
    final normalized = _normalizeLanguageSetting(code, fallback: 'en');
    if (_activeSourceLanguage == normalized) return;
    _activeSourceLanguage = normalized;
    await _box.put(_activeSourceLanguageKey, normalized);
    notifyListeners();
  }

  set activeSourceLanguage(String code) {
    final normalized = _normalizeLanguageSetting(code, fallback: 'en');
    if (_activeSourceLanguage == normalized) return;
    _activeSourceLanguage = normalized;
    unawaited(_box.put(_activeSourceLanguageKey, normalized));
    notifyListeners();
  }

  Future<void> setTargetExplanationLanguage(String code) async {
    final normalized = _normalizeLanguageSetting(code, fallback: 'zh');
    if (_targetExplanationLanguage == normalized) return;
    _targetExplanationLanguage = normalized;
    await _box.put(_targetExplanationLanguageKey, normalized);
    notifyListeners();
  }

  set targetExplanationLanguage(String code) {
    final normalized = _normalizeLanguageSetting(code, fallback: 'zh');
    if (_targetExplanationLanguage == normalized) return;
    _targetExplanationLanguage = normalized;
    unawaited(_box.put(_targetExplanationLanguageKey, normalized));
    notifyListeners();
  }

  String _normalizeLanguageSetting(String code, {required String fallback}) {
    final normalized = code.trim().toLowerCase();
    return normalized.isEmpty ? fallback : normalized;
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

  Future<void> setReviewFeatureEnabled(bool enabled) {
    return setExperimentalFeatureEnabled(experimentalFeatureReview, enabled);
  }

  Future<void> setV2FeatureEnabled(bool enabled) {
    return setExperimentalFeatureEnabled(experimentalFeatureV2, enabled);
  }

  Future<void> setDictionarySourceEnabled(
    DictionarySourceType type,
    bool enabled,
  ) async {
    if (type == DictionarySourceType.wordNet && !enabled) return;
    _dictionarySources = DictionarySourceConfig.normalize(
      _dictionarySources.map(
        (config) =>
            config.type == type ? config.copyWith(enabled: enabled) : config,
      ),
    );
    await _writeDictionarySources(_dictionarySources);
    notifyListeners();
  }

  Future<void> setCollinsDictionaryEnabled(bool enabled) {
    return setDictionarySourceEnabled(DictionarySourceType.collins, enabled);
  }

  Future<void> moveDictionarySource(
    DictionarySourceType type,
    int direction,
  ) async {
    if (direction == 0) return;
    final sources = DictionarySourceConfig.normalize(_dictionarySources);
    final currentIndex = sources.indexWhere((config) => config.type == type);
    if (currentIndex < 0) return;

    final targetIndex = (currentIndex + direction)
        .clamp(0, sources.length - 1)
        .toInt();
    if (targetIndex == currentIndex) return;

    final reordered = [...sources];
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, moved);
    _dictionarySources = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(priority: i),
    ];
    await _writeDictionarySources(_dictionarySources);
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

  int _normalizeDailyReadingGoalMinutes(Object? raw) {
    int minutes;
    if (raw is int) {
      minutes = raw;
    } else if (raw is num) {
      minutes = raw.round();
    } else if (raw is String) {
      minutes =
          int.tryParse(raw) ??
          double.tryParse(raw)?.round() ??
          defaultDailyReadingGoalMinutes;
    } else {
      minutes = defaultDailyReadingGoalMinutes;
    }

    final stepped =
        (minutes / dailyReadingGoalStepMinutes).round() *
        dailyReadingGoalStepMinutes;
    return stepped
        .clamp(minDailyReadingGoalMinutes, maxDailyReadingGoalMinutes)
        .toInt();
  }
}
