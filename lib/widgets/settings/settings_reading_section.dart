import 'package:flutter/material.dart';
import 'package:flow_language/flow_language.dart';

import '../../models/book_metadata.dart';
import '../../services/settings_service.dart';
import 'settings_shared.dart';

class SettingsReadingSection extends StatelessWidget {
  const SettingsReadingSection({
    super.key,
    required this.settings,
    required this.activeBookMetadata,
    required this.onBookSourceLanguageChanged,
    required this.onClearBookSourceLanguageOverride,
  });

  final SettingsService settings;
  final BookMetadata? activeBookMetadata;
  final Future<void> Function(String bookId, String code)
  onBookSourceLanguageChanged;
  final Future<void> Function(String bookId) onClearBookSourceLanguageOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMinutes = settings.dailyReadingGoalMinutes;
    final weeklyMinutes = currentMinutes * 6;
    final languageModules = LanguageRegistry.instance.modules;
    final languageOptions = languageModules.isEmpty
        ? const [LanguageOption(code: 'en', name: 'English')]
        : languageModules
              .map(
                (module) => LanguageOption(
                  code: module.languageCode,
                  name: module.languageName,
                ),
              )
              .toList();
    final selectedLanguage =
        languageOptions.any(
          (option) => option.code == settings.activeSourceLanguage,
        )
        ? settings.activeSourceLanguage
        : 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: Icons.flag_outlined,
          title: '每日目标',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '每日 ${_formatDuration(currentMinutes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: currentMinutes.toDouble(),
                min: SettingsService.minDailyReadingGoalMinutes.toDouble(),
                max: SettingsService.maxDailyReadingGoalMinutes.toDouble(),
                divisions:
                    (SettingsService.maxDailyReadingGoalMinutes -
                        SettingsService.minDailyReadingGoalMinutes) ~/
                    SettingsService.dailyReadingGoalStepMinutes,
                label: _formatDuration(currentMinutes),
                onChanged: (value) {
                  settings.setDailyReadingGoalMinutes(value.round());
                },
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatDuration(SettingsService.minDailyReadingGoalMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(SettingsService.maxDailyReadingGoalMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SettingsStatusLine(
                icon: Icons.calendar_view_week_outlined,
                text: '周目标 ${_formatDuration(weeklyMinutes)}',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: Icons.translate_outlined,
          title: '内容语言',
          child: SegmentedButton<String>(
            segments: [
              for (final option in languageOptions)
                ButtonSegment<String>(
                  value: option.code,
                  label: Text(option.name),
                ),
            ],
            selected: {selectedLanguage},
            onSelectionChanged: (value) {
              if (value.isEmpty) return;
              settings.setActiveSourceLanguage(value.first);
            },
          ),
        ),
        if (activeBookMetadata != null) ...[
          const SizedBox(height: 16),
          _BookLanguageSection(
            metadata: activeBookMetadata!,
            languageOptions: languageOptions,
            onLanguageChanged: onBookSourceLanguageChanged,
            onClearOverride: onClearBookSourceLanguageOverride,
          ),
        ],
      ],
    );
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分钟';
  }
}
class _BookLanguageSection extends StatelessWidget {
  const _BookLanguageSection({
    required this.metadata,
    required this.languageOptions,
    required this.onLanguageChanged,
    required this.onClearOverride,
  });

  final BookMetadata metadata;
  final List<LanguageOption> languageOptions;
  final Future<void> Function(String bookId, String code) onLanguageChanged;
  final Future<void> Function(String bookId) onClearOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLanguage = metadata.effectiveSourceLanguage
        .toLowerCase()
        .trim();
    final options = _mergedOptions(effectiveLanguage);
    final detectedLanguage = metadata.sourceLanguage?.toLowerCase().trim();
    final overrideLanguage = metadata.sourceLanguageOverride
        ?.toLowerCase()
        .trim();

    return SettingsCard(
      icon: Icons.travel_explore_outlined,
      title: '当前书籍语言',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSettingsGrid(
            children: [
              DropdownButtonFormField<String>(
                initialValue: effectiveLanguage,
                decoration: const InputDecoration(
                  labelText: '原文语言',
                  prefixIcon: Icon(Icons.translate_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
                items: options
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.code,
                        child: Text(option.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onLanguageChanged(metadata.id, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsStatusLine(
            icon: Icons.manage_search_outlined,
            text:
                '自动检测：${_languageName(detectedLanguage)} · 置信度 ${_formatConfidence(metadata.languageConfidence)}',
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          SettingsStatusLine(
            icon: overrideLanguage == null
                ? Icons.check_circle_outline
                : Icons.edit_outlined,
            text: overrideLanguage == null
                ? '当前使用自动检测语言'
                : '当前覆盖：${_languageName(overrideLanguage)}',
            color: overrideLanguage == null
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),
          if (overrideLanguage != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onClearOverride(metadata.id),
              icon: const Icon(Icons.restart_alt_outlined, size: 18),
              label: const Text('恢复自动检测'),
            ),
          ],
        ],
      ),
    );
  }

  List<LanguageOption> _mergedOptions(String effectiveLanguage) {
    final merged = [...languageOptions];
    final hasEffective = merged.any(
      (option) => option.code == effectiveLanguage,
    );
    if (!hasEffective && effectiveLanguage.isNotEmpty) {
      merged.add(
        LanguageOption(
          code: effectiveLanguage,
          name: effectiveLanguage.toUpperCase(),
        ),
      );
    }
    return merged;
  }

  String _languageName(String? code) {
    if (code == null || code.isEmpty) return '未检测';
    for (final option in languageOptions) {
      if (option.code == code) return option.name;
    }
    return code.toUpperCase();
  }

  String _formatConfidence(double? confidence) {
    if (confidence == null) return '未知';
    return '${(confidence.clamp(0, 1) * 100).round()}%';
  }
}
