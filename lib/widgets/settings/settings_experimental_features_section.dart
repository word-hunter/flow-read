import 'package:flutter/material.dart';

import '../../services/settings_service.dart';
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
            ],
          ),
        ),
      ],
    );
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
