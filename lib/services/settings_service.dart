import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';

import '../storage/database/dao/settings_dao.dart';
import '../storage/legacy_backup_box_names.dart';
import '../theme/app_theme.dart';
import 'package:flow_ai/flow_ai.dart';
import 'package:flow_dictionary/flow_dictionary.dart';

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
  static const _forceDefaultBookCoverKey = 'forceDefaultBookCover';
  static const _dictionarySourcesKey = 'dictionarySources';
  static const _activeSourceLanguageKey =
      LegacyBackupBoxNames.activeSourceLanguageKey;
  static const _targetExplanationLanguageKey = 'target_explanation_language';
  static const _cityAtmosphereEnabledKey = 'city_atmosphere.enabled';
  static const _cityAtmosphereThemeModeKey = 'city_atmosphere.theme_mode';
  static const _cityAtmosphereManualThemeIdKey =
      'city_atmosphere.manual_theme_id';
  static const _cityAtmosphereBlendModeKey = 'city_atmosphere.blend_mode';
  static const _cityAtmosphereManualSceneKey = 'city_atmosphere.manual_scene';
  static const _cityAtmosphereIntensityKey = 'city_atmosphere.intensity';
  static const _cityAtmosphereReduceMotionKey = 'city_atmosphere.reduce_motion';
  static const _cityAtmospherePerformanceModeKey =
      'city_atmosphere.performance_mode';
  static const _aiAutomationModeKey = 'ai_automation_mode';
  static const _themeModeCycle = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  final SettingsDao _dao;
  Map<String, String> _cache = {};
  Future<void>? _initFuture;
  bool _initialized = false;

  VocabularyColorSettings _colors = VocabularyColorSettings();
  String _aiProviderId = AIProviders.deepSeek.id;
  Map<String, String> _aiApiKeys = {};
  Map<String, String> _aiBaseUrls = {};
  Map<String, String> _aiModels = {};
  AIUsageStats _aiUsage = AIUsageStats();
  AIAutomationMode _aiAutomationMode = AIAutomationMode.saving;
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
  bool _forceDefaultBookCover = false;
  CityAtmosphereSettings _cityAtmosphereSettings =
      const CityAtmosphereSettings();
  List<DictionarySourceConfig> _dictionarySources =
      DictionarySourceConfig.defaults;

  SettingsService(this._dao);

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
  AIAutomationMode get aiAutomationMode => _aiAutomationMode;
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
  bool get desktopReaderWorkspaceEnabled => true;

  bool get forceDefaultBookCover => _forceDefaultBookCover;
  CityAtmosphereSettings get cityAtmosphereSettings => _cityAtmosphereSettings;

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
      _cache = await _dao.allEntries();
      _load();
      await _writeDictionarySources(_dictionarySources);
      _initialized = true;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> reloadFromStorage() async {
    _cache = await _dao.allEntries();
    _load();
    _initialized = true;
    notifyListeners();
  }

  String? _get(String key, {String? defaultValue}) {
    return _cache[key] ?? defaultValue;
  }

  void _put(String key, String value) {
    _cache[key] = value;
    unawaited(_dao.putValue(key, value));
  }

  void _remove(String key) {
    _cache.remove(key);
    unawaited(_dao.removeValue(key));
  }

  Future<void> _putAndWait(String key, String value) {
    _cache[key] = value;
    return _dao.putValue(key, value);
  }

  void _load() {
    _colors = VocabularyColorSettings(
      unknownColor: Color(_readInt('unknownColor', 0xFFE74C3C)),
      learningColor: Color(_readInt('learningColor', 0xFF8E44AD)),
      knownColor: Color(_readInt('knownColor', 0xFF999999)),
    );
    _aiProviderId = _get(
      'aiProviderId',
      defaultValue: AIProviders.deepSeek.id,
    )!;
    _aiProviderId = AIProviders.byId(_aiProviderId).id;
    _aiApiKeys = _readStringMap('aiApiKeys');
    final legacyApiKey = _get('apiKey') ?? '';
    if (legacyApiKey.isNotEmpty &&
        (_aiApiKeys[AIProviders.deepSeek.id]?.isEmpty ?? true)) {
      _aiApiKeys[AIProviders.deepSeek.id] = legacyApiKey;
    }
    _aiBaseUrls = _readStringMap('aiBaseUrls');
    _aiModels = _readStringMap('aiModels');
    _aiUsage = AIUsageStats(
      chapterSummaryCount: _readInt('aiChapterSummaryCount', 0),
      textAnalysisCount: _readInt('aiTextAnalysisCount', 0),
      practiceCount: _readInt('aiPracticeCount', 0),
      wordAnalysisCount: _readInt('aiWordAnalysisCount', 0),
    );
    _aiAutomationMode = _readEnumByName(
      _aiAutomationModeKey,
      AIAutomationMode.values,
      AIAutomationMode.saving,
    );
    final themeModeIndex = _readInt('themeMode', 0);
    _themeMode =
        ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
    final appThemeIdValue = _get(
      'appThemeId',
      defaultValue: AppThemeId.classic.name,
    )!;
    _appThemeId = AppTheme.themeIdFromName(appThemeIdValue);
    _dailyReadingGoalMinutes = _normalizeDailyReadingGoalMinutes(
      _get(
        _dailyReadingGoalMinutesKey,
        defaultValue: '$defaultDailyReadingGoalMinutes',
      ),
    );
    _backupEnabled = _readBool('backupEnabled', false);
    _includeSecretsInBackup = _readBool('includeSecretsInBackup', false);
    _backupFolderPath = _get('backupFolderPath', defaultValue: '')!;
    _backupFolderBookmark = _get('backupFolderBookmark', defaultValue: '')!;
    _backupIntervalMinutes = _readInt(
      'backupIntervalMinutes',
      defaultBackupIntervalMinutes,
    );
    final lastBackupAtValue = _get('lastBackupAt');
    _lastBackupAt = lastBackupAtValue != null
        ? DateTime.tryParse(lastBackupAtValue)
        : null;
    _lastBackupPath = _get('lastBackupPath');
    _lastSeenReleaseNotesVersion = _get(
      'lastSeenReleaseNotesVersion',
      defaultValue: '',
    )!;
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
    _forceDefaultBookCover = _readBool(_forceDefaultBookCoverKey, false);
    _cityAtmosphereSettings = _readCityAtmosphereSettings();
    _dictionarySources = _readDictionarySources();
  }

  int _readInt(String key, int defaultValue) {
    final val = _cache[key];
    if (val == null) return defaultValue;
    return int.tryParse(val) ?? defaultValue;
  }

  bool _readBool(String key, bool defaultValue) {
    final val = _cache[key];
    if (val == null) return defaultValue;
    return val == 'true';
  }

  CityAtmosphereSettings _readCityAtmosphereSettings() {
    final defaults = const CityAtmosphereSettings();
    final manualThemeId = _get(
      _cityAtmosphereManualThemeIdKey,
      defaultValue: defaults.manualThemeId,
    )!;

    return CityAtmosphereSettings(
      enabled: _readBool(_cityAtmosphereEnabledKey, false),
      themeMode: _readEnumByName(
        _cityAtmosphereThemeModeKey,
        CityThemeMode.values,
        CityThemeMode.systemTime,
      ),
      manualThemeId: CityThemePresets.containsId(manualThemeId)
          ? manualThemeId
          : defaults.manualThemeId,
      blendMode: _readEnumByName(
        _cityAtmosphereBlendModeKey,
        AtmosphereBlendMode.values,
        AtmosphereBlendMode.followTheme,
      ),
      manualScene: _readEnumByName(
        _cityAtmosphereManualSceneKey,
        AtmosphereScene.values,
        AtmosphereScene.none,
      ),
      atmosphereIntensity: _readDouble(
        _cityAtmosphereIntensityKey,
        defaultValue: defaults.atmosphereIntensity,
        min: 0,
        max: 1,
      ),
      reduceMotion: _readBool(_cityAtmosphereReduceMotionKey, false),
      performanceMode: _readEnumByName(
        _cityAtmospherePerformanceModeKey,
        AtmospherePerformanceMode.values,
        AtmospherePerformanceMode.auto,
      ),
    );
  }

  Map<String, String> _readStringMap(String key) {
    final raw = _cache[key];
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  Set<String> _readStringSet(String key) {
    final raw = _cache[key];
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
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
    } catch (_) {}
    return {};
  }

  T _readEnumByName<T extends Enum>(
    String key,
    List<T> values,
    T fallback,
  ) {
    final raw = _get(key, defaultValue: fallback.name) ?? fallback.name;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  double _readDouble(
    String key, {
    required double defaultValue,
    required double min,
    required double max,
  }) {
    final raw = _cache[key];
    if (raw == null) return defaultValue;
    final value = double.tryParse(raw) ?? defaultValue;
    return value.clamp(min, max).toDouble();
  }

  List<DictionarySourceConfig> _readDictionarySources() {
    final raw = _cache[_dictionarySourcesKey];
    if (raw == null || raw.isEmpty) return DictionarySourceConfig.defaults;
    try {
      final decoded = jsonDecode(raw);
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
    } catch (_) {}
    return DictionarySourceConfig.defaults;
  }

  String _readLanguageCode(String key, {required String defaultValue}) {
    final value = _get(key, defaultValue: defaultValue) ?? defaultValue;
    return value.isEmpty ? defaultValue : value.toLowerCase();
  }

  void _writeStringMap(String key, Map<String, String> value) {
    _put(key, jsonEncode(value));
  }

  void _writeStringSet(String key, Set<String> value) {
    final sorted = value.toList()..sort();
    _put(key, jsonEncode(sorted));
  }

  Future<void> _writeDictionarySources(
    List<DictionarySourceConfig> value,
  ) async {
    await _putAndWait(
      _dictionarySourcesKey,
      jsonEncode(value.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _writeCityAtmosphereSettings(
    CityAtmosphereSettings value,
  ) async {
    await Future.wait<void>([
      _putAndWait(_cityAtmosphereEnabledKey, value.enabled.toString()),
      _putAndWait(_cityAtmosphereThemeModeKey, value.themeMode.name),
      _putAndWait(_cityAtmosphereManualThemeIdKey, value.manualThemeId),
      _putAndWait(_cityAtmosphereBlendModeKey, value.blendMode.name),
      _putAndWait(_cityAtmosphereManualSceneKey, value.manualScene.name),
      _putAndWait(
        _cityAtmosphereIntensityKey,
        value.normalizedIntensity.toString(),
      ),
      _putAndWait(
        _cityAtmosphereReduceMotionKey,
        value.reduceMotion.toString(),
      ),
      _putAndWait(
        _cityAtmospherePerformanceModeKey,
        value.performanceMode.name,
      ),
    ]);
  }

  Future<void> _setCityAtmosphereSettings(CityAtmosphereSettings value) async {
    final normalized = value.copyWith(
      manualThemeId: CityThemePresets.byId(value.manualThemeId).id,
      atmosphereIntensity: value.normalizedIntensity,
    );
    if (_cityAtmosphereSettings == normalized) return;
    _cityAtmosphereSettings = normalized;
    await _writeCityAtmosphereSettings(normalized);
    notifyListeners();
  }

  Future<void> setAppThemeId(AppThemeId themeId) async {
    if (_appThemeId == themeId) return;
    _appThemeId = themeId;
    _put('appThemeId', themeId.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _put('themeMode', mode.index.toString());
    notifyListeners();
  }

  Future<void> toggleThemeMode() {
    return setThemeMode(nextThemeMode);
  }

  Future<void> setDailyReadingGoalMinutes(int minutes) async {
    final normalized = _normalizeDailyReadingGoalMinutes(minutes);
    if (_dailyReadingGoalMinutes == normalized) return;
    _dailyReadingGoalMinutes = normalized;
    _put(_dailyReadingGoalMinutesKey, normalized.toString());
    notifyListeners();
  }

  Future<void> setUnknownColor(Color color) async {
    _colors.unknownColor = color;
    _put('unknownColor', color.toARGB32().toString());
    notifyListeners();
  }

  Future<void> setLearningColor(Color color) async {
    _colors.learningColor = color;
    _put('learningColor', color.toARGB32().toString());
    notifyListeners();
  }

  Future<void> setKnownColor(Color color) async {
    _colors.knownColor = color;
    _put('knownColor', color.toARGB32().toString());
    notifyListeners();
  }

  Future<void> setAIProvider(String providerId) async {
    _aiProviderId = AIProviders.byId(providerId).id;
    _put('aiProviderId', _aiProviderId);
    notifyListeners();
  }

  Future<void> setApiKey(String key, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiApiKeys = {..._aiApiKeys, id: key};
    _writeStringMap('aiApiKeys', _aiApiKeys);
    if (id == AIProviders.deepSeek.id) {
      _put('apiKey', key);
    }
    notifyListeners();
  }

  Future<void> setAIBaseUrl(String baseUrl, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiBaseUrls = {..._aiBaseUrls, id: baseUrl};
    _writeStringMap('aiBaseUrls', _aiBaseUrls);
    notifyListeners();
  }

  Future<void> setAIModel(String model, {String? providerId}) async {
    final id = AIProviders.byId(providerId ?? _aiProviderId).id;
    _aiModels = {..._aiModels, id: model};
    _writeStringMap('aiModels', _aiModels);
    notifyListeners();
  }

  Future<void> setAIAutomationMode(AIAutomationMode mode) async {
    _aiAutomationMode = mode;
    _put(_aiAutomationModeKey, mode.name);
    notifyListeners();
  }

  Future<void> setBackupEnabled(bool enabled) async {
    _backupEnabled = enabled;
    _put('backupEnabled', enabled.toString());
    notifyListeners();
  }

  Future<void> setIncludeSecretsInBackup(bool enabled) async {
    _includeSecretsInBackup = enabled;
    _put('includeSecretsInBackup', enabled.toString());
    notifyListeners();
  }

  Future<void> setBackupFolderPath(String path, {String? bookmark}) async {
    _backupFolderPath = path;
    _backupFolderBookmark = bookmark ?? '';
    _put('backupFolderPath', path);
    if (_backupFolderBookmark.isEmpty) {
      _remove('backupFolderBookmark');
    } else {
      _put('backupFolderBookmark', _backupFolderBookmark);
    }
    notifyListeners();
  }

  Future<void> setBackupIntervalMinutes(int minutes) async {
    _backupIntervalMinutes = minutes.clamp(15, 60 * 24 * 7).toInt();
    _put('backupIntervalMinutes', _backupIntervalMinutes.toString());
    notifyListeners();
  }

  Future<void> setLastBackup(DateTime at, String path) async {
    _lastBackupAt = at;
    _lastBackupPath = path;
    _put('lastBackupAt', at.toIso8601String());
    _put('lastBackupPath', path);
    notifyListeners();
  }

  bool shouldShowReleaseNotes(String version) {
    return _lastSeenReleaseNotesVersion != version;
  }

  Future<void> markReleaseNotesSeen(String version) async {
    _lastSeenReleaseNotesVersion = version;
    await _putAndWait('lastSeenReleaseNotesVersion', version);
    notifyListeners();
  }

  Future<void> setActiveSourceLanguage(String code) async {
    final normalized = _normalizeLanguageSetting(code, fallback: 'en');
    if (_activeSourceLanguage == normalized) return;
    _activeSourceLanguage = normalized;
    _put(_activeSourceLanguageKey, normalized);
    notifyListeners();
  }

  set activeSourceLanguage(String code) {
    final normalized = _normalizeLanguageSetting(code, fallback: 'en');
    if (_activeSourceLanguage == normalized) return;
    _activeSourceLanguage = normalized;
    _put(_activeSourceLanguageKey, normalized);
    notifyListeners();
  }

  Future<void> setTargetExplanationLanguage(String code) async {
    final normalized = _normalizeLanguageSetting(code, fallback: 'zh');
    if (_targetExplanationLanguage == normalized) return;
    _targetExplanationLanguage = normalized;
    _put(_targetExplanationLanguageKey, normalized);
    notifyListeners();
  }

  set targetExplanationLanguage(String code) {
    final normalized = _normalizeLanguageSetting(code, fallback: 'zh');
    if (_targetExplanationLanguage == normalized) return;
    _targetExplanationLanguage = normalized;
    _put(_targetExplanationLanguageKey, normalized);
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
    _writeStringSet(
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

  Future<void> setForceDefaultBookCover(bool enabled) async {
    if (_forceDefaultBookCover == enabled) return;
    _forceDefaultBookCover = enabled;
    _put(_forceDefaultBookCoverKey, enabled.toString());
    notifyListeners();
  }

  Future<void> setCityAtmosphereEnabled(bool enabled) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(enabled: enabled),
    );
  }

  Future<void> setCityThemeMode(CityThemeMode value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(themeMode: value),
    );
  }

  Future<void> setManualCityTheme(String themeId) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(
        manualThemeId: CityThemePresets.byId(themeId).id,
      ),
    );
  }

  Future<void> setAtmosphereBlendMode(AtmosphereBlendMode value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(blendMode: value),
    );
  }

  Future<void> setManualAtmosphereScene(AtmosphereScene value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(manualScene: value),
    );
  }

  Future<void> setAtmosphereIntensity(double value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(atmosphereIntensity: value),
    );
  }

  Future<void> setReduceAtmosphereMotion(bool value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(reduceMotion: value),
    );
  }

  Future<void> setAtmospherePerformanceMode(AtmospherePerformanceMode value) {
    return _setCityAtmosphereSettings(
      _cityAtmosphereSettings.copyWith(performanceMode: value),
    );
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
      _put('aiChapterSummaryCount', _aiUsage.chapterSummaryCount.toString());
    }
    if (textAnalysis) {
      _aiUsage.textAnalysisCount++;
      _put('aiTextAnalysisCount', _aiUsage.textAnalysisCount.toString());
    }
    if (practice) {
      _aiUsage.practiceCount++;
      _put('aiPracticeCount', _aiUsage.practiceCount.toString());
    }
    if (wordAnalysis) {
      _aiUsage.wordAnalysisCount++;
      _put('aiWordAnalysisCount', _aiUsage.wordAnalysisCount.toString());
    }
    notifyListeners();
  }

  Future<void> clearAIUsage() async {
    _aiUsage = AIUsageStats();
    _put('aiChapterSummaryCount', '0');
    _put('aiTextAnalysisCount', '0');
    _put('aiPracticeCount', '0');
    _put('aiWordAnalysisCount', '0');
    notifyListeners();
  }

  Future<void> close() async {}

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
