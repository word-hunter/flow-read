import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_vocabulary.dart';
import '../../providers/reading_provider.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../dictionary_detail_view.dart';
import '../pronunciation_button.dart';
import '../word_mastery_confetti.dart';

enum _WordAction { known, learning }

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
    final settings = context.watch<SettingsService>();
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
                : _buildLookupLayout(provider, settings, theme, word),
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

  Widget _buildLookupLayout(
    ReadingProvider provider,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    final status = provider.getWordStatus(word);
    final isBookmarked = provider.isBookmarked(word);

    return LayoutBuilder(
      builder: (context, constraints) {
        final persistentPanelMaxHeight = constraints.maxHeight * 0.54;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                child: DictionaryDetailView.fromProvider(
                  provider: provider,
                  word: word,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: persistentPanelMaxHeight),
              child: _buildPersistentLearningPanel(
                provider,
                settings,
                theme,
                word,
                status,
                isBookmarked,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersistentLearningPanel(
    ReadingProvider provider,
    SettingsService settings,
    ThemeData theme,
    String word,
    UserWordStatus? status,
    bool isBookmarked,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContextSection(provider, settings, theme, word),
            const SizedBox(height: 16),
            _buildLearningStatusSection(
              provider,
              theme,
              word,
              status,
              isBookmarked,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSection(
    ReadingProvider provider,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DictionaryContextBlock(
          word: word,
          contextText: provider.selectedWordContext,
          contextWordStart: provider.selectedWordContextStart,
          contextWordEnd: provider.selectedWordContextEnd,
          trailing: _buildAIContextAction(provider, settings, theme, word),
        ),
        if (_showAIAnalysis) ...[
          const SizedBox(height: 10),
          _buildAIAnalysisContent(provider, theme, word),
        ],
      ],
    );
  }

  Widget _buildAIContextAction(
    ReadingProvider provider,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    final canToggleAIAnalysis =
        _showAIAnalysis ||
        (settings.aiFeaturesEnabled && provider.aiFeaturesEnabled);
    final disabledReason = settings.aiFeaturesEnabled
        ? provider.aiFeatureDisabledReason
        : settings.aiFeatureDisabledReason;
    return IconButton(
      tooltip: _showAIAnalysis
          ? '收起 AI 详解'
          : canToggleAIAnalysis
          ? 'AI 详解语境'
          : disabledReason,
      onPressed: provider.isAnalyzingWord && !_showAIAnalysis
          ? null
          : canToggleAIAnalysis
          ? () {
              setState(() => _showAIAnalysis = !_showAIAnalysis);
              if (_showAIAnalysis) {
                provider.analyzeWordAI(word, _analysisContext(provider, word));
              }
            }
          : null,
      icon: Icon(
        _showAIAnalysis ? Icons.auto_awesome : Icons.auto_awesome_outlined,
        size: 20,
      ),
      color: _showAIAnalysis
          ? AppColors.vocabLearning
          : theme.colorScheme.onSurfaceVariant,
      selectedIcon: const Icon(Icons.auto_awesome, size: 20),
      isSelected: _showAIAnalysis,
      style: IconButton.styleFrom(
        backgroundColor: _showAIAnalysis
            ? AppColors.vocabLearning.withValues(alpha: 0.10)
            : null,
        hoverColor: AppColors.vocabLearning.withValues(alpha: 0.10),
        disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.35,
        ),
        enabledMouseCursor: SystemMouseCursors.click,
        disabledMouseCursor: SystemMouseCursors.basic,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLearningStatusSection(
    ReadingProvider provider,
    ThemeData theme,
    String word,
    UserWordStatus? status,
    bool isBookmarked,
  ) {
    final selected = _selectedWordAction(status, isBookmarked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: WordMasteryActionAnchor(
            builder: (context, origin) => SegmentedButton<_WordAction>(
              selected: selected == null ? const {} : {selected},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  _markWordUnknown(provider, word);
                  return;
                }
                _applyWordAction(
                  provider,
                  word,
                  selection.single,
                  celebrationOrigin: origin,
                );
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                mouseCursor: const WidgetStatePropertyAll(
                  SystemMouseCursors.click,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: _WordAction.known,
                  icon: Icon(Icons.check_circle_outline, size: 17),
                  label: Text('已掌握'),
                ),
                ButtonSegment(
                  value: _WordAction.learning,
                  icon: Icon(Icons.bookmark_border, size: 17),
                  label: Text('生词本'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _WordAction? _selectedWordAction(UserWordStatus? status, bool isBookmarked) {
    if (status == UserWordStatus.known) return _WordAction.known;
    if (status == UserWordStatus.learning || isBookmarked) {
      return _WordAction.learning;
    }
    return null;
  }

  Future<void> _applyWordAction(
    ReadingProvider provider,
    String word,
    _WordAction action, {
    Offset? Function()? celebrationOrigin,
  }) async {
    switch (action) {
      case _WordAction.known:
        await provider.markWordKnown(
          word,
          celebrationOrigin: celebrationOrigin?.call(),
        );
        break;
      case _WordAction.learning:
        await _addToLearning(provider, word);
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _markWordUnknown(ReadingProvider provider, String word) async {
    await provider.markWordUnknown(word);
    if (provider.isBookmarked(word)) {
      provider.removeBookmark(word);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addToLearning(ReadingProvider provider, String word) async {
    await provider.markWordLearning(word);
    final translation = provider.selectedWordTranslation?.trim();
    if (translation != null &&
        translation.isNotEmpty &&
        !provider.isBookmarked(word)) {
      provider.addBookmark(word, translation);
    }
    if (mounted) setState(() {});
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

  Widget _buildAIAnalysisContent(
    ReadingProvider provider,
    ThemeData theme,
    String word,
  ) {
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
                if (provider.canPronounceWords)
                  PronunciationButton(
                    word: word,
                    onSpeakWord: provider.speakWord,
                    buttonSize: 28,
                    iconSize: 16,
                  )
                else
                  Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: AppColors.vocabLearning.withValues(alpha: 0.45),
                  ),
                const SizedBox(width: 4),
                Flexible(
                  child: DictionaryPhoneticText(
                    text: analysis.pronunciation,
                    style: theme.textTheme.bodySmall?.copyWith(
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
