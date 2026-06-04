import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../providers/backup_provider.dart';
import '../providers/reading_provider.dart';
import '../providers/rss_riverpod_provider.dart';
import '../services/ai_cache_service.dart';
import '../services/app_update_installer.dart';
import '../services/app_update_service.dart';
import '../services/app_links.dart';
import '../services/backup_folder_access.dart';
import '../services/backup_service.dart';
import '../services/changelog_service.dart';
import '../services/dictionary/dictionary_cache_service.dart';
import '../services/dictionary/dictionary_source_config.dart';
import '../services/dictionary/dictionary_source_registry.dart';
import '../services/dictionary/dictionary_source_test_service.dart';
import '../services/diagnostic_export_service.dart';
import '../services/external_url_launcher.dart';
import '../services/log_folder_opener.dart';
import '../services/llm_client.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/release_notes_dialog.dart';
import '../widgets/settings/settings_sections.dart';
import '../widgets/settings/update_check_result_dialog.dart';
import '../widgets/theme_transition.dart';

class SettingsScreen extends riverpod.ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.appUpdateService,
    this.updateInstaller,
    this.externalUrlLauncher,
    this.logFolderOpener,
  });

  static const routeName = '/settings';

  final AppUpdateService? appUpdateService;
  final AppUpdateInstaller? updateInstaller;
  final ExternalUrlLauncher? externalUrlLauncher;
  final LogFolderOpener? logFolderOpener;

  @override
  riverpod.ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends riverpod.ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _dictionaryTestWordController = TextEditingController(text: 'flow');
  String? _controllerProviderId;
  bool _obscureKey = true;
  bool _testingConnection = false;
  bool _testingDictionarySources = false;
  bool _importingWordHunter = false;
  String? _connectionResult;
  Map<DictionarySourceType, DictionarySourceTestResult>
  _dictionarySourceTestResults = const {};
  bool _checkingForUpdate = false;
  String? _updateStatusMessage;
  bool _updateStatusIsError = false;
  String? _updateFallbackActionLabel;
  Uri? _updateFallbackUrl;
  AppUpdateInfo? _availableUpdate;
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;
  String? _extractedAppPath;
  bool _installingUpdate = false;
  int? _aiCacheEntryCount;
  int? _dictionaryCacheEntryCount;
  bool _cacheStatsLoading = true;
  bool _exportingDiagnostics = false;
  SettingsSection _selectedSection = SettingsSection.appearance;
  final BackupFolderAccess _backupFolderAccess = const BackupFolderAccess();
  late final AppUpdateService _appUpdateService;
  late final bool _ownsAppUpdateService;
  late final AppUpdateInstaller _updateInstaller;
  late final ExternalUrlLauncher _externalUrlLauncher;
  late final LogFolderOpener _logFolderOpener;

  static const _desktopBreakpoint = 760.0;

  @override
  void initState() {
    super.initState();
    _appUpdateService = widget.appUpdateService ?? AppUpdateService();
    _ownsAppUpdateService = widget.appUpdateService == null;
    _updateInstaller = widget.updateInstaller ?? const AppUpdateInstaller();
    _externalUrlLauncher =
        widget.externalUrlLauncher ?? const ExternalUrlLauncher();
    _logFolderOpener = widget.logFolderOpener ?? LogFolderOpener();
    unawaited(_refreshCacheStats());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _dictionaryTestWordController.dispose();
    if (_ownsAppUpdateService) {
      _appUpdateService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final backup = ref.watch(backupProvider);
    final theme = Theme.of(context);
    _syncAIControllers(settings);

    return Scaffold(
      body: SafeArea(
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _desktopBreakpoint) {
                return Row(
                  children: [
                    _buildSidebar(theme),
                    VerticalDivider(
                      width: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    Expanded(
                      child: _buildSectionContent(theme, settings, backup),
                    ),
                  ],
                );
              }
              return _buildCompactLayout(theme, settings, backup);
            },
          ),
        ),
      ),
    );
  }

  void _syncAIControllers(SettingsService settings) {
    if (_controllerProviderId == settings.aiProviderId) return;
    _controllerProviderId = settings.aiProviderId;
    _apiKeyController.text = settings.apiKeyFor(settings.aiProviderId);
    _baseUrlController.text = settings.aiBaseUrlFor(settings.aiProviderId);
    _modelController.text = settings.aiModelFor(settings.aiProviderId);
  }

  Widget _buildSidebar(ThemeData theme) {
    final topInset = AppConstants.immersiveTitleBarTopInset;
    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18 + topInset, 18, 22),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    Tooltip(
                      message: '返回',
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Image.asset(
                    'assets/brand/flow_read_logo.png',
                    width: 26,
                    height: 26,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FlowRead',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
                children: [
                  for (final section in SettingsSection.values)
                    SettingsSidebarItem(
                      section: section,
                      selected: _selectedSection == section,
                      onTap: () => setState(() => _selectedSection = section),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    ThemeData theme,
    SettingsService settings,
    BackupService backup,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            10 + AppConstants.immersiveTitleBarTopInset,
            12,
            6,
          ),
          child: Row(
            children: [
              if (Navigator.canPop(context))
                Tooltip(
                  message: '返回',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              Image.asset(
                'assets/brand/flow_read_logo.png',
                width: 26,
                height: 26,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 10),
              Text(
                '设置',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final section = SettingsSection.values[index];
              final selected = _selectedSection == section;
              return ChoiceChip(
                avatar: Icon(section.icon, size: 18),
                label: Text(section.title),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSection = section),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemCount: SettingsSection.values.length,
          ),
        ),
        Expanded(child: _buildSectionContent(theme, settings, backup)),
      ],
    );
  }

  Widget _buildSectionContent(
    ThemeData theme,
    SettingsService settings,
    BackupService backup, {
    double topInset = 0,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          key: ValueKey('settings-section-${_selectedSection.name}'),
          padding: EdgeInsets.fromLTRB(32, 28 + topInset, 36, 36),
          children: [
            SettingsSectionHeading(section: _selectedSection),
            const SizedBox(height: 22),
            switch (_selectedSection) {
              SettingsSection.appearance => SettingsAppearanceSection(
                settings: settings,
                onSwitchTheme: _switchTheme,
              ),
              SettingsSection.reading => SettingsReadingSection(
                settings: settings,
              ),
              SettingsSection.dictionary => SettingsDictionarySection(
                settings: settings,
                testWordController: _dictionaryTestWordController,
                testingSources: _testingDictionarySources,
                testResults: _dictionarySourceTestResults,
                onTestSources: () =>
                    unawaited(_testDictionarySources(settings)),
                onClearCache: () => unawaited(_clearDictionaryCache()),
                cacheEntryCount: _dictionaryCacheEntryCount,
                cacheStatsLoading: _cacheStatsLoading,
              ),
              SettingsSection.ai => SettingsAISection(
                settings: settings,
                apiKeyController: _apiKeyController,
                baseUrlController: _baseUrlController,
                modelController: _modelController,
                obscureKey: _obscureKey,
                testingConnection: _testingConnection,
                connectionResult: _connectionResult,
                onProviderChanged: (value) {
                  _connectionResult = null;
                  settings.setAIProvider(value);
                },
                onModelChanged: (value) {
                  settings.setAIModel(value);
                  _connectionResult = null;
                },
                onBaseUrlChanged: (value) {
                  settings.setAIBaseUrl(value);
                  _connectionResult = null;
                },
                onApiKeyChanged: (value) {
                  settings.setApiKey(value);
                  _connectionResult = null;
                },
                onToggleObscureKey: () =>
                    setState(() => _obscureKey = !_obscureKey),
                onTestConnection: () => unawaited(_testConnection(settings)),
                onClearConfig: () => unawaited(_clearAIConfig(settings)),
                onClearCache: _showClearCacheDialog,
                aiCacheEntryCount: _aiCacheEntryCount,
                cacheStatsLoading: _cacheStatsLoading,
              ),
              SettingsSection.backup => SettingsBackupSection(
                settings: settings,
                backup: backup,
                importingWordHunter: _importingWordHunter,
                onChooseFolder: () => unawaited(_chooseBackupFolder()),
                onExportBackup: () => unawaited(_exportBackup(backup)),
                onImportBackup: () => unawaited(_importBackup()),
                onImportWordHunter: () => unawaited(_importWordHunterBackup()),
              ),
              SettingsSection.experiments =>
                SettingsExperimentalFeaturesSection(settings: settings),
              SettingsSection.about => SettingsAboutSection(
                onShowReleaseNotes: () => unawaited(_showCurrentReleaseNotes()),
                onCheckForUpdates: () => unawaited(_checkForUpdates()),
                checkingForUpdate: _checkingForUpdate,
                updateStatusMessage: _updateStatusMessage,
                updateStatusIsError: _updateStatusIsError,
                updateFallbackActionLabel: _updateFallbackActionLabel,
                onOpenUpdateFallback: _updateFallbackUrl == null
                    ? null
                    : () => unawaited(_openUpdateFallbackUrl()),
                availableUpdate: _availableUpdate,
                onDownloadUpdate: _availableUpdate == null
                    ? null
                    : () => unawaited(_startDownloadUpdate()),
                downloadingUpdate: _downloadingUpdate,
                downloadProgress: _downloadProgress,
                installedAppPath: _extractedAppPath,
                installingUpdate: _installingUpdate,
                onInstallUpdate: _extractedAppPath == null
                    ? null
                    : () => unawaited(_installUpdate()),
                onOpenUpdateReleasePage: _availableUpdate == null
                    ? null
                    : () => unawaited(_openAvailableUpdateReleasePage()),
                onOpenLogsFolder: () => unawaited(_openLogsFolder()),
                onExportDiagnostics: () =>
                    unawaited(_exportDiagnostics(settings)),
                exportingDiagnostics: _exportingDiagnostics,
                backupFolderPath: settings.backupFolderPath,
                backupFolderBookmark: settings.backupFolderBookmark,
                onReauthorizeBackupFolder: () =>
                    unawaited(_chooseBackupFolder()),
                onOpenRepository: () => unawaited(_openRepositoryUrl()),
                onOpenIssueFeedback: () => unawaited(_openIssueFeedbackUrl()),
              ),
            },
          ],
        ),
      ),
    );
  }

  Future<void> _switchTheme(ThemeMutation mutation) {
    return runThemeTransition(context, mutation);
  }

  Future<void> _testConnection(SettingsService settings) async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });

    final client = LLMClient(settings);
    final ok = await client.testConnection();

    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _connectionResult = ok ? '连接成功' : '连接失败，请检查配置';
    });
  }

  Future<void> _testDictionarySources(SettingsService settings) async {
    setState(() {
      _testingDictionarySources = true;
      _dictionarySourceTestResults = const {};
    });

    final word = _dictionaryTestWordController.text.trim().isEmpty
        ? 'flow'
        : _dictionaryTestWordController.text.trim();
    if (_dictionaryTestWordController.text != word) {
      _dictionaryTestWordController.text = word;
    }

    try {
      final dictionarySources = DictionarySourceRegistry();
      await dictionarySources.init();
      final tester = DictionarySourceTestService(
        repositories: dictionarySources.repositories(),
      );

      final results = await tester.testSources(
        settings.dictionarySources.map((config) => config.type),
        word,
      );

      if (!mounted) return;
      setState(() {
        _dictionarySourceTestResults = results;
        _testingDictionarySources = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _testingDictionarySources = false);
      _showSnackBar('词典来源测试失败：$error');
    }
  }

  Future<void> _refreshCacheStats() async {
    if (mounted) {
      setState(() => _cacheStatsLoading = true);
    }

    int? aiCacheCount;
    int? dictionaryCacheCount;

    try {
      final aiCache = AICacheService();
      await aiCache.init();
      aiCacheCount = await aiCache.getCacheCount();
    } catch (_) {
      aiCacheCount = null;
    }

    try {
      final dictionaryCache = DictionaryCacheService();
      await dictionaryCache.init();
      dictionaryCacheCount = dictionaryCache.entryCount;
    } catch (_) {
      dictionaryCacheCount = null;
    }

    if (!mounted) return;
    setState(() {
      _aiCacheEntryCount = aiCacheCount;
      _dictionaryCacheEntryCount = dictionaryCacheCount;
      _cacheStatsLoading = false;
    });
  }

  Future<void> _clearAIConfig(SettingsService settings) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('清除配置'),
            content: Text(
              '将清除 ${settings.aiProvider.label} 的 API Key，并把 Base URL 和模型恢复为默认值。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('清除配置'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final provider = settings.aiProvider;
    await settings.setApiKey('');
    await settings.setAIBaseUrl(provider.defaultBaseUrl);
    await settings.setAIModel(provider.defaultModel);
    if (!mounted) return;

    _controllerProviderId = null;
    _syncAIControllers(settings);
    setState(() => _connectionResult = null);
    _showSnackBar('AI 配置已清除');
  }

  void _showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除 AI 缓存'),
        content: const Text('将清除所有章节总结和练习题缓存。书籍、生词、书签、阅读进度和 AI 配置不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ReadingProvider>().clearAICache();
              await _refreshCacheStats();
              if (mounted) {
                _showSnackBar('AI 缓存已清除');
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDictionaryCache() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('清理词典缓存'),
            content: const Text(
              '将删除 Collins、Longman 等在线词典查询缓存。生词本、学习记录、书签和阅读进度不会被删除。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('清理'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final cache = DictionaryCacheService();
    await cache.init();
    await cache.clear();
    await _refreshCacheStats();
    if (mounted) {
      _showSnackBar('词典缓存已清理');
    }
  }

  Future<void> _chooseBackupFolder() async {
    final settings = context.read<SettingsService>();
    final selection = await _backupFolderAccess.chooseDirectory(
      dialogTitle: '选择备份文件夹',
      initialDirectory: settings.backupFolderPath.trim().isEmpty
          ? null
          : settings.backupFolderPath,
    );
    if (selection == null || !mounted) return;
    await settings.setBackupFolderPath(
      selection.path,
      bookmark: selection.bookmark,
    );
  }

  Future<void> _exportBackup(BackupService backup) async {
    try {
      final refreshed = await _refreshBackupFolderAccessIfNeeded();
      if (!refreshed || !mounted) return;
      final path = await backup.exportNow();
      if (!mounted) return;
      _showSnackBar('备份已生成：$path');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('备份失败：$e');
    }
  }

  Future<bool> _refreshBackupFolderAccessIfNeeded() async {
    final settings = context.read<SettingsService>();
    if (!_backupFolderAccess.requiresPersistentAccess ||
        settings.backupFolderBookmark.isNotEmpty) {
      return true;
    }

    final selection = await _backupFolderAccess.chooseDirectory(
      dialogTitle: '重新授权备份文件夹',
      initialDirectory: settings.backupFolderPath.trim().isEmpty
          ? null
          : settings.backupFolderPath,
    );
    if (selection == null || !mounted) return false;
    await settings.setBackupFolderPath(
      selection.path,
      bookmark: selection.bookmark,
    );
    return true;
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 FlowRead 备份',
      type: FileType.custom,
      allowedExtensions: ['bak'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await _confirmImport();
    if (!confirmed || !mounted) return;

    final backup = ref.read(backupProvider);
    final readingProvider = context.read<ReadingProvider>();
    final rssNotifier = ref.read(rssProvider);

    try {
      await backup.importBackupFile(path);
      await readingProvider.reloadAfterBackupRestore();
      await rssNotifier.init();
      if (!mounted) return;
      _showSnackBar('备份已导入');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('导入失败：$e');
    }
  }

  Future<void> _importWordHunterBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 Word Hunter 备份',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await _confirmWordHunterImport();
    if (!confirmed || !mounted) return;

    final backup = ref.read(backupProvider);
    final readingProvider = context.read<ReadingProvider>();

    setState(() => _importingWordHunter = true);
    try {
      final importResult = await backup.importWordHunterBackupFile(path);
      await readingProvider.init();
      if (!mounted) return;
      _showSnackBar(
        'Word Hunter 已导入：${importResult.knownCount} 个熟词、'
        '${importResult.learningCount} 个学习中、'
        '${importResult.exampleCount} 条例句',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Word Hunter 导入失败：$e');
    } finally {
      if (mounted) {
        setState(() => _importingWordHunter = false);
      }
    }
  }

  Future<bool> _confirmImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入备份'),
            content: const Text('导入前将自动备份当前数据。导入后将替换当前书架、词汇、书签、RSS 和阅读数据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('导入'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmWordHunterImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入 Word Hunter 备份'),
            content: const Text(
              '将合并熟词、学习中单词和例句，不会清空当前 FlowRead 数据；同一个单词以熟词状态优先。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('导入'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showCurrentReleaseNotes() async {
    final notes = await ChangelogService.loadCurrentReleaseNotes();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => ReleaseNotesDialog(notes: notes),
    );
  }

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdate) return;

    setState(() {
      _checkingForUpdate = true;
      _updateStatusMessage = null;
      _updateStatusIsError = false;
      _updateFallbackActionLabel = null;
      _updateFallbackUrl = null;
    });

    try {
      final update = await _appUpdateService.checkForUpdate();
      if (!mounted) return;

      setState(() {
        _checkingForUpdate = false;
        _availableUpdate = update;
        _updateStatusIsError = false;
        _updateFallbackActionLabel = null;
        _updateFallbackUrl = null;
        _updateStatusMessage = update == null ? '当前已安装最新版本' : null;
        _extractedAppPath = null;
      });
      await _showUpdateCheckResultDialog(update);
    } catch (error) {
      if (!mounted) return;
      final message = _friendlyUpdateError(error);
      final fallbackActionLabel = error is AppUpdateException
          ? error.actionLabel
          : null;
      final fallbackUrl = error is AppUpdateException ? error.actionUrl : null;

      setState(() {
        _checkingForUpdate = false;
        _updateStatusIsError = true;
        _updateStatusMessage = message;
        _updateFallbackActionLabel = fallbackActionLabel;
        _updateFallbackUrl = fallbackUrl;
      });
      await _showUpdateCheckErrorDialog(
        message,
        actionLabel: fallbackActionLabel,
        actionUrl: fallbackUrl,
      );
    }
  }

  Future<void> _showUpdateCheckResultDialog(AppUpdateInfo? update) async {
    if (!mounted) return;

    final action = await showDialog<UpdateCheckResultAction>(
      context: context,
      builder: (_) => UpdateCheckResultDialog(update: update),
    );

    if (update == null) return;
    if (!mounted) return;
    switch (action) {
      case UpdateCheckResultAction.updateNow:
        await _startDownloadUpdate();
      case UpdateCheckResultAction.viewReleaseNotes:
        await _openAvailableUpdateReleasePage();
      case null:
        return;
    }
  }

  Future<void> _showUpdateCheckErrorDialog(
    String message, {
    String? actionLabel,
    Uri? actionUrl,
  }) async {
    if (!mounted) return;

    final openFallback = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('检查更新失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('知道了'),
          ),
          if (actionLabel != null && actionUrl != null)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(actionLabel),
            ),
        ],
      ),
    );

    if (openFallback == true && actionUrl != null) {
      await _openExternalUrl(actionUrl);
    }
  }

  Future<void> _openUpdateFallbackUrl() async {
    final url = _updateFallbackUrl;
    if (url == null) return;
    await _openExternalUrl(url);
  }

  Future<void> _startDownloadUpdate() async {
    final update = _availableUpdate;
    if (update == null || _downloadingUpdate) return;
    if (!update.hasDownloadAsset) {
      await _openAvailableUpdateReleasePage();
      return;
    }

    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
      _updateStatusMessage = null;
      _extractedAppPath = null;
    });

    try {
      final appPath = await _appUpdateService.downloadAndExtract(
        update,
        onProgress: (phase, progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      if (!mounted) return;

      setState(() {
        _downloadingUpdate = false;
        _downloadProgress = 1;
        _extractedAppPath = appPath;
        _updateStatusMessage = '已准备好安装 Flow Read ${update.version}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _downloadingUpdate = false;
        _downloadProgress = 0;
        _extractedAppPath = null;
        _updateStatusIsError = true;
        _updateStatusMessage = _friendlyUpdateError(error);
      });
    }
  }

  Future<void> _installUpdate() async {
    final appPath = _extractedAppPath;
    if (appPath == null || _installingUpdate) return;

    setState(() {
      _installingUpdate = true;
    });

    try {
      await _updateInstaller.installUpdate(appPath);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _installingUpdate = false;
        _updateStatusIsError = true;
        _updateStatusMessage = _friendlyUpdateError(error);
      });
    }
  }

  Future<void> _openAvailableUpdateReleasePage() async {
    final update = _availableUpdate;
    if (update == null) return;
    await _openExternalUrl(update.releasePageUrl);
  }

  Future<void> _openRepositoryUrl() async {
    await _openExternalUrl(AppLinks.repositoryUrl);
  }

  Future<void> _openIssueFeedbackUrl() async {
    await _openExternalUrl(AppLinks.issueFeedbackUrl);
  }

  Future<void> _openLogsFolder() async {
    try {
      await _logFolderOpener.openLogsFolder();
    } catch (error) {
      if (!mounted) return;
      if (error is LogFolderOpenException) {
        _showSnackBar(error.message);
        return;
      }
      _showSnackBar('打开日志文件夹失败');
    }
  }

  Future<void> _exportDiagnostics(SettingsService settings) async {
    if (_exportingDiagnostics) return;
    setState(() => _exportingDiagnostics = true);
    try {
      final service = DiagnosticExportService();
      final tempPath = await service.export(settings: settings);
      if (!mounted) return;

      final fileName = tempPath.split(Platform.pathSeparator).last;
      final targetPath = await FilePicker.saveFile(
        dialogTitle: '保存诊断报告',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (targetPath == null || targetPath.trim().isEmpty) {
        if (mounted) _showSnackBar('已取消导出');
        return;
      }

      if (targetPath != tempPath) {
        await File(tempPath).copy(targetPath);
      }
      if (mounted) _showSnackBar('诊断报告已导出');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('导出诊断报告失败：$error');
    } finally {
      if (mounted) {
        setState(() => _exportingDiagnostics = false);
      }
    }
  }

  Future<void> _openExternalUrl(Uri uri) async {
    try {
      await _externalUrlLauncher.open(uri);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(_friendlyUpdateError(error));
    }
  }

  String _friendlyUpdateError(Object error) {
    if (error is AppUpdateException) return error.message;
    if (error is AppUpdateInstallException) return error.message;
    if (error is ExternalUrlOpenException) return error.message;
    return '检查更新失败，请稍后重试';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
