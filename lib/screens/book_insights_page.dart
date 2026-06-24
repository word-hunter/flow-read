import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flow_ai/flow_ai.dart';

import '../models/book_glossary_entry.dart';
import '../providers/book_insight_provider.dart';
import 'package:flow_design_system/flow_design_system.dart';
import '../widgets/flow/flow_components.dart';

class BookInsightsPage extends StatefulWidget {
  const BookInsightsPage({
    super.key,
    required this.provider,
    required this.bookTitle,
    required this.onGenerateChapter,
    this.onGenerateMissingReadChapters,
  });

  final BookInsightProvider provider;
  final String bookTitle;
  final Future<void> Function(int chapterIndex) onGenerateChapter;
  final Future<int> Function(List<int> chapterIndexes)?
  onGenerateMissingReadChapters;

  @override
  State<BookInsightsPage> createState() => _BookInsightsPageState();
}

class _BookInsightsPageState extends State<BookInsightsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _requestedLoad = false;
  bool _isBackfillingSummaries = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: '术语'),
            Tab(text: '章节'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? _buildError(theme, provider.error!)
          : provider.isEmpty && provider.coverage == null
          ? _buildEmpty(theme)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStoryline(theme, provider),
                _buildCharacters(theme, provider),
                _buildGlossary(theme, provider),
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
    final analysisEvents = provider.analysisData?.storyEvents ?? const [];
    final timelineEvents = analysisEvents.isNotEmpty
        ? analysisEvents.map(_TimelineEvent.fromAnalysis).toList()
        : (provider.storyline?.events ?? const [])
              .map(_TimelineEvent.fromLegacy)
              .toList();
    final hasSynthesisControls = provider.analysisData != null;
    if (timelineEvents.isEmpty && !hasSynthesisControls) {
      return _buildEmptyTab(theme, '暂无故事线数据');
    }

    final eventsByChapter = <int, List<_TimelineEvent>>{};
    for (final event in timelineEvents) {
      eventsByChapter.putIfAbsent(event.chapterIndex, () => []).add(event);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.coverage != null) _buildCoverageBar(theme, provider),
        if (hasSynthesisControls) ...[
          const SizedBox(height: 12),
          _buildSynthesisPanel(theme, provider),
        ],
        const SizedBox(height: 12),
        if (eventsByChapter.isEmpty)
          _buildInlineEmpty(theme, '暂无事件数据')
        else
          for (final chapterIndex in eventsByChapter.keys.toList()..sort())
            _buildChapterEventGroup(
              theme,
              chapterIndex,
              eventsByChapter[chapterIndex]!,
            ),
      ],
    );
  }

  Widget _buildSynthesisPanel(ThemeData theme, BookInsightProvider provider) {
    final synthesis = provider.visibleSynthesis;
    final canGenerate = provider.canGenerateSynthesis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.showFullBook ? '全书分析' : '已读范围分析',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FlowButton.secondary(
                onPressed:
                    canGenerate && !provider.isGeneratingReadScopeSynthesis
                    ? () {
                        unawaited(_generateReadScopeSynthesis(provider));
                      }
                    : null,
                icon: provider.isGeneratingReadScopeSynthesis
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                child: Text(
                  provider.isGeneratingReadScopeSynthesis ? '生成中' : '生成已读范围分析',
                ),
              ),
              FlowButton.secondary(
                onPressed:
                    canGenerate && !provider.isGeneratingFullBookSynthesis
                    ? () {
                        unawaited(_confirmAndGenerateFullBook(provider));
                      }
                    : null,
                icon: provider.isGeneratingFullBookSynthesis
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore, size: 16),
                child: Text(
                  provider.isGeneratingFullBookSynthesis
                      ? '生成中'
                      : '生成全书分析（可能剧透）',
                ),
              ),
            ],
          ),
          if (synthesis != null) ...[
            const SizedBox(height: 12),
            Text(synthesis.fullStoryline, style: theme.textTheme.bodyMedium),
            if (synthesis.keyInsights.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: synthesis.keyInsights
                    .map(
                      (insight) => Chip(
                        label: Text(insight),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChapterEventGroup(
    ThemeData theme,
    int chapterIndex,
    List<_TimelineEvent> events,
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
                    if (event.detail != null && event.detail!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.detail!,
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
    final registryEntries = provider.characterRegistryEntries;
    final registeredNames = registryEntries
        .map((entry) => entry.canonicalName.toLowerCase())
        .toSet();
    final analysisCards = (provider.analysisData?.characters ?? const [])
        .where(
          (card) => !registeredNames.contains(card.canonicalName.toLowerCase()),
        )
        .toList();
    final cards = analysisCards.isEmpty
        ? provider.characterCards
              .where(
                (card) => !registeredNames.contains(
                  card.canonicalName.toLowerCase(),
                ),
              )
              .toList()
        : const <BookCharacterCard>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.coverage != null) _buildCoverageBar(theme, provider),
        const SizedBox(height: 12),
        _buildCharacterActions(theme, provider),
        if (registryEntries.isEmpty &&
            analysisCards.isEmpty &&
            cards.isEmpty) ...[
          const SizedBox(height: 48),
          Center(
            child: Text(
              '暂无人物数据',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
        ...registryEntries.map(
          (entry) => _buildRegistryCharacterCard(theme, provider, entry),
        ),
        ...analysisCards.map(
          (card) => _buildAnalysisCharacterCard(theme, card),
        ),
        ...cards.map((card) => _buildCharacterCard(theme, provider, card)),
      ],
    );
  }

  Widget _buildCharacterActions(
    ThemeData theme,
    BookInsightProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '人物注册表',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FlowButton.secondary(
            onPressed: provider.canMaintainCharacters
                ? () => _showAddCharacterDialog(provider)
                : null,
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            child: const Text('新增人物'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryCharacterCard(
    ThemeData theme,
    BookInsightProvider provider,
    CharacterRegistryEntry entry,
  ) {
    final aliases = [...entry.aliases, ...entry.userOverrides].toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      entry.canonicalName.isNotEmpty
                          ? entry.canonicalName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.canonicalName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (entry.firstAppearanceChapter != null)
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
                      '首次出现: 第 ${entry.firstAppearanceChapter! + 1} 章',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: '人物操作',
                  onSelected: (value) {
                    switch (value) {
                      case 'alias':
                        _showAddAliasDialog(provider, entry.canonicalName);
                        break;
                      case 'delete':
                        _confirmDeleteCharacter(provider, entry.canonicalName);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'alias',
                      child: ListTile(
                        leading: Icon(Icons.sell_outlined),
                        title: Text('添加别名'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('删除人物'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (aliases.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: aliases
                    .map(
                      (alias) => Chip(
                        label: Text(alias),
                        onDeleted: provider.canMaintainCharacters
                            ? () {
                                unawaited(
                                  provider.removeCharacterAlias(
                                    entry.canonicalName,
                                    alias,
                                  ),
                                );
                              }
                            : null,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    ThemeData theme,
    BookInsightProvider provider,
    BookCharacterCard card,
  ) {
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
                FlowButton.secondary(
                  onPressed: provider.canMaintainCharacters
                      ? () {
                          unawaited(provider.confirmCharacterCard(card));
                        }
                      : null,
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  child: const Text('登记'),
                ),
                const SizedBox(width: 8),
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

  Widget _buildAnalysisCharacterCard(ThemeData theme, CharacterCard card) {
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
                    '第 ${card.firstChapter + 1}-${card.lastChapter + 1} 章',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (card.traits.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.traits
                    .take(6)
                    .map(
                      (trait) => Chip(
                        label: Text(trait),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (card.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...card.actions
                  .take(4)
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '· $action',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCharacterDialog(BookInsightProvider provider) async {
    final controller = TextEditingController();
    final name = await showFlowDialog<String>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: const Text('新增人物'),
        content: FlowTextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: '人物名'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FlowButton.primary(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await provider.addCharacter(name);
  }

  Future<void> _showAddAliasDialog(
    BookInsightProvider provider,
    String canonicalName,
  ) async {
    final controller = TextEditingController();
    final alias = await showFlowDialog<String>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: Text('添加 $canonicalName 的别名'),
        content: FlowTextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: '别名'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FlowButton.primary(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (alias == null || alias.trim().isEmpty) return;
    await provider.addCharacterAlias(canonicalName, alias);
  }

  Future<void> _confirmDeleteCharacter(
    BookInsightProvider provider,
    String canonicalName,
  ) async {
    final confirmed = await showFlowDialog<bool>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: const Text('删除人物'),
        content: Text('删除后将不再作为本书人物参与 AI 上下文：$canonicalName'),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FlowButton.destructive(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.removeCharacter(canonicalName);
  }

  Widget _buildGlossary(ThemeData theme, BookInsightProvider provider) {
    final entries = provider.glossaryEntries;
    if (entries.isEmpty) {
      return _buildEmptyTab(theme, '暂无本书术语');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.coverage != null) _buildCoverageBar(theme, provider),
        const SizedBox(height: 12),
        ...entries.map((entry) => _buildGlossaryCard(theme, entry)),
      ],
    );
  }

  Widget _buildGlossaryCard(ThemeData theme, BookGlossaryEntry entry) {
    final canonical = entry.canonicalForm?.trim();
    final context = entry.sourceContext?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 15,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.word,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (canonical != null &&
                          canonical.isNotEmpty &&
                          canonical.toLowerCase() !=
                              entry.word.toLowerCase()) ...[
                        const SizedBox(height: 3),
                        Text(
                          canonical,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(entry.explanation, style: theme.textTheme.bodyMedium),
            if (context != null && context.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$context"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
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
          backgroundColor: FunctionalColors.correct.withValues(alpha: 0.15),
          child: Icon(
            Icons.check_circle,
            size: 16,
            color: FunctionalColors.correct,
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
                onPressed: () {
                  unawaited(_generateChapterSummary(chapterIndex));
                },
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
    final readMissingChapters = _readMissingChapters(coverage);

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
              if (readMissingChapters.isNotEmpty) ...[
                const Spacer(),
                FlowButton.secondary(
                  onPressed:
                      _isBackfillingSummaries ||
                          widget.onGenerateMissingReadChapters == null
                      ? null
                      : () {
                          unawaited(
                            _generateMissingReadSummaries(readMissingChapters),
                          );
                        },
                  icon: _isBackfillingSummaries
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_add_check, size: 16),
                  child: Text(
                    _isBackfillingSummaries ? '补齐中' : '补齐已读',
                  ),
                ),
              ],
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

  List<int> _readMissingChapters(BookInsightCoverage coverage) {
    return coverage.missingChapters
        .where((chapterIndex) => chapterIndex < coverage.readChapters)
        .toList(growable: false);
  }

  Future<void> _generateChapterSummary(int chapterIndex) async {
    await widget.onGenerateChapter(chapterIndex);
    await widget.provider.refresh();
  }

  Future<void> _generateMissingReadSummaries(List<int> chapterIndexes) async {
    if (_isBackfillingSummaries || chapterIndexes.isEmpty) return;
    final onGenerate = widget.onGenerateMissingReadChapters;
    if (onGenerate == null) return;

    setState(() => _isBackfillingSummaries = true);
    try {
      final generatedCount = await onGenerate(chapterIndexes);
      await widget.provider.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generatedCount > 0
                ? '已补齐 $generatedCount 个已读章节摘要'
                : '没有需要补齐的已读章节摘要',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackfillingSummaries = false);
    }
  }

  Future<void> _generateReadScopeSynthesis(BookInsightProvider provider) async {
    await provider.generateReadScopeSynthesis();
    if (!mounted || provider.error != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已生成已读范围分析'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmAndGenerateFullBook(BookInsightProvider provider) async {
    final confirmed = await showFlowDialog<bool>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: const Text('生成全书分析'),
        content: const Text('全书分析可能包含尚未阅读章节的情节。'),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FlowButton.primary(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('生成'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.generateFullBookSynthesis();
    if (!mounted || provider.error != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已生成全书分析'),
        behavior: SnackBarBehavior.floating,
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

  Widget _buildInlineEmpty(ThemeData theme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.chapterIndex,
    required this.description,
    this.detail,
    this.source,
  });

  factory _TimelineEvent.fromAnalysis(StoryEvent event) {
    final source = event.anchors.isEmpty
        ? null
        : event.anchors.first.quoteSnippet;
    return _TimelineEvent(
      chapterIndex: event.chapterIndex,
      description: event.description,
      detail: event.participants.isEmpty
          ? null
          : '人物: ${event.participants.join(', ')}',
      source: source,
    );
  }

  factory _TimelineEvent.fromLegacy(StorylineEvent event) {
    return _TimelineEvent(
      chapterIndex: event.chapterIndex,
      description: event.description,
      detail: event.significance,
      source: event.source,
    );
  }

  final int chapterIndex;
  final String description;
  final String? detail;
  final String? source;
}
