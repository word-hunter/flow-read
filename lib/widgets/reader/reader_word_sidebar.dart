import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flow_ai/flow_ai.dart';
import '../../models/user_vocabulary.dart';
import '../../providers/reading/ai_notifier.dart';
import '../../providers/reading/bookmark_notifier.dart';
import '../../providers/reading/services_provider.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../dictionary_detail_view.dart';
import '../word_mastery_confetti.dart';

enum _WordAction { known, learning }

class ReaderWordSidebar extends riverpod.ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onOpenAssistant;

  const ReaderWordSidebar({super.key, this.onClose, this.onOpenAssistant});

  @override
  riverpod.ConsumerState<ReaderWordSidebar> createState() =>
      _ReaderWordSidebarState();
}

class _ReaderWordSidebarState
    extends riverpod.ConsumerState<ReaderWordSidebar> {
  String? _previousWord;

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    ref.watch(bookmarkNotifierProvider);
    final bookmarkNotifier = ref.read(bookmarkNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final word = lookupState.selectedWord;

    if (word != _previousWord) {
      _previousWord = word;
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
                : _buildLookupLayout(
                    lookupState,
                    lookupNotifier,
                      vocabularyNotifier,
                      bookmarkNotifier,
                    settings,
                    theme,
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
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    final status = vocabularyNotifier.getWordStatus(word);
    final isBookmarked = bookmarkNotifier.isBookmarked(word);

    return LayoutBuilder(
      builder: (context, constraints) {
        final persistentPanelMaxHeight = constraints.maxHeight * 0.54;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                child: DictionaryDetailView.fromWordLookup(
                  lookupState: lookupState,
                  lookupNotifier: lookupNotifier,
                  word: word,
                  wordLevelService: ref.read(wordLevelServiceProvider),
                  canPronounceWords: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: persistentPanelMaxHeight),
              child: _buildPersistentLearningPanel(
                lookupState,
                lookupNotifier,
                vocabularyNotifier,
                bookmarkNotifier,
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
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
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
            _buildContextSection(lookupState, lookupNotifier, settings, theme, word),
            const SizedBox(height: 16),
            _buildLearningStatusSection(
              lookupState,
              lookupNotifier,
              vocabularyNotifier,
              bookmarkNotifier,
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
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DictionaryContextBlock(
          word: word,
          contextText: lookupState.selectedWordContext,
          contextWordStart: lookupState.selectedWordContextStart,
          contextWordEnd: lookupState.selectedWordContextEnd,
          trailing: _buildAIContextAction(lookupState, settings, theme, word),
        ),
      ],
    );
  }

  Widget _buildAIContextAction(
    WordLookupState lookupState,
    SettingsService settings,
    ThemeData theme,
    String word,
  ) {
    final aiNotifier = ref.read(aiNotifierProvider.notifier);
    final canToggleAIAnalysis =
        settings.aiFeaturesEnabled && aiNotifier.aiFeaturesEnabled;
    final disabledReason = settings.aiFeaturesEnabled
        ? aiNotifier.aiFeatureDisabledReason
        : settings.aiFeatureDisabledReason;
    return IconButton(
      tooltip: canToggleAIAnalysis ? 'AI 详解语境' : disabledReason,
      onPressed: canToggleAIAnalysis
          ? () {
              final assistant = ref.read(aiAssistantControllerProvider);
              assistant.setContext(
                AIContextSnapshot(
                  source: AIContextSource.readerWord,
                  word: word,
                  wordSentence: _analysisContext(lookupState, word),
                ),
              );
              widget.onOpenAssistant?.call();
            }
          : null,
      icon: const Icon(Icons.auto_awesome_outlined, size: 20),
      color: theme.colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
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
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
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
                  _markWordUnknown(vocabularyNotifier, bookmarkNotifier, word);
                  return;
                }
                _applyWordAction(
                  lookupState,
                  lookupNotifier,
                  vocabularyNotifier,
                  bookmarkNotifier,
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
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    String word,
    _WordAction action, {
    Offset? Function()? celebrationOrigin,
  }) async {
    switch (action) {
      case _WordAction.known:
        await vocabularyNotifier.markWordKnown(
          word,
          celebrationOrigin: celebrationOrigin?.call(),
        );
        break;
      case _WordAction.learning:
        await _addToLearning(lookupState, lookupNotifier, vocabularyNotifier, bookmarkNotifier, word);
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _markWordUnknown(
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    String word,
  ) async {
    await vocabularyNotifier.markWordUnknown(word);
    if (bookmarkNotifier.isBookmarked(word)) {
      bookmarkNotifier.removeBookmark(word);
    }
    if (mounted) setState(() {});
  }

  Future<void> _addToLearning(
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    VocabularyNotifier vocabularyNotifier,
    BookmarkNotifier bookmarkNotifier,
    String word,
  ) async {
    await vocabularyNotifier.markWordLearning(word);
    final translation = lookupState.selectedWordTranslation?.trim();
    if (translation != null &&
        translation.isNotEmpty &&
        !bookmarkNotifier.isBookmarked(word)) {
      bookmarkNotifier.addBookmark(word, translation);
    }
    if (mounted) setState(() {});
  }

  String _analysisContext(WordLookupState lookupState, String word) {
    final contextText = lookupState.selectedWordContext?.trim();
    if (contextText != null && contextText.isNotEmpty) return contextText;
    final firstMeaning = lookupState.selectedWordEntry?.meanings.firstOrNull;
    final definition = firstMeaning?.definitions.firstOrNull;
    if (definition != null && definition.trim().isNotEmpty) {
      return definition.trim();
    }
    return lookupState.selectedWordTranslation ?? word;
  }

}
