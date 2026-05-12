import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/aggregated_vocabulary.dart';
import '../models/user_vocabulary.dart';
import '../providers/reading_provider.dart';
import '../theme/app_colors.dart';

class VocabPage extends StatefulWidget {
  const VocabPage({super.key});

  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage> {
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
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(provider, theme),
            _buildSearchBar(theme),
            Expanded(child: _buildBody(provider, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ReadingProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Vocabulary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text('${provider.totalVocabularyCount} words',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search words...',
          hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildBody(ReadingProvider provider, ThemeData theme) {
    if (provider.selectedWord != null) return _buildWordDetail(context, provider, theme);

    final allVocab = provider.getAllVocabulary();
    final filtered = _searchQuery.isEmpty
        ? allVocab
        : allVocab.where((v) => v.word.contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No matching words' : 'No vocabulary yet',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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
            child: TextButton(
              onPressed: () => setState(() => _visibleCount += _showCount),
              child: Text('Show more (${filtered.length - displayCount} remaining)',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
            ),
          );
        }
        final vocab = filtered[index];
        return _VocabItem(
          vocab: vocab,
          status: provider.getWordStatus(vocab.word),
          onMarkKnown: () => provider.markWordKnown(vocab.word),
          onMarkLearning: () => provider.markWordLearning(vocab.word),
          onMarkUnknown: () => provider.markWordUnknown(vocab.word),
          onTap: () => provider.lookupWord(vocab.word),
        );
      },
    );
  }

  Widget _buildWordDetail(BuildContext context, ReadingProvider provider, ThemeData theme) {
    final entry = provider.selectedWordEntry;
    final translation = provider.selectedWordTranslation;
    final word = provider.selectedWord!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(word, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: provider.clearWordLookup,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
            ]),
            if (entry?.phonetic != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.volume_up, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(entry!.phonetic!,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
              ]),
            ],
            if (translation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Text(translation,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimaryContainer)),
              ),
            ],
            if (entry != null && entry.meanings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Definitions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              ...entry.meanings.map((meaning) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (meaning.partOfSpeech.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                          child: Text(meaning.partOfSpeech,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSecondaryContainer)),
                        ),
                      const SizedBox(height: 4),
                      ...meaning.definitions.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text('${e.key + 1}. ${e.value}',
                                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                          )),
                    ]),
                  )),
            ],
            if (provider.isLoadingWord)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ),
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
      case 'Primary School': return Colors.green;
      case 'Middle School': return Colors.teal;
      case 'High School': return Colors.blue;
      case 'CET-4': return Colors.orange;
      case 'CET-6': return Colors.deepOrange;
      case 'GRE': return Colors.red;
      default: return Colors.grey;
    }
  }

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
                  if (vocab.level != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _levelColor(vocab.level!).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(vocab.level!,
                          style: TextStyle(fontSize: 10, color: _levelColor(vocab.level!), fontWeight: FontWeight.w600)),
                    ),
                  if (vocab.level != null) const SizedBox(width: 4),
                  if (status == UserWordStatus.learning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.vocabLearning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('learning',
                          style: TextStyle(fontSize: 10, color: AppColors.vocabLearning, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 6),
                  Text('Ch.${vocab.firstChapter + 1}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                vocab.meaning,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (status != UserWordStatus.known)
                    _miniButton(label: 'Known', color: AppColors.familiarityHigh, onTap: onMarkKnown),
                  if (status != UserWordStatus.learning)
                    _miniButton(label: 'Learning', color: AppColors.vocabLearning, onTap: onMarkLearning),
                  if (status != null)
                    _miniButton(label: 'Unknown', color: AppColors.familiarityLow, onTap: onMarkUnknown),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniButton({required String label, required Color color, required VoidCallback onTap}) {
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
          child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
