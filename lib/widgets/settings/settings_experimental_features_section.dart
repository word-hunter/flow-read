import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reading/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/external_url_launcher.dart';
import '../../services/reading_memory/reading_memory_inspector_web_server.dart';
import '../../services/settings_service.dart';
import '../../storage/database/dao/reading_memory_dao.dart';
import 'settings_shared.dart';

class SettingsExperimentalFeaturesSection extends StatelessWidget {
  const SettingsExperimentalFeaturesSection({
    super.key,
    required this.settings,
  });

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.list_alt_outlined,
          title: '测试项列表',
          child: Column(
            children: [
              _ExperimentalFeatureTile(
                icon: Icons.rss_feed_outlined,
                title: 'RSS 入口',
                subtitle: '在首页显示 RSS 订阅与最新内容入口',
                value: settings.rssFeatureEnabled,
                onChanged: settings.setRssFeatureEnabled,
              ),
              const Divider(height: 1),
              _ExperimentalFeatureTile(
                icon: Icons.replay_outlined,
                title: '轻量复习',
                subtitle: '显示首页今日复习和训练页复习入口',
                value: settings.reviewFeatureEnabled,
                onChanged: settings.setReviewFeatureEnabled,
              ),
              const Divider(height: 1),
              _ExperimentalFeatureTile(
                icon: Icons.auto_stories_outlined,
                title: '强制默认封面',
                subtitle: '在 V2 书架中忽略 EPUB 封面，统一使用 Flow Read 默认封面',
                value: settings.forceDefaultBookCover,
                onChanged: settings.setForceDefaultBookCover,
              ),
              if (kDebugMode) ...[
                const Divider(height: 1),
                const _DebugInspectorTile(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugInspectorTile extends ConsumerStatefulWidget {
  const _DebugInspectorTile();

  @override
  ConsumerState<_DebugInspectorTile> createState() =>
      _DebugInspectorTileState();
}

class _DebugInspectorTileState extends ConsumerState<_DebugInspectorTile> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(appDatabaseProvider);
    final languageCode = ref.watch(settingsProvider).activeSourceLanguage;

    return database.when(
      data: (db) => _buildTile(
        context,
        enabled: !_opening,
        subtitle: '在浏览器打开只读 Web Inspector',
        trailing: _opening
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.open_in_new),
        onTap: _opening
            ? null
            : () => _openWebInspector(
                dao: db.readingMemoryDao,
                languageCode: languageCode,
              ),
      ),
      error: (error, _) => _buildTile(
        context,
        enabled: false,
        subtitle: '数据库不可用：$error',
        trailing: const Icon(Icons.error_outline),
        onTap: null,
      ),
      loading: () => _buildTile(
        context,
        enabled: false,
        subtitle: '正在准备数据库',
        trailing: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        onTap: null,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required bool enabled,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.storage_outlined),
      title: const Text('Reading Memory Inspector'),
      subtitle: Text(subtitle),
      trailing: trailing,
      enabled: enabled,
      onTap: onTap,
    );
  }

  Future<void> _openWebInspector({
    required ReadingMemoryDao dao,
    required String languageCode,
  }) async {
    setState(() => _opening = true);
    try {
      final uri = await ReadingMemoryInspectorWebLauncher.open(
        dao: dao,
        languageCode: languageCode,
      );
      await const ExternalUrlLauncher().open(uri);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开 Web Inspector 失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }
}

class _ExperimentalFeatureTile extends StatelessWidget {
  const _ExperimentalFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
