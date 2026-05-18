import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import 'dictionary_detail_view.dart';

class WordBottomSheet extends StatefulWidget {
  final String word;

  const WordBottomSheet({super.key, required this.word});

  @override
  State<WordBottomSheet> createState() => _WordBottomSheetState();
}

class _WordBottomSheetState extends State<WordBottomSheet> {
  bool _bookmarkAdded = false;
  bool _showAIAnalysis = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);
    final isBookmarked = provider.isBookmarked(widget.word) || _bookmarkAdded;
    final status = provider.getWordStatus(widget.word);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.85,
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildContent(provider),
                ),
              ),
              _buildBottomActions(
                provider,
                settings,
                theme,
                status,
                isBookmarked,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
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

  Widget _buildContent(ReadingProvider provider) {
    return DictionaryDetailView.fromProvider(
      provider: provider,
      word: widget.word,
    );
  }

  Widget _buildBottomActions(
    ReadingProvider provider,
    SettingsService settings,
    ThemeData theme,
    UserWordStatus? status,
    bool isBookmarked,
  ) {
    final canToggleAIAnalysis = _showAIAnalysis || settings.aiFeaturesEnabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.isAnalyzingWord || !canToggleAIAnalysis
                  ? null
                  : () {
                      setState(() => _showAIAnalysis = !_showAIAnalysis);
                      if (_showAIAnalysis) {
                        provider.analyzeWordAI(
                          widget.word,
                          provider
                                  .selectedWordEntry
                                  ?.meanings
                                  .firstOrNull
                                  ?.definitions
                                  .firstOrNull ??
                              widget.word,
                        );
                      }
                    },
              icon: _showAIAnalysis
                  ? const Icon(
                      Icons.psychology,
                      size: 20,
                      color: AppColors.vocabLearning,
                    )
                  : const Icon(Icons.psychology, size: 20),
              label: Text(
                _showAIAnalysis ? '收起 AI 详解' : 'AI 详解此词',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 14,
                ),
                side: BorderSide(
                  color: AppColors.vocabLearning.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          if (_showAIAnalysis) ...[
            const SizedBox(height: 8),
            _buildAIAnalysisContent(provider, theme),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (status != UserWordStatus.known)
                Expanded(
                  child: _actionButton(
                    theme: theme,
                    label: 'Known',
                    icon: Icons.check_circle_outline,
                    color: AppColors.familiarityHigh,
                    onPressed: () => provider.markWordKnown(widget.word),
                  ),
                ),
              if (status != UserWordStatus.learning)
                Expanded(
                  child: _actionButton(
                    theme: theme,
                    label: 'Learning',
                    icon: Icons.school_outlined,
                    color: AppColors.vocabLearning,
                    onPressed: () => provider.markWordLearning(widget.word),
                  ),
                ),
              if (status != null)
                Expanded(
                  child: _actionButton(
                    theme: theme,
                    label: 'Unknown',
                    icon: Icons.help_outline,
                    color: AppColors.familiarityLow,
                    onPressed: () => provider.markWordUnknown(widget.word),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          isBookmarked
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已加入生词本',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: provider.selectedWordTranslation != null
                        ? () {
                            provider.addBookmark(
                              widget.word,
                              provider.selectedWordTranslation!,
                            );
                            setState(() => _bookmarkAdded = true);
                          }
                        : null,
                    icon: const Icon(Icons.bookmark_border, size: 22),
                    label: const Text('加入生词本'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 18,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildAIAnalysisContent(ReadingProvider provider, ThemeData theme) {
    if (provider.isAnalyzingWord) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final analysis = provider.aiWordAnalysis;
    if (analysis == null || analysis.isEmpty) {
      return Text(
        '尚未生成 AI 详解',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vocabLearning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.vocabLearning.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysis.pronunciation.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.volume_up, size: 16, color: AppColors.vocabLearning),
                const SizedBox(width: 6),
                Text(
                  analysis.pronunciation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ...analysis.meanings.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.meaning,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (m.explanation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      m.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (analysis.usageTips.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '用法提示',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.vocabLearning,
              ),
            ),
            const SizedBox(height: 4),
            ...analysis.usageTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.vocabLearning,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (analysis.memoryTip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analysis.memoryTip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
