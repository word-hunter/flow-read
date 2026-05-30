import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_chapter_preview.dart';
import '../models/ai_summary.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';

class AISummaryView extends StatefulWidget {
  const AISummaryView({super.key});

  @override
  State<AISummaryView> createState() => _AISummaryViewState();
}

class _AISummaryViewState extends State<AISummaryView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(theme, provider),
              _buildLanguageToggle(theme, provider, settings.aiFeaturesEnabled),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              Expanded(
                child: provider.isGeneratingSummary
                    ? _buildLoadingView(theme)
                    : provider.aiSummary == null || provider.aiSummary!.isEmpty
                    ? _buildEmptyView(theme, provider, settings)
                    : _buildSummaryContent(
                        scrollController,
                        provider.aiSummary!,
                        theme,
                        provider,
                        settings.aiFeaturesEnabled,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ReadingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(
    ThemeData theme,
    ReadingProvider provider,
    bool aiFeaturesEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Icon(Icons.summarize, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            '章节总结',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'zh', label: Text('中文')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {provider.summaryLanguage},
            onSelectionChanged: aiFeaturesEnabled
                ? (value) {
                    provider.toggleSummaryLanguage();
                    provider.generateSummary();
                  }
                : null,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在生成总结...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(
    ThemeData theme,
    ReadingProvider provider,
    SettingsService settings,
  ) {
    final aiFeaturesEnabled = settings.aiFeaturesEnabled;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            aiFeaturesEnabled ? '暂无总结' : settings.aiFeatureDisabledReason,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isGeneratingChapterPreview) ...[
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
          ] else if (provider.aiChapterPreview != null &&
              !provider.aiChapterPreview!.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPreviewSection(
                provider.aiChapterPreview!,
                theme,
                compact: true,
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: aiFeaturesEnabled && !provider.isGeneratingChapterPreview
                ? () => provider.generateChapterPreview()
                : null,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('生成读前预览'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: aiFeaturesEnabled
                ? () => provider.generateSummary()
                : null,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('生成 AI 总结'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(
    ScrollController scrollController,
    AISummary summary,
    ThemeData theme,
    ReadingProvider provider,
    bool aiFeaturesEnabled,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.aiChapterPreview != null &&
              !provider.aiChapterPreview!.isEmpty) ...[
            _buildPreviewSection(provider.aiChapterPreview!, theme),
            const SizedBox(height: 20),
          ],
          if (summary.events.isNotEmpty) ...[
            _buildSectionHeader(theme, '关键事件', Icons.event_note),
            ...summary.events.map((e) => _buildEventCard(e, theme)),
            const SizedBox(height: 20),
          ],
          if (summary.characterDevelopments.isNotEmpty) ...[
            _buildSectionHeader(theme, '角色发展', Icons.person),
            ...summary.characterDevelopments.map(
              (c) => _buildCharacterCard(c, theme),
            ),
            const SizedBox(height: 20),
          ],
          if (summary.keyVocabulary.isNotEmpty) ...[
            _buildSectionHeader(theme, '重点词汇', Icons.menu_book),
            ...summary.keyVocabulary.map((v) => _buildVocabCard(v, theme)),
            const SizedBox(height: 20),
          ],
          if (summary.readingGuidance.isNotEmpty) ...[
            _buildSectionHeader(theme, '阅读建议', Icons.lightbulb),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                summary.readingGuidance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: FilledButton.icon(
              onPressed: aiFeaturesEnabled
                  ? () {
                      provider.generatePractice();
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.quiz, size: 18),
              label: const Text('生成练习题'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(
    AIChapterPreview preview,
    ThemeData theme, {
    bool compact = false,
  }) {
    final content = <Widget>[
      if (preview.setup.isNotEmpty)
        Text(
          preview.setup,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.45,
          ),
        ),
      if (preview.focusPoints.isNotEmpty) ...[
        if (preview.setup.isNotEmpty) const SizedBox(height: 10),
        ...preview.focusPoints.map(
          (point) =>
              _PreviewBullet(text: point, icon: Icons.center_focus_strong),
        ),
      ],
      if (!compact && preview.vocabularyHints.isNotEmpty) ...[
        const SizedBox(height: 8),
        ...preview.vocabularyHints.map(
          (hint) => _PreviewBullet(text: hint, icon: Icons.menu_book_outlined),
        ),
      ],
      if (!compact && preview.spoilerBoundaryNote.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          preview.spoilerBoundaryNote,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, '读前预览', Icons.visibility_outlined),
          ...content,
        ],
      ),
    );
  }

  Widget _buildEventCard(SummaryEvent event, ThemeData theme) {
    final confidenceColor = event.confidence == 'high'
        ? Colors.green
        : event.confidence == 'medium'
        ? Colors.orange
        : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.confidence,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: confidenceColor,
                    ),
                  ),
                ),
              ],
            ),
            if (event.source.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '"${event.source}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (event.significance.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                event.significance,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(CharacterDevelopment cd, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    cd.character.isNotEmpty
                        ? cd.character[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cd.character,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cd.change,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabCard(KeyVocabulary vocab, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vocab.word,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.vocabLearning,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vocab.meaningInContext,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (vocab.sentence.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vocab.sentence,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewBullet extends StatelessWidget {
  final String text;
  final IconData icon;

  const _PreviewBullet({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
