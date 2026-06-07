import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../models/aggregated_vocabulary.dart';
import '../models/learning_item.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import 'package:flow_language/flow_language.dart';
import '../theme/app_colors.dart';
import '../widgets/word_bottom_sheet.dart';
import '../widgets/word_mastery_confetti.dart';

enum _VocabularyView { words, cards }

class VocabularyScreen extends riverpod.ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  riverpod.ConsumerState<VocabularyScreen> createState() =>
      _VocabularyScreenState();
}

class _VocabularyScreenState extends riverpod.ConsumerState<VocabularyScreen> {
  bool _sortAlpha = false;
  _VocabularyView _view = _VocabularyView.words;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _languageFilter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    final theme = Theme.of(context);
    final allVocab = vocabularyNotifier.getAllVocabulary(alphabetical: _sortAlpha);
    final allLearningItems = vocabularyNotifier.learningItems;
    final languageOptions = _languageOptionsFor(allVocab);
    final effectiveLanguageFilter = languageOptions.contains(_languageFilter)
        ? _languageFilter
        : null;

    final filtered = allVocab
        .where((v) => _matchesVocabulary(v, effectiveLanguageFilter))
        .toList();
    final filteredLearningItems = _searchQuery.isEmpty
        ? allLearningItems
        : allLearningItems.where((item) => _matchesLearningItem(item)).toList();

    final unknownCount = filtered
        .where((v) => vocabularyNotifier.getWordStatus(v.word) == null)
        .length;
    final learningCount = filtered
        .where(
          (v) => vocabularyNotifier.getWordStatus(v.word) == UserWordStatus.learning,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vocabulary',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, languageOptions, effectiveLanguageFilter),
          _buildViewToggle(theme),
          if (_view == _VocabularyView.words) ...[
            _buildStatsBar(theme, filtered.length, unknownCount, learningCount),
            _buildSortToggle(theme),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final vocab = filtered[index];
                        return _VocabItem(
                          vocab: vocab,
                          status: vocabularyNotifier.getWordStatus(vocab.word),
                          onMarkKnown: (origin) => vocabularyNotifier.markWordKnown(
                            vocab.word,
                            celebrationOrigin: origin,
                          ),
                          onMarkLearning: () =>
                              vocabularyNotifier.markWordLearning(vocab.word),
                          onMarkUnknown: () =>
                              vocabularyNotifier.markWordUnknown(vocab.word),
                          onTap: () => _openWordDetail(context, lookupNotifier, vocab),
                        );
                      },
                    ),
            ),
          ] else ...[
            _buildLearningItemStatsBar(theme, filteredLearningItems),
            Expanded(
              child: filteredLearningItems.isEmpty
                  ? _buildLearningItemEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredLearningItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredLearningItems[index];
                        return _LearningItemCard(
                          item: item,
                          onDelete: () =>
                              vocabularyNotifier.deleteLearningItem(item.id),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  bool _matchesLearningItem(LearningItem item) {
    final query = _searchQuery.toLowerCase();
    return item.title.toLowerCase().contains(query) ||
        item.content.toLowerCase().contains(query) ||
        item.answer.toLowerCase().contains(query) ||
        item.note.toLowerCase().contains(query) ||
        item.sourceText.toLowerCase().contains(query);
  }

  bool _matchesVocabulary(
    AggregatedVocabulary vocab,
    String? languageFilter,
  ) {
    if (languageFilter != null && vocab.languageId != languageFilter) {
      return false;
    }
    if (_searchQuery.isEmpty) return true;
    return vocab.word.toLowerCase().contains(_searchQuery);
  }

  List<String> _languageOptionsFor(List<AggregatedVocabulary> vocabulary) {
    final languageIds =
        vocabulary
            .map((vocab) => vocab.languageId.toLowerCase().trim())
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return languageIds;
  }

  void _openWordDetail(
    BuildContext context,
    WordLookupNotifier lookupNotifier,
    AggregatedVocabulary vocab,
  ) {
    lookupNotifier.lookupWord(vocab.word, contextText: vocab.context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordBottomSheet(word: vocab.word),
    ).whenComplete(lookupNotifier.clearWordLookup);
  }

  Widget _buildSearchBar(
    ThemeData theme,
    List<String> languageOptions,
    String? selectedLanguageId,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _view == _VocabularyView.words
                    ? 'Search words...'
                    : 'Search learning cards...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_view == _VocabularyView.words && languageOptions.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildLanguageFilter(theme, languageOptions, selectedLanguageId),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageFilter(
    ThemeData theme,
    List<String> languageOptions,
    String? selectedLanguageId,
  ) {
    return Tooltip(
      message: 'Language',
      child: Container(
        height: 48,
        constraints: const BoxConstraints(minWidth: 82),
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedLanguageId,
            isDense: true,
            icon: const Icon(Icons.expand_more, size: 18),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All'),
              ),
              ...languageOptions.map(
                (code) => DropdownMenuItem<String?>(
                  value: code,
                  child: Text(_languageLabel(code)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _languageFilter = value;
              });
            },
          ),
        ),
      ),
    );
  }

  String _languageLabel(String code) {
    final normalized = code.toLowerCase().trim();
    final module = LanguageRegistry.instance.get(normalized);
    return (module?.languageCode ?? normalized).toUpperCase();
  }

  Widget _buildViewToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_VocabularyView>(
          selected: {_view},
          onSelectionChanged: (value) {
            setState(() {
              _view = value.single;
            });
          },
          segments: const [
            ButtonSegment(
              value: _VocabularyView.words,
              icon: Icon(Icons.text_fields_outlined, size: 18),
              label: Text('Words'),
            ),
            ButtonSegment(
              value: _VocabularyView.cards,
              icon: Icon(Icons.add_card_outlined, size: 18),
              label: Text('Cards'),
            ),
          ],
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme, int total, int unknown, int learning) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          Text(
            '$total words',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (unknown > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.familiarityLow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$unknown new',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.familiarityLow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (learning > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.vocabLearning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$learning learning',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.vocabLearning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          _sortChip(
            label: 'By Order',
            selected: !_sortAlpha,
            onTap: () => setState(() => _sortAlpha = false),
          ),
          const SizedBox(width: 8),
          _sortChip(
            label: 'A-Z',
            selected: _sortAlpha,
            onTap: () => setState(() => _sortAlpha = true),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningItemStatsBar(ThemeData theme, List<LearningItem> items) {
    final wordCount = items
        .where((item) => item.type == LearningItemType.word)
        .length;
    final sentenceCount = items
        .where((item) => item.type == LearningItemType.sentence)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            '${items.length} cards',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (wordCount > 0) ...[
            const SizedBox(width: 10),
            _statPill('$wordCount words', AppColors.vocabLearning),
          ],
          if (sentenceCount > 0) ...[
            const SizedBox(width: 6),
            _statPill('$sentenceCount passages', theme.colorScheme.tertiary),
          ],
        ],
      ),
    );
  }

  Widget _statPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Import a book to see vocabulary',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningItemEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_card_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No learning cards yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabItem extends StatelessWidget {
  final AggregatedVocabulary vocab;
  final UserWordStatus? status;
  final ValueChanged<Offset?> onMarkKnown;
  final VoidCallback onMarkLearning;
  final VoidCallback onMarkUnknown;
  final VoidCallback onTap;

  const _VocabItem({
    required this.vocab,
    required this.status,
    required this.onMarkKnown,
    required this.onMarkLearning,
    required this.onMarkUnknown,
    required this.onTap,
  });

  Color get _statusColor {
    if (status == UserWordStatus.learning) return AppColors.vocabLearning;
    return AppColors.familiarityLow;
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Primary School':
        return Colors.green;
      case 'Middle School':
        return Colors.teal;
      case 'High School':
        return Colors.blue;
      case 'CET-4':
        return Colors.orange;
      case 'CET-6':
        return Colors.deepOrange;
      case 'GRE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _languageLabel(String code) => code.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vocab.word,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                          fontFamily: 'Serif',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _languageLabel(vocab.languageId),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (vocab.level != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _levelColor(
                            vocab.level!,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vocab.level!,
                          style: TextStyle(
                            fontSize: 10,
                            color: _levelColor(vocab.level!),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (vocab.level != null) const SizedBox(width: 4),
                    if (status == UserWordStatus.learning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.vocabLearning.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'learning',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.vocabLearning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '位置 ${vocab.firstChapter + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  vocab.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (status != UserWordStatus.known)
                      WordMasteryActionAnchor(
                        builder: (context, origin) => _miniButton(
                          label: 'Known',
                          color: AppColors.familiarityHigh,
                          onTap: () => onMarkKnown(origin()),
                        ),
                      ),
                    if (status != UserWordStatus.learning)
                      _miniButton(
                        label: 'Learning',
                        color: AppColors.vocabLearning,
                        onTap: onMarkLearning,
                      ),
                    if (status != null)
                      _miniButton(
                        label: 'Unknown',
                        color: AppColors.familiarityLow,
                        onTap: onMarkUnknown,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningItemCard extends StatelessWidget {
  final LearningItem item;
  final VoidCallback onDelete;

  const _LearningItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _firstNonEmpty([item.answer, item.note, item.sourceText]);
    final location = item.chapterIndex >= 0
        ? '位置 ${item.chapterIndex + 1}'
        : '未关联书籍';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _typeBadge(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title.isEmpty ? item.content : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: '删除',
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.chapterTitle.isNotEmpty
                          ? '$location · ${item.chapterTitle}'
                          : location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(ThemeData theme) {
    final color = switch (item.type) {
      LearningItemType.word => AppColors.vocabLearning,
      LearningItemType.sentence => theme.colorScheme.primary,
      LearningItemType.grammar => theme.colorScheme.tertiary,
      LearningItemType.expression => Colors.indigo,
      LearningItemType.questionMistake => theme.colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.type.label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$month-$day';
  }
}
