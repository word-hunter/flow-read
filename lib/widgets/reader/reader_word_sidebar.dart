import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flow_dictionary/flow_dictionary.dart';
import '../../models/user_vocabulary.dart';
import '../../providers/reading/services_provider.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import 'package:flow_design_system/flow_design_system.dart';
import '../dictionary_detail_view.dart';
import '../visual_hint_card.dart';
import '../word_mastery_confetti.dart';

class ReaderWordSidebar extends riverpod.ConsumerWidget {
  final VoidCallback? onClose;

  const ReaderWordSidebar({super.key, this.onClose});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    final theme = Theme.of(context);
    final word = lookupState.selectedWord;

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
                : _buildLookupLayout(
                    ref,
                    lookupState,
                    lookupNotifier,
                    word,
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
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: '收起侧栏',
              onPressed: onClose,
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
    riverpod.WidgetRef ref,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    String word,
  ) {
    final visualDefinition = lookupState.visualDefinition;
    final isLoadingVisualHint = lookupState.isLoadingVisualHint;
    final hasVisualHint = visualDefinition != null || isLoadingVisualHint;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: DictionaryDetailView.fromWordLookup(
              word: word,
              lookupState: lookupState,
              lookupNotifier: lookupNotifier,
              showVisualHint: false,
              wordLevelService: ref.read(wordLevelServiceProvider),
              canPronounceWords: true,
            ),
          ),
        ),
        if (hasVisualHint)
          _SidebarVisualHintSection(
            visualDefinition: visualDefinition,
          ),
        _WordStatusBar(word: word),
      ],
    );
  }
}

class _SidebarVisualHintSection extends StatelessWidget {
  final VisualDefinition? visualDefinition;

  const _SidebarVisualHintSection({required this.visualDefinition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: visualDefinition != null
          ? VisualHintCard(definition: visualDefinition!)
          : const VisualHintLoadingIndicator(),
    );
  }
}

class _WordStatusBar extends riverpod.ConsumerWidget {
  final String word;

  const _WordStatusBar({required this.word});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(vocabularyNotifierProvider);
    final theme = Theme.of(context);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    final status = vocabularyNotifier.getWordStatus(word);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          if (status != UserWordStatus.known)
            WordMasteryActionAnchor(
              builder: (context, origin) => _statusChip(
                theme: theme,
                label: '已掌握',
                icon: Icons.check_circle_outline,
                color: FunctionalColors.familiarityHigh,
                onTap: () => vocabularyNotifier.markWordKnown(
                  word,
                  celebrationOrigin: origin(),
                ),
              ),
            ),
          if (status != UserWordStatus.learning)
            _statusChip(
              theme: theme,
              label: '学习中',
              icon: Icons.school_outlined,
              color: FunctionalColors.vocabLearning,
              onTap: () => vocabularyNotifier.markWordLearning(word),
            ),
          if (status != null)
            _statusChip(
              theme: theme,
              label: '未知',
              icon: Icons.help_outline,
              color: FunctionalColors.familiarityLow,
              onTap: () => vocabularyNotifier.markWordUnknown(word),
            ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _HoverStatusChip(
        label: label,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }
}

class _HoverStatusChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HoverStatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverStatusChip> createState() => _HoverStatusChipState();
}

class _HoverStatusChipState extends State<_HoverStatusChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.12) : null,
            border: Border.all(
              color: color.withValues(alpha: _hovered ? 0.5 : 0.3),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
