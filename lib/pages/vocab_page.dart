import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../models/aggregated_vocabulary.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import 'package:flow_design_system/flow_design_system.dart';
import '../widgets/dictionary_detail_view.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/pronunciation_button.dart';
import '../widgets/word_mastery_confetti.dart';

class VocabPage extends riverpod.ConsumerStatefulWidget {
  const VocabPage({super.key});

  @override
  riverpod.ConsumerState<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends riverpod.ConsumerState<VocabPage> {
  static const _showCount = 50;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  int _visibleCount = _showCount;

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
        _visibleCount = _showCount;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(vocabularyNotifier, theme),
            _buildSearchBar(theme),
            Expanded(
              child: _buildBody(
                vocabularyNotifier,
                lookupState,
                lookupNotifier,
                theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(VocabularyNotifier vocabularyNotifier, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Vocabulary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${vocabularyNotifier.totalVocabularyCount} words',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: FlowTextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search words...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    VocabularyNotifier vocabularyNotifier,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    ThemeData theme,
  ) {
    if (lookupState.selectedWord != null) {
      return _buildWordDetail(context, lookupState, lookupNotifier, theme);
    }

    final allVocab = vocabularyNotifier.getAllVocabulary();
    final filtered = _searchQuery.isEmpty
        ? allVocab
        : allVocab.where((v) => v.word.contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching words'
                  : 'No vocabulary yet',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayCount = _visibleCount.clamp(0, filtered.length);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: displayCount + (displayCount < filtered.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= displayCount) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FlowButton.text(
              onPressed: () => setState(() => _visibleCount += _showCount),
              child: Text(
                'Show more (${filtered.length - displayCount} remaining)',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }
        final vocab = filtered[index];
        return _VocabItem(
          vocab: vocab,
          status: vocabularyNotifier.getWordStatus(vocab.word),
          onMarkKnown: (origin) => vocabularyNotifier.markWordKnown(
            vocab.word,
            celebrationOrigin: origin,
          ),
          onMarkLearning: () => vocabularyNotifier.markWordLearning(vocab.word),
          onMarkUnknown: () => vocabularyNotifier.markWordUnknown(vocab.word),
          onTap: () => lookupNotifier.lookupWord(vocab.word),
        );
      },
    );
  }

  Widget _buildWordDetail(
    BuildContext context,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    ThemeData theme,
  ) {
    final word = lookupState.selectedWord!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (true)
                  PronunciationButton(
                    word: word,
                    onSpeakWord: lookupNotifier.speakWord,
                    buttonSize: 32,
                    iconSize: 18,
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: lookupNotifier.clearWordLookup,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DictionaryDetailView.fromWordLookup(
              lookupState: lookupState,
              lookupNotifier: lookupNotifier,
              word: word,
              showWordHeader: false,
              wordLevelService: ref.read(wordLevelServiceProvider),
              canPronounceWords: true,
            ),
          ],
        ),
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
    if (status == UserWordStatus.learning) return FunctionalColors.vocabLearning;
    return FunctionalColors.familiarityLow;
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vocab.word,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
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
                      style: TextStyle(
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
                        color: FunctionalColors.vocabLearning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'learning',
                        style: TextStyle(
                          fontSize: 10,
                          color: FunctionalColors.vocabLearning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '位置 ${vocab.firstChapter + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                vocab.meaning,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (status != UserWordStatus.known)
                    WordMasteryActionAnchor(
                      builder: (context, origin) => _miniButton(
                        label: 'Known',
                        color: FunctionalColors.familiarityHigh,
                        onTap: () => onMarkKnown(origin()),
                      ),
                    ),
                  if (status != UserWordStatus.learning)
                    _miniButton(
                      label: 'Learning',
                      color: FunctionalColors.vocabLearning,
                      onTap: onMarkLearning,
                    ),
                  if (status != null)
                    _miniButton(
                      label: 'Unknown',
                      color: FunctionalColors.familiarityLow,
                      onTap: onMarkUnknown,
                    ),
                ],
              ),
            ],
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
