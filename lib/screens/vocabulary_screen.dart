import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aggregated_vocabulary.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading_provider.dart';
import '../theme/app_colors.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  bool _sortAlpha = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final allVocab = provider.getAllVocabulary(alphabetical: _sortAlpha);

    final filtered = _searchQuery.isEmpty
        ? allVocab
        : allVocab.where((v) => v.word.contains(_searchQuery)).toList();

    final unknownCount = filtered
        .where((v) => provider.getWordStatus(v.word) == null)
        .length;
    final learningCount = filtered
        .where((v) => provider.getWordStatus(v.word) == UserWordStatus.learning)
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
          _buildSearchBar(theme),
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
                        status: provider.getWordStatus(vocab.word),
                        onMarkKnown: () => provider.markWordKnown(vocab.word),
                        onMarkLearning: () =>
                            provider.markWordLearning(vocab.word),
                        onMarkUnknown: () =>
                            provider.markWordUnknown(vocab.word),
                        onTap: () => provider.lookupWord(vocab.word),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search words...',
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
}

class _VocabItem extends StatelessWidget {
  final AggregatedVocabulary vocab;
  final UserWordStatus? status;
  final VoidCallback onMarkKnown;
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
                      _miniButton(
                        label: 'Known',
                        color: AppColors.familiarityHigh,
                        onTap: onMarkKnown,
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
