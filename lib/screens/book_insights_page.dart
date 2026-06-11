import 'package:flutter/material.dart';

import 'package:flow_ai/flow_ai.dart';

import '../providers/book_insight_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/flow/flow_components.dart';

class BookInsightsPage extends StatefulWidget {
  const BookInsightsPage({
    super.key,
    required this.provider,
    required this.bookTitle,
    required this.onGenerateChapter,
  });

  final BookInsightProvider provider;
  final String bookTitle;
  final ValueChanged<int> onGenerateChapter;

  @override
  State<BookInsightsPage> createState() => _BookInsightsPageState();
}

class _BookInsightsPageState extends State<BookInsightsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _requestedLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!_requestedLoad) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.provider.addListener(_onProviderChanged);
      });
    }
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = widget.provider;

    return Scaffold(
      appBar: FlowToolbar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '书籍洞察',
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (provider.coverage != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.showFullBook ? '全书' : '已读',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  Switch(
                    value: provider.showFullBook,
                    onChanged: (_) => provider.toggleShowFullBook(),
                  ),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '故事线'),
            Tab(text: '人物'),
            Tab(text: '章节'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? _buildError(theme, provider.error!)
          : provider.isEmpty
          ? _buildEmpty(theme)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStoryline(theme, provider),
                _buildCharacters(theme, provider),
                _buildChapterList(theme, provider),
              ],
            ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(error, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无章节总结',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在阅读器中为章节生成 AI 总结后，\n这里将展示全书故事线和人物卡片。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryline(ThemeData theme, BookInsightProvider provider) {
    final storyline = provider.storyline;
    if (storyline == null || storyline.events.isEmpty) {
      return _buildEmptyTab(theme, '暂无故事线数据');
    }

    final eventsByChapter = <int, List<StorylineEvent>>{};
    for (final event in storyline.events) {
      eventsByChapter.putIfAbsent(event.chapterIndex, () => []).add(event);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.coverage != null) _buildCoverageBar(theme, provider),
        const SizedBox(height: 12),
        for (final chapterIndex in eventsByChapter.keys.toList()..sort())
          _buildChapterEventGroup(
            theme,
            chapterIndex,
            eventsByChapter[chapterIndex]!,
          ),
      ],
    );
  }

  Widget _buildChapterEventGroup(
    ThemeData theme,
    int chapterIndex,
    List<StorylineEvent> events,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${chapterIndex + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '第 ${chapterIndex + 1} 章',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...events.map(
            (event) => Card(
              margin: const EdgeInsets.only(left: 42, bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.significance != null &&
                        event.significance!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.significance!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (event.source != null && event.source!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '"${event.source}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacters(ThemeData theme, BookInsightProvider provider) {
    final cards = provider.characterCards;
    if (cards.isEmpty) {
      return _buildEmptyTab(theme, '暂无人物数据');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.coverage != null) _buildCoverageBar(theme, provider),
        const SizedBox(height: 12),
        ...cards.map((card) => _buildCharacterCard(theme, card)),
      ],
    );
  }

  Widget _buildCharacterCard(ThemeData theme, BookCharacterCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    card.canonicalName.isNotEmpty
                        ? card.canonicalName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.canonicalName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '首次出现: 第 ${card.firstSeenChapter + 1} 章',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...card.developments.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ch${entry.key + 1}: ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.change,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(ThemeData theme, BookInsightProvider provider) {
    final coverage = provider.coverage;
    if (coverage == null) return _buildEmptyTab(theme, '暂无章节数据');

    final summaries = provider.chapterSummaries;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCoverageBar(theme, provider),
        const SizedBox(height: 12),
        for (var i = 0; i < coverage.totalChapters; i++)
          if (summaries.containsKey(i))
            _buildChapterSummaryCard(theme, i, summaries[i]!)
          else
            _buildChapterMissingCard(theme, i, coverage.readChapters),
      ],
    );
  }

  Widget _buildChapterSummaryCard(
    ThemeData theme,
    int chapterIndex,
    AISummary summary,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.correct.withValues(alpha: 0.15),
          child: Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.correct,
          ),
        ),
        title: Text(
          '第 ${chapterIndex + 1} 章',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          '${summary.events.length} 个事件 · ${summary.characterDevelopments.length} 个角色',
          style: theme.textTheme.labelSmall,
        ),
        children: [
          if (summary.events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关键事件',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  ...summary.events.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '· ${e.description}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (summary.readingGuidance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                summary.readingGuidance,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChapterMissingCard(
    ThemeData theme,
    int chapterIndex,
    int readChapters,
  ) {
    final isRead = chapterIndex < readChapters;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: isRead
              ? theme.colorScheme.error.withValues(alpha: 0.12)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
          child: Icon(
            isRead ? Icons.sync : Icons.lock_outline,
            size: 16,
            color: isRead ? theme.colorScheme.error : theme.colorScheme.outline,
          ),
        ),
        title: Text(
          '第 ${chapterIndex + 1} 章',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          isRead ? '尚未生成总结' : '尚未阅读',
          style: theme.textTheme.labelSmall,
        ),
        trailing: isRead
            ? FlowButton.secondary(
                onPressed: () => widget.onGenerateChapter(chapterIndex),
                icon: const Icon(Icons.auto_awesome, size: 16),
                child: const Text('生成'),
              )
            : null,
      ),
    );
  }

  Widget _buildCoverageBar(ThemeData theme, BookInsightProvider provider) {
    final coverage = provider.coverage;
    if (coverage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '已总结 ${coverage.summarizedChapters}/${coverage.totalChapters} 章',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: coverage.percentage,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.4,
              ),
            ),
          ),
          if (coverage.missingChapters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '未生成总结: ${coverage.missingChapters.map((i) => 'Ch${i + 1}').join(', ')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTab(ThemeData theme, String message) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
