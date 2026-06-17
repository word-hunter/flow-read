import 'dart:async';

import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/user_vocabulary.dart';
import '../models/wordbook_dashboard.dart';
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/word_bottom_sheet.dart';
import '../widgets/word_mastery_confetti.dart';

class VocabularyScreen extends riverpod.ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  riverpod.ConsumerState<VocabularyScreen> createState() =>
      _VocabularyScreenState();
}

class _VocabularyScreenState extends riverpod.ConsumerState<VocabularyScreen> {
  static const _wideLayoutBreakpoint = 1080.0;
  static const _contentMaxWidth = 1220.0;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  WordbookFilter _filter = WordbookFilter.due;
  String _query = '';

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
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(vocabularyNotifierProvider);
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    final books = ref.watch(bookServiceProvider).books;
    final now = DateTime.now();
    final dashboard = const WordbookDashboardBuilder().build(
      vocabulary: vocabularyNotifier.getAllVocabulary(),
      learningItems: vocabularyNotifier.learningItems,
      statusFor: vocabularyNotifier.getWordStatus,
      bookTitlesById: {for (final book in books) book.id: book.title},
      now: now,
    );
    final visibleEntries = dashboard.visibleEntries(
      filter: _filter,
      query: _query,
      now: now,
    );
    final visibleEntryGroups = dashboard.visibleEntryGroupsByBook(
      query: _query,
      now: now,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 16,
                    isWide ? 24 : 14,
                    isWide ? 28 : 16,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(context, dashboard),
                      const SizedBox(height: 22),
                      _buildHeading(context),
                      const SizedBox(height: 18),
                      if (isWide)
                        Expanded(
                          child: _buildWideLayout(
                            context,
                            dashboard,
                            visibleEntries,
                            visibleEntryGroups,
                            vocabularyNotifier,
                          ),
                        )
                      else
                        Expanded(
                          child: _buildNarrowLayout(
                            context,
                            dashboard,
                            visibleEntries,
                            visibleEntryGroups,
                            vocabularyNotifier,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WordbookDashboard dashboard) {
    final theme = Theme.of(context);
    final searchField = FlowTextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索单词、释义或来源书籍',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                tooltip: '清除搜索',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.34,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: 0.58,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: 0.42,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
    final startButton = FlowButton.primary(
      onPressed: dashboard.dueCount > 0 ? _startTodayReview : null,
      icon: const Icon(Icons.fact_check_outlined, size: 18),
      child: const Text('开始今日测验'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: startButton,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 16),
            startButton,
          ],
        );
      },
    );
  }

  Widget _buildHeading(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '单词本',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '所有生词均来自阅读材料',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    WordbookDashboard dashboard,
    List<WordbookEntry> entries,
    List<WordbookEntryGroup> entryGroups,
    VocabularyNotifier vocabularyNotifier,
  ) {
    return Column(
      children: [
        _buildStatsGrid(context, dashboard),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildReviewSummary(context, dashboard),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _buildEntryPanel(
                        context,
                        dashboard,
                        entries,
                        entryGroups,
                        vocabularyNotifier,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 310,
                child: _buildSidePanel(context, dashboard),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    WordbookDashboard dashboard,
    List<WordbookEntry> entries,
    List<WordbookEntryGroup> entryGroups,
    VocabularyNotifier vocabularyNotifier,
  ) {
    return ListView(
      children: [
        _buildStatsGrid(context, dashboard),
        const SizedBox(height: 14),
        _buildReviewSummary(context, dashboard),
        const SizedBox(height: 14),
        SizedBox(
          height: 520,
          child: _buildEntryPanel(
            context,
            dashboard,
            entries,
            entryGroups,
            vocabularyNotifier,
          ),
        ),
        const SizedBox(height: 14),
        _buildSidePanel(context, dashboard),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, WordbookDashboard dashboard) {
    final stats = [
      _WordbookStat(
        label: '今日应复习',
        value: dashboard.dueCount.toString(),
        icon: Icons.event_available_outlined,
        color: const Color(0xFFE7A51A),
      ),
      _WordbookStat(
        label: '学习中',
        value: dashboard.learningCount.toString(),
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF1C73E8),
      ),
      _WordbookStat(
        label: '已掌握',
        value: dashboard.masteredCount.toString(),
        icon: Icons.check_circle_outline,
        color: FunctionalColors.familiarityHigh,
      ),
      _WordbookStat(
        label: '连续复习',
        value: '${dashboard.reviewStreakDays} 天',
        icon: Icons.local_fire_department_outlined,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columnCount == 4 ? 2.75 : 2.35,
          ),
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
        );
      },
    );
  }

  Widget _buildReviewSummary(
    BuildContext context,
    WordbookDashboard dashboard,
  ) {
    final theme = Theme.of(context);
    final totalTarget = dashboard.dueCount == 0
        ? 20
        : dashboard.dueCount.clamp(1, 20);
    return _PanelSurface(
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: totalTarget == 0
                        ? 0
                        : (dashboard.dueCount / totalTarget)
                              .clamp(0, 1)
                              .toDouble(),
                    strokeWidth: 9,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: const Color(0xFFE7A51A),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: dashboard.dueCount.toString(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' / $totalTarget',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Container(
            width: 1,
            height: 92,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日复习',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboard.dueCount > 0
                      ? '基于阅读上下文生成题目'
                      : '暂无到期词，继续阅读或保存学习项后会自动进入队列',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FlowButton.primary(
                  onPressed: dashboard.dueCount > 0 ? _startTodayReview : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  child: const Text('开始今日测验'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryPanel(
    BuildContext context,
    WordbookDashboard dashboard,
    List<WordbookEntry> entries,
    List<WordbookEntryGroup> entryGroups,
    VocabularyNotifier vocabularyNotifier,
  ) {
    final theme = Theme.of(context);
    return _PanelSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(child: _buildFilterChips()),
                const SizedBox(width: 10),
                Tooltip(
                  message: '筛选',
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _filter = WordbookFilter.due),
                    icon: const Icon(Icons.filter_list, size: 20),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _TableHeader(theme: theme),
          Expanded(
            child: entries.isEmpty
                ? _buildEmptyList(context, dashboard)
                : _filter == WordbookFilter.byBook
                ? _buildGroupedEntryList(
                    context,
                    entryGroups,
                    vocabularyNotifier,
                  )
                : _buildFlatEntryList(context, entries, vocabularyNotifier),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Text(
                  _filter == WordbookFilter.byBook
                      ? '共 ${entries.length} 个单词 · ${entryGroups.length} 本来源'
                      : '共 ${entries.length} 个单词',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '上一页',
                  onPressed: null,
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    fixedSize: const Size(40, 36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('1'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '下一页',
                  onPressed: null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatEntryList(
    BuildContext context,
    List<WordbookEntry> entries,
    VocabularyNotifier vocabularyNotifier,
  ) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryRow(entry, vocabularyNotifier);
      },
    );
  }

  Widget _buildGroupedEntryList(
    BuildContext context,
    List<WordbookEntryGroup> groups,
    VocabularyNotifier vocabularyNotifier,
  ) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BookGroupHeader(group: group),
            for (var index = 0; index < group.entries.length; index++) ...[
              _buildEntryRow(group.entries[index], vocabularyNotifier),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEntryRow(
    WordbookEntry entry,
    VocabularyNotifier vocabularyNotifier,
  ) {
    return _WordbookEntryRow(
      entry: entry,
      onTap: () => _openWordDetail(context, entry),
      onMarkKnown: (origin) => _markKnown(
        vocabularyNotifier,
        entry.word,
        origin,
      ),
      onMarkLearning: () => _markLearning(
        vocabularyNotifier,
        entry.word,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in WordbookFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: _filter == filter,
              onTap: () => setState(() => _filter = filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyList(BuildContext context, WordbookDashboard dashboard) {
    final theme = Theme.of(context);
    final hasQuery = _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.collections_bookmark_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? '没有匹配的单词' : '暂无${_filter.label}单词',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dashboard.entries.isEmpty ? '阅读中保存的词会出现在这里。' : '可以切换筛选或调整搜索词。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context, WordbookDashboard dashboard) {
    return Column(
      children: [
        _SourcesPanel(sources: dashboard.sourceSummaries.take(3).toList()),
        const SizedBox(height: 14),
        const _QuestionTypesPanel(),
      ],
    );
  }

  void _startTodayReview() {
    Navigator.pushNamed(context, '/spaced_review');
  }

  void _openWordDetail(BuildContext context, WordbookEntry entry) {
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    lookupNotifier.lookupWord(entry.word, contextText: entry.sourceContext);
    showFlowSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordBottomSheet(word: entry.word),
    ).whenComplete(lookupNotifier.clearWordLookup);
  }

  Future<void> _markKnown(
    VocabularyNotifier vocabularyNotifier,
    String word,
    Offset? origin,
  ) async {
    await vocabularyNotifier.markWordKnown(word, celebrationOrigin: origin);
    if (mounted) setState(() {});
  }

  Future<void> _markLearning(
    VocabularyNotifier vocabularyNotifier,
    String word,
  ) async {
    await vocabularyNotifier.markWordLearning(word);
    if (mounted) setState(() {});
  }
}

class _WordbookStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WordbookStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _WordbookStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, color: stat.color, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(flex: 18, child: Text('单词', style: labelStyle)),
          Expanded(flex: 18, child: Text('释义', style: labelStyle)),
          Expanded(flex: 18, child: Text('来源', style: labelStyle)),
          Expanded(flex: 24, child: Text('原句上下文', style: labelStyle)),
          SizedBox(width: 76, child: Text('熟悉度', style: labelStyle)),
          SizedBox(width: 78, child: Text('下次复习', style: labelStyle)),
          const SizedBox(width: 46),
        ],
      ),
    );
  }
}

class _BookGroupHeader extends StatelessWidget {
  const _BookGroupHeader({required this.group});

  final WordbookEntryGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.34,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.36),
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
          Expanded(
            child: Text(
              group.sourceTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${group.wordCount} 个单词',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordbookEntryRow extends StatelessWidget {
  const _WordbookEntryRow({
    required this.entry,
    required this.onTap,
    required this.onMarkKnown,
    required this.onMarkLearning,
  });

  final WordbookEntry entry;
  final VoidCallback onTap;
  final ValueChanged<Offset?> onMarkKnown;
  final VoidCallback onMarkLearning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: [
            Expanded(
              flex: 18,
              child: _WordCell(word: entry.word),
            ),
            Expanded(
              flex: 18,
              child: _OneLineText(
                entry.meaning.isEmpty ? '暂无释义' : entry.meaning,
                color: theme.colorScheme.onSurfaceVariant,
                weight: FontWeight.w600,
              ),
            ),
            Expanded(
              flex: 18,
              child: _OneLineText(
                _sourceLabel(entry),
                color: theme.colorScheme.onSurfaceVariant,
                weight: FontWeight.w600,
              ),
            ),
            Expanded(
              flex: 24,
              child: _OneLineText(
                entry.sourceContext.isEmpty ? '暂无上下文' : entry.sourceContext,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(
              width: 76,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _FamiliarityBadge(entry: entry),
              ),
            ),
            SizedBox(
              width: 78,
              child: Text(
                _nextReviewLabel(entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _nextReviewColor(context, entry),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 46,
              child: _RowActions(
                status: entry.status,
                onMarkKnown: onMarkKnown,
                onMarkLearning: onMarkLearning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(WordbookEntry entry) {
    if (entry.sourceDetail.isEmpty) return entry.sourceTitle;
    return '${entry.sourceTitle} · ${entry.sourceDetail}';
  }

  String _nextReviewLabel(WordbookEntry entry) {
    if (!entry.fromLearningItem) return '未安排';
    final value = entry.nextReviewAt;
    if (value.millisecondsSinceEpoch == 0) return '今天';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final dayDelta = target.difference(today).inDays;
    if (dayDelta <= 0) return '今天';
    if (dayDelta == 1) return '明天';
    return '$dayDelta 天后';
  }

  Color _nextReviewColor(BuildContext context, WordbookEntry entry) {
    if (_nextReviewLabel(entry) == '今天') return const Color(0xFFE87512);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _WordCell extends StatelessWidget {
  const _WordCell({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '/${word.toLowerCase()}/',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OneLineText extends StatelessWidget {
  const _OneLineText(
    this.text, {
    required this.color,
    this.weight = FontWeight.w500,
  });

  final String text;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: weight,
        ),
      ),
    );
  }
}

class _FamiliarityBadge extends StatelessWidget {
  const _FamiliarityBadge({required this.entry});

  final WordbookEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.status == UserWordStatus.known
        ? FunctionalColors.familiarityHigh
        : entry.reviewCount == 0
        ? FunctionalColors.vocabLearning
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        entry.isMastered ? '已掌握' : entry.familiarityLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.status,
    required this.onMarkKnown,
    required this.onMarkLearning,
  });

  final UserWordStatus? status;
  final ValueChanged<Offset?> onMarkKnown;
  final VoidCallback onMarkLearning;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '操作',
      icon: const Icon(Icons.chevron_right, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        if (status != UserWordStatus.learning)
          const PopupMenuItem(
            value: 'learning',
            child: Text('标为学习中'),
          ),
        if (status != UserWordStatus.known)
          PopupMenuItem(
            value: 'known',
            child: WordMasteryActionAnchor(
              builder: (context, origin) => const Text('标为已掌握'),
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'learning') {
          onMarkLearning();
          return;
        }
        onMarkKnown(null);
      },
    );
  }
}

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({required this.sources});

  final List<WordbookSourceSummary> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '来源书籍',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: null,
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sources.isEmpty)
            Text(
              '保存阅读中的词后会显示来源分布。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...sources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _bookInitial(source.title),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${source.wordCount} 个单词',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _bookInitial(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'B';
    return trimmed.characters.first.toUpperCase();
  }
}

class _QuestionTypesPanel extends StatelessWidget {
  const _QuestionTypesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const types = [
      (icon: Icons.fact_check_outlined, title: '原句挖空', text: '检测对单词拼写与搭配的掌握'),
      (
        icon: Icons.travel_explore_outlined,
        title: '语境选义',
        text: '根据上下文选择最合适的释义',
      ),
      (icon: Icons.translate_outlined, title: '看中文选英文', text: '根据中文释义选择对应英文单词'),
    ];
    return _PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 题型',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (final type in types) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type.icon,
                    size: 21,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (type != types.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.46),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
