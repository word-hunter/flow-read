import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_vocabulary.dart';
import '../../models/word_level.dart';
import '../../providers/reading_provider.dart';
import '../../theme/app_colors.dart';
import '../imported_word_examples.dart';

class ReaderWordSidebar extends StatefulWidget {
  final VoidCallback? onClose;

  const ReaderWordSidebar({super.key, this.onClose});

  @override
  State<ReaderWordSidebar> createState() => _ReaderWordSidebarState();
}

class _ReaderWordSidebarState extends State<ReaderWordSidebar> {
  bool _showAIAnalysis = false;
  String? _previousWord;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final word = provider.selectedWord;

    if (word != _previousWord) {
      _previousWord = word;
      _showAIAnalysis = false;
    }

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: word == null
                ? _buildEmptyState(theme)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: _buildLearningPanel(provider, theme, word),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '词典',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: '收起侧栏',
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '点击文中生词查看释义',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPanel(
    ReadingProvider provider,
    ThemeData theme,
    String word,
  ) {
    final status = provider.getWordStatus(word);
    final isBookmarked = provider.isBookmarked(word);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWordSection(provider, theme, word),
        const SizedBox(height: 22),
        _buildDefinitionSection(provider, theme, word),
        const SizedBox(height: 22),
        _buildContextSection(provider, theme, word),
        const SizedBox(height: 22),
        _buildLearningStatusSection(provider, theme, word, status),
        const SizedBox(height: 22),
        _buildOperationsSection(provider, theme, word, isBookmarked),
      ],
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildWordSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
  ) {
    final levelService = provider.wordLevelService;
    LevelKey? level;
    if (levelService != null && levelService.hasWord(word)) {
      level = levelService.getLevel(word);
    }
    final sourceName = provider.selectedWordEntry?.sourceName;
    final phonetic = provider.selectedWordEntry?.phonetic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, '单词'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Serif',
                  color: theme.colorScheme.onSurface,
                  height: 1.05,
                ),
              ),
            ),
            if (provider.isLoadingWord)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (phonetic != null && phonetic.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            phonetic,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (level != null || sourceName != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (level != null)
                _buildMetaChip(
                  theme,
                  '${level.shortLabel} ${level.label}',
                  _levelColor(level),
                ),
              if (sourceName != null)
                _buildMetaChip(
                  theme,
                  sourceName,
                  theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetaChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _levelColor(LevelKey level) {
    switch (level) {
      case LevelKey.p:
        return Colors.green;
      case LevelKey.m:
        return Colors.teal;
      case LevelKey.h:
        return Colors.blue;
      case LevelKey.cet4:
        return Colors.orange;
      case LevelKey.cet6:
        return Colors.deepOrange;
      case LevelKey.gre:
        return Colors.red;
      case LevelKey.other:
        return Colors.grey;
    }
  }

  Widget _buildDefinitionSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
  ) {
    if (provider.isLoadingWord) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(theme, '释义'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ],
      );
    }

    final entry = provider.selectedWordEntry;
    final primaryDefinition = provider.selectedWordTranslation?.trim();
    final importedExamples = provider.importedExamplesFor(word);
    final hasContent =
        entry != null ||
        (primaryDefinition != null && primaryDefinition.isNotEmpty) ||
        importedExamples.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, '释义'),
        if (!hasContent)
          Text(
            '未找到释义，请检查拼写或网络连接。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          if (primaryDefinition != null && primaryDefinition.isNotEmpty)
            _buildDefinitionCard(theme, primaryDefinition),
          if (entry != null) ...[
            if (primaryDefinition != null && primaryDefinition.isNotEmpty)
              const SizedBox(height: 12),
            ...entry.meanings.map((meaning) {
              final definitions = meaning.definitions
                  .where((definition) => definition.trim() != primaryDefinition)
                  .toList();
              if (definitions.isEmpty && meaning.partOfSpeech.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meaning.partOfSpeech.isNotEmpty)
                      _buildPartOfSpeechChip(theme, meaning.partOfSpeech),
                    if (definitions.isNotEmpty) const SizedBox(height: 6),
                    ...definitions.take(4).map((definition) {
                      final isExample = definition.startsWith('Example:');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          definition,
                          style:
                              (isExample
                                      ? theme.textTheme.bodySmall
                                      : theme.textTheme.bodyMedium)
                                  ?.copyWith(
                                    color: isExample
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.onSurface,
                                    fontStyle: isExample
                                        ? FontStyle.italic
                                        : null,
                                    height: 1.35,
                                  ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
          if (importedExamples.isNotEmpty) ...[
            const SizedBox(height: 4),
            ImportedWordExamples(examples: importedExamples),
          ],
        ],
      ],
    );
  }

  Widget _buildDefinitionCard(ThemeData theme, String definition) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        definition,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildPartOfSpeechChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContextSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
  ) {
    final contextText = provider.selectedWordContext?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, '原文语境'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: contextText == null || contextText.isEmpty
              ? Text(
                  '暂无原文语境',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Text.rich(
                  _highlightContext(theme, contextText, word),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
        ),
      ],
    );
  }

  TextSpan _highlightContext(ThemeData theme, String contextText, String word) {
    final lowerContext = contextText.toLowerCase();
    final lowerWord = word.toLowerCase();
    final index = lowerContext.indexOf(lowerWord);
    if (index < 0) {
      return TextSpan(
        text: contextText,
        style: TextStyle(color: theme.colorScheme.onSurface),
      );
    }

    return TextSpan(
      style: TextStyle(color: theme.colorScheme.onSurface),
      children: [
        TextSpan(text: contextText.substring(0, index)),
        TextSpan(
          text: contextText.substring(index, index + word.length),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: contextText.substring(index + word.length)),
      ],
    );
  }

  Widget _buildLearningStatusSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
    UserWordStatus? status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, '学习状态'),
        Row(
          children: [
            Expanded(
              child: _statusButton(
                theme: theme,
                label: '已掌握',
                icon: Icons.check_circle_outline,
                color: AppColors.familiarityHigh,
                selected: status == UserWordStatus.known,
                onPressed: () => provider.markWordKnown(word),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statusButton(
                theme: theme,
                label: '学习中',
                icon: Icons.school_outlined,
                color: AppColors.vocabLearning,
                selected: status == UserWordStatus.learning,
                onPressed: () => provider.markWordLearning(word),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: selected ? color.withValues(alpha: 0.10) : null,
        side: BorderSide(
          color: color.withValues(alpha: selected ? 0.65 : 0.35),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOperationsSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
    bool isBookmarked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, '操作'),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: provider.selectedWordTranslation == null || isBookmarked
                ? null
                : () {
                    provider.addBookmark(
                      word,
                      provider.selectedWordTranslation!,
                    );
                    setState(() {});
                  },
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
            ),
            label: Text(isBookmarked ? '已加入生词本' : '加入生词本'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: provider.isAnalyzingWord
                ? null
                : () {
                    setState(() => _showAIAnalysis = !_showAIAnalysis);
                    if (_showAIAnalysis) {
                      provider.analyzeWordAI(
                        word,
                        _analysisContext(provider, word),
                      );
                    }
                  },
            icon: Icon(
              Icons.psychology,
              size: 20,
              color: AppColors.vocabLearning,
            ),
            label: Text(_showAIAnalysis ? '收起 AI 详解' : 'AI 详解这个词'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.vocabLearning,
              side: BorderSide(
                color: AppColors.vocabLearning.withValues(alpha: 0.35),
              ),
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (_showAIAnalysis) ...[
          const SizedBox(height: 12),
          _buildAIAnalysisContent(provider, theme),
        ],
      ],
    );
  }

  String _analysisContext(ReadingProvider provider, String word) {
    final contextText = provider.selectedWordContext?.trim();
    if (contextText != null && contextText.isNotEmpty) return contextText;
    final firstMeaning = provider.selectedWordEntry?.meanings.firstOrNull;
    final definition = firstMeaning?.definitions.firstOrNull;
    if (definition != null && definition.trim().isNotEmpty) {
      return definition.trim();
    }
    return provider.selectedWordTranslation ?? word;
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
        borderRadius: BorderRadius.circular(8),
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
                Flexible(
                  child: Text(
                    analysis.pronunciation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
