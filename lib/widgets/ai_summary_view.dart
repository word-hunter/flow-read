import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flow_ai/flow_ai.dart';
import '../providers/reading/ai_notifier.dart';
import '../providers/reading/current_book_notifier.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import 'package:flow_design_system/flow_design_system.dart';
import 'flow/flow_components.dart';

class AISummaryView extends riverpod.ConsumerStatefulWidget {
  const AISummaryView({super.key});

  @override
  riverpod.ConsumerState<AISummaryView> createState() => _AISummaryViewState();
}

class _AISummaryViewState extends riverpod.ConsumerState<AISummaryView> {
  bool _requestedCoverage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedCoverage) return;
    _requestedCoverage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final aiNotifier = ref.read(aiNotifierProvider.notifier);
      final aiState = ref.read(aiNotifierProvider);
      if (aiState.chapterAISummaryCoverage == null &&
          !aiState.isLoadingChapterAISummaryCoverage) {
        aiNotifier.refreshChapterAISummaryCoverage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiNotifierProvider);
    final aiNotifier = ref.read(aiNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final currentChapter = ref.read(currentBookNotifierProvider).currentChapter;
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
              _buildHeader(theme),
              _buildLanguageToggle(
                theme,
                aiState,
                aiNotifier,
                settings.aiFeaturesEnabled,
              ),
              _buildAIStatus(theme, aiState.chapterAIStatus),
              _buildSummaryCoverage(theme, aiState, currentChapter),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              Expanded(
                child: aiState.isGeneratingSummary
                    ? _buildLoadingView(theme)
                    : aiState.aiSummary == null || aiState.aiSummary!.isEmpty
                    ? _buildEmptyView(theme, aiState, aiNotifier, settings)
                    : _buildSummaryContent(
                        scrollController,
                        aiState.aiSummary!,
                        theme,
                        aiState,
                        aiNotifier,
                        settings.aiFeaturesEnabled,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
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

  Widget _buildSummaryCoverage(
    ThemeData theme,
    AIState aiState,
    int currentChapter,
  ) {
    final coverage = aiState.chapterAISummaryCoverage;
    if (!aiState.isLoadingChapterAISummaryCoverage && coverage == null) {
      return const SizedBox.shrink();
    }

    final message = coverage == null
        ? '正在读取已生成章节...'
        : _coverageMessage(coverage, currentChapter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _coverageMessage(
    ChapterAISummaryCoverage coverage,
    int currentChapter,
  ) {
    final currentState = coverage.isGenerated(currentChapter)
        ? '当前章已生成'
        : '当前章未生成';
    return '已生成 ${coverage.generatedCount}/${coverage.totalChapters} 章总结 · $currentState';
  }

  Widget _buildAIStatus(ThemeData theme, ChapterAIStatus? status) {
    if (status == null) return const SizedBox.shrink();

    final color = switch (status.kind) {
      ChapterAIStatusKind.unconfigured => theme.colorScheme.outline,
      ChapterAIStatusKind.loading => theme.colorScheme.primary,
      ChapterAIStatusKind.cacheHit => FunctionalColors.correct,
      ChapterAIStatusKind.failed => theme.colorScheme.error,
      ChapterAIStatusKind.fallback => theme.colorScheme.tertiary,
      ChapterAIStatusKind.generated => theme.colorScheme.primary,
    };
    final icon = switch (status.kind) {
      ChapterAIStatusKind.unconfigured => Icons.block_outlined,
      ChapterAIStatusKind.loading => Icons.sync,
      ChapterAIStatusKind.cacheHit => Icons.cached,
      ChapterAIStatusKind.failed => Icons.error_outline,
      ChapterAIStatusKind.fallback => Icons.info_outline,
      ChapterAIStatusKind.generated => Icons.check_circle_outline,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(
    ThemeData theme,
    AIState aiState,
    AINotifier aiNotifier,
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
            selected: {aiState.summaryLanguage},
            onSelectionChanged: aiFeaturesEnabled
                ? (value) {
                    aiNotifier.toggleSummaryLanguage();
                    aiNotifier.generateSummary();
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
    AIState aiState,
    AINotifier aiNotifier,
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
          if (aiState.isGeneratingChapterPreview) ...[
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
          ] else if (aiState.aiChapterPreview != null &&
              !aiState.aiChapterPreview!.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPreviewSection(
                aiState.aiChapterPreview!,
                theme,
                compact: true,
              ),
            ),
            const SizedBox(height: 16),
          ],
          FlowButton.secondary(
            onPressed: aiFeaturesEnabled && !aiState.isGeneratingChapterPreview
                ? () => aiNotifier.generateChapterPreview()
                : null,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            child: const Text('生成读前预览'),
          ),
          const SizedBox(height: 10),
          FlowButton.primary(
            onPressed: aiFeaturesEnabled
                ? () => aiNotifier.generateSummary()
                : null,
            icon: const Icon(Icons.auto_awesome, size: 18),
            child: const Text('生成 AI 总结'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(
    ScrollController scrollController,
    AISummary summary,
    ThemeData theme,
    AIState aiState,
    AINotifier aiNotifier,
    bool aiFeaturesEnabled,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aiState.aiChapterPreview != null &&
              !aiState.aiChapterPreview!.isEmpty) ...[
            _buildPreviewSection(aiState.aiChapterPreview!, theme),
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
            child: FlowButton.primary(
              onPressed: aiFeaturesEnabled
                  ? () {
                      aiNotifier.generatePractice();
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.quiz, size: 18),
              child: const Text('生成练习题'),
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
                color: FunctionalColors.vocabLearning,
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
