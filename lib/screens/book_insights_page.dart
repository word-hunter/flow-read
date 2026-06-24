import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flow_ai/flow_ai.dart';

import '../models/book_glossary_entry.dart';
import '../providers/book_insight_provider.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/reader_shell/reader_right_assistant_panel.dart';
import '../widgets/reader_shell/reader_workspace_controller.dart';

const _insightBackground = Color(0xFFFEFCF9);
const _insightBorder = Color(0xFFECE3D7);
const _insightCard = Color(0xFFFFFEFC);
const _insightMuted = Color(0xFF6F7785);
const _insightPrimary = Color(0xFF1677FF);
const _insightDanger = Color(0xFFD43C3C);
const _insightText = Color(0xFF172033);
const _insightHover = Color(0xFFF3F8FF);
const _insightPrimaryHover = Color(0xFF0F6BEF);
const _insightPrimaryPressed = Color(0xFF0B5ED7);
const _insightDangerHover = Color(0xFFFFF4F4);
const _insightDangerPressed = Color(0xFFFFEAEA);

class BookInsightChapterGenerationResult {
  const BookInsightChapterGenerationResult.generated()
    : isGenerated = true,
      message = null;

  const BookInsightChapterGenerationResult.notGenerated(this.message)
    : isGenerated = false;

  final bool isGenerated;
  final String? message;
}

class BookInsightsPage extends StatefulWidget {
  const BookInsightsPage({
    super.key,
    required this.provider,
    required this.bookTitle,
    required this.onGenerateChapter,
    this.onGenerateMissingReadChapters,
    this.onAskAI,
    this.aiPanelBuilder,
  });

  final BookInsightProvider provider;
  final String bookTitle;
  final Future<BookInsightChapterGenerationResult> Function(int chapterIndex)
  onGenerateChapter;
  final Future<int> Function(List<int> chapterIndexes)?
  onGenerateMissingReadChapters;
  final bool Function(BuildContext context)? onAskAI;
  final Widget Function(VoidCallback onClose)? aiPanelBuilder;

  @override
  State<BookInsightsPage> createState() => _BookInsightsPageState();
}

class _BookInsightsPageState extends State<BookInsightsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ReaderWorkspaceController _assistantPanelController;

  bool _requestedLoad = false;
  bool _isBackfillingSummaries = false;
  final Set<int> _generatingChapterIndexes = <int>{};
  String? _selectedCharacterName;
  String _glossaryQuery = '';
  bool _showOnlyUnlockedTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _assistantPanelController = ReaderWorkspaceController(
      leftPanelOpen: false,
      rightPanelOpen: false,
      rightTab: ReaderRightPanelTab.ai,
    );
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
    _assistantPanelController.dispose();
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
      backgroundColor: _insightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showAssistantPanel =
              _assistantPanelController.isRightPanelOpen &&
              widget.aiPanelBuilder != null;
          final mainContent = Column(
            children: [
              _BookInsightsHeader(
                bookTitle: widget.bookTitle,
                provider: provider,
                onBack: () => Navigator.pop(context),
                onSelectBoundary: (mode) => _selectBoundaryMode(provider, mode),
                onAskAI: widget.onAskAI == null || widget.aiPanelBuilder == null
                    ? null
                    : _openAssistantPanel,
              ),
              _BookInsightsTabStrip(controller: _tabController),
              Expanded(child: _buildBody(theme, provider)),
            ],
          );

          if (!showAssistantPanel) {
            return mainContent;
          }

          if (constraints.maxWidth < 760) {
            return _buildAssistantPanel();
          }

          return Row(
            children: [
              Expanded(child: mainContent),
              const VerticalDivider(width: 1, color: _insightBorder),
              SizedBox(
                width: _assistantPanelWidth(constraints.maxWidth),
                child: _buildAssistantPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAssistantPanel() {
    final onAskAI = widget.onAskAI;
    if (onAskAI == null || widget.aiPanelBuilder == null) return;
    final prepared = onAskAI(context);
    if (!prepared) return;
    _assistantPanelController.openRightPanel(ReaderRightPanelTab.ai);
    if (mounted) setState(() {});
  }

  void _closeAssistantPanel() {
    _assistantPanelController.closeRightPanel();
    if (mounted) setState(() {});
  }

  void _selectAssistantPanelTab(ReaderRightPanelTab tab) {
    _assistantPanelController.setRightTab(tab);
    if (mounted) setState(() {});
  }

  double _assistantPanelWidth(double availableWidth) {
    if (availableWidth < 980) return 360;
    return math.min(430, math.max(380, availableWidth * 0.3));
  }

  Widget _buildAssistantPanel() {
    return ReaderRightAssistantPanel(
      workspaceController: _assistantPanelController,
      onTabSelected: _selectAssistantPanelTab,
      onClose: _closeAssistantPanel,
      dictionaryContent: const _InsightAssistantEmptyState(
        icon: Icons.text_fields_outlined,
        message: '在阅读页点选单词后查看释义',
      ),
      aiContent: widget.aiPanelBuilder!(_closeAssistantPanel),
      chapterContent: const _InsightAssistantEmptyState(
        icon: Icons.insights_outlined,
        message: '章节统计仍在阅读页显示',
      ),
    );
  }

  Widget _buildBody(ThemeData theme, BookInsightProvider provider) {
    if (provider.isLoading && provider.coverage == null) {
      return _buildLoading(theme);
    }
    if (provider.error != null && provider.coverage == null) {
      return _buildError(theme, provider.error!, provider);
    }
    if (provider.isEmpty && provider.coverage == null) {
      return _buildEmpty(theme);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildStoryline(theme, provider),
        _buildCharacters(theme, provider),
        _buildGlossary(theme, provider),
        _buildChapterList(theme, provider),
      ],
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            '正在整理书籍洞察',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    ThemeData theme,
    String error,
    BookInsightProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(error, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FlowButton.secondary(
              onPressed: () => unawaited(provider.refresh()),
              icon: const Icon(Icons.refresh, size: 16),
              child: const Text('重试'),
            ),
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
              '在阅读器中为章节生成 AI 总结后，这里将展示梗概、人物、术语和章节时间线。',
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
    final synthesis = provider.visibleSynthesis;
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 118),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1156),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.coverage != null)
                        _buildCoverageStrip(theme, provider),
                      const SizedBox(height: 16),
                      _buildSynthesisOverview(theme, provider, synthesis),
                      if (synthesis != null &&
                          synthesis.keyInsights.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildKeyInsights(theme, synthesis.keyInsights),
                      ],
                      if (synthesis != null &&
                          (synthesis.themeAnalysis.trim().isNotEmpty ||
                              synthesis.structure.trim().isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        _buildThemeAndStructure(theme, synthesis),
                      ],
                      if (_hasLockedFuture(provider)) ...[
                        const SizedBox(height: 12),
                        _buildLockedCard(
                          theme,
                          nextChapter: provider.boundaryChapter + 2,
                          message: '后续情节发展、人物命运和更深入的主题分析会在读到后解锁。',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StorylineActionBar(
            provider: provider,
            onGenerateReadScope: () =>
                unawaited(_generateReadScopeSynthesis(provider)),
            onGenerateFullBook: () =>
                unawaited(_confirmAndGenerateFullBook(provider)),
          ),
        ),
      ],
    );
  }

  Widget _buildSynthesisOverview(
    ThemeData theme,
    BookInsightProvider provider,
    BookSynthesisResult? synthesis,
  ) {
    if (provider.isGeneratingVisibleSynthesis) {
      return _SectionCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.description_outlined,
              title: '故事梗概',
              subtitle: _boundaryLabel(provider),
            ),
            const SizedBox(height: 16),
            _SkeletonLine(widthFactor: 0.92),
            const SizedBox(height: 10),
            _SkeletonLine(widthFactor: 0.98),
            const SizedBox(height: 10),
            _SkeletonLine(widthFactor: 0.74),
          ],
        ),
      );
    }

    if (synthesis == null || synthesis.fullStoryline.trim().isEmpty) {
      return _SectionCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 320,
          child: _EmptyState(
            icon: Icons.auto_awesome,
            title: '还没有当前范围梗概',
            message: '生成后会在这里显示截至当前剧透边界的故事主线。',
            action: _InlinePrimaryButton(
              onPressed: provider.canGenerateSynthesis
                  ? () => unawaited(_generateReadScopeSynthesis(provider))
                  : null,
              icon: Icons.refresh,
              label: '生成当前范围梗概',
            ),
          ),
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.description_outlined,
            title: '故事梗概',
            subtitle:
                '${_boundaryLabel(provider)} · 生成于 ${_formatTime(synthesis.generatedAt)}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.showFullBook) ...[
                  _StatusPill(
                    label: '剧透模式',
                    icon: Icons.warning_amber_outlined,
                    foreground: theme.colorScheme.error,
                    background: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.keyboard_arrow_down, color: _insightMuted),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            synthesis.fullStoryline.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.75,
              color: _insightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights(ThemeData theme, List<String> insights) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SquareIcon(
                icon: Icons.lightbulb_outline,
                background: Color(0xFFFFF3DA),
                foreground: Color(0xFF8A640F),
              ),
              const SizedBox(width: 14),
              Text(
                '关键洞察',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _insightText,
                ),
              ),
            ],
          );
          final chips = Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final insight in insights) _InsightChip(label: insight),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                chips,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              title,
              const SizedBox(width: 24),
              Expanded(child: chips),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeAndStructure(
    ThemeData theme,
    BookSynthesisResult synthesis,
  ) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SquareIcon(
                icon: Icons.view_sidebar_outlined,
                background: Color(0xFFF2ECFF),
                foreground: Color(0xFF5E4B8B),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '主题 / 结构',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _insightText,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_up, color: _insightMuted),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final themePanel = _TextBlock(
                title: '主题分析',
                text: synthesis.themeAnalysis,
              );
              final structurePanel = _TextBlock(
                title: '结构',
                text: synthesis.structure,
              );
              if (!isWide) {
                return Column(
                  children: [
                    themePanel,
                    const SizedBox(height: 14),
                    Divider(color: _insightBorder),
                    const SizedBox(height: 14),
                    structurePanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: themePanel),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: SizedBox(
                      height: 132,
                      child: VerticalDivider(color: _insightBorder),
                    ),
                  ),
                  Expanded(child: structurePanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacters(ThemeData theme, BookInsightProvider provider) {
    final items = _characterItems(provider);
    final graph =
        provider.visibleSynthesis?.characterGraph ??
        const CharacterRelationGraph();
    _selectedCharacterName = _effectiveSelectedCharacter(items, graph);

    if (items.isEmpty && graph.nodes.isEmpty && graph.edges.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _EmptyState(
            icon: Icons.person_outline,
            title: '暂无人物数据',
            message: '生成章节总结或当前范围梗概后，会在这里合并人物卡片与关系图谱。',
            action: FlowButton.secondary(
              onPressed: provider.canMaintainCharacters
                  ? () => _showAddCharacterDialog(provider)
                  : null,
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              child: const Text('新增人物'),
            ),
          ),
          if (_hasLockedFuture(provider)) ...[
            const SizedBox(height: 12),
            _buildLockedCard(
              theme,
              nextChapter: provider.boundaryChapter + 2,
              message: '后续登场人物会在读到对应章节后显示。',
            ),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (!isWide) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildCharacterListPanel(theme, provider, items, embedded: true),
              const SizedBox(height: 16),
              _buildCharacterSidePanel(
                theme,
                provider,
                items,
                graph,
                embedded: true,
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: math.min(520, constraints.maxWidth * 0.46),
                child: _buildCharacterListPanel(theme, provider, items),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildCharacterSidePanel(theme, provider, items, graph),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterListPanel(
    ThemeData theme,
    BookInsightProvider provider,
    List<_CharacterInsightItem> items, {
    bool embedded = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            embedded ? 0 : 4,
            0,
            embedded ? 0 : 4,
            12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '人物列表',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FlowButton.secondary(
                onPressed: provider.canMaintainCharacters
                    ? () => _showAddCharacterDialog(provider)
                    : null,
                icon: const Icon(Icons.add, size: 16),
                child: const Text('新增人物'),
              ),
            ],
          ),
        ),
        for (final item in items)
          _CharacterInsightCard(
            item: item,
            selected: item.canonicalName == _selectedCharacterName,
            canMaintainCharacters: provider.canMaintainCharacters,
            onTap: () =>
                setState(() => _selectedCharacterName = item.canonicalName),
            onConfirm: item.confirmationCard == null
                ? null
                : () => unawaited(
                    provider.confirmCharacterCard(item.confirmationCard!),
                  ),
            onAddAlias: item.isRegistered
                ? () => _showAddAliasDialog(provider, item.canonicalName)
                : null,
            onDelete: item.isRegistered
                ? () => _confirmDeleteCharacter(provider, item.canonicalName)
                : null,
            onRemoveAlias: item.isRegistered
                ? (alias) => unawaited(
                    provider.removeCharacterAlias(item.canonicalName, alias),
                  )
                : null,
          ),
        if (_hasLockedFuture(provider))
          _buildLockedCard(
            theme,
            nextChapter: provider.boundaryChapter + 2,
            message: '包含后续情节发展、人物命运与重要关系。',
          ),
      ],
    );

    if (embedded) return content;
    return ClipRect(child: ListView(children: [content]));
  }

  Widget _buildCharacterSidePanel(
    ThemeData theme,
    BookInsightProvider provider,
    List<_CharacterInsightItem> items,
    CharacterRelationGraph graph, {
    bool embedded = false,
  }) {
    final selectedItem = _selectedCharacterName == null
        ? null
        : items
              .where((item) => item.canonicalName == _selectedCharacterName)
              .firstOrNull;
    final selectedNode = _nodeForCharacter(graph, _selectedCharacterName);
    final selectedEdges = _edgesForSelected(
      graph,
      selectedNode,
      _selectedCharacterName,
    );

    final children = [
      _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.hub_outlined,
              title: '人物关系图谱',
              trailing: Wrap(
                spacing: 8,
                children: [
                  FlowButton.secondary(
                    onPressed:
                        provider.canGenerateSynthesis &&
                            !provider.isGeneratingReadScopeSynthesis
                        ? () => unawaited(_generateReadScopeSynthesis(provider))
                        : null,
                    icon: const Icon(Icons.refresh, size: 16),
                    child: const Text('刷新图谱'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (graph.nodes.isEmpty && graph.edges.isEmpty)
              _EmptyState(
                icon: Icons.account_tree_outlined,
                title: '暂无关系图谱',
                message: '生成当前范围梗概后会同步产出人物关系。',
                action: FlowButton.secondary(
                  onPressed: provider.canGenerateSynthesis
                      ? () => unawaited(_generateReadScopeSynthesis(provider))
                      : null,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  child: const Text('生成图谱'),
                ),
              )
            else
              _RelationGraphView(
                graph: graph,
                selectedName: _selectedCharacterName,
                onSelected: (name) =>
                    setState(() => _selectedCharacterName = name),
              ),
          ],
        ),
      ),
      if (selectedItem != null) ...[
        const SizedBox(height: 14),
        _SelectedCharacterDetail(
          item: selectedItem,
          relatedEdges: selectedEdges,
          graph: graph,
        ),
      ] else if (selectedEdges.isNotEmpty) ...[
        const SizedBox(height: 14),
        _RelationEvidenceList(edges: selectedEdges, graph: graph),
      ],
    ];

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ClipRect(child: ListView(children: children));
  }

  Widget _buildGlossary(ThemeData theme, BookInsightProvider provider) {
    final query = _glossaryQuery.trim().toLowerCase();
    final entries = provider.glossaryEntries
        .where((entry) {
          if (query.isEmpty) return true;
          return entry.word.toLowerCase().contains(query) ||
              (entry.canonicalForm?.toLowerCase().contains(query) ?? false) ||
              entry.explanation.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '本书术语表',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '已收录 ${provider.glossaryEntries.length} 个术语',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: FlowTextField(
                        placeholder: '搜索术语',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        onChanged: (value) {
                          setState(() => _glossaryQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      selected: _showOnlyUnlockedTerms,
                      avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                      label: const Text('仅显示已解锁'),
                      onSelected: (value) {
                        setState(() => _showOnlyUnlockedTerms = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  _EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: provider.glossaryEntries.isEmpty
                        ? '暂无本书术语'
                        : '没有匹配的术语',
                    message: provider.glossaryEntries.isEmpty
                        ? '术语会从章节分析和阅读记忆中自动汇总。'
                        : '换一个关键词试试。',
                  )
                else
                  for (final entry in entries) _buildGlossaryCard(theme, entry),
                if (_hasLockedFuture(provider)) ...[
                  const SizedBox(height: 4),
                  _buildLockedCard(
                    theme,
                    nextChapter: provider.boundaryChapter + 2,
                    message: '该术语可能含有潜在剧透内容，解锁后可查看完整解释与原文语境。',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlossaryCard(ThemeData theme, BookGlossaryEntry entry) {
    final canonical = entry.canonicalForm?.trim();
    final context = entry.sourceContext?.trim();

    return _SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIcon(
            icon: Icons.article_outlined,
            background: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.55,
            ),
            foreground: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.word,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FlowButton.text(
                      onPressed: () => _showFeatureSnack('术语解释会使用当前剧透边界作为上下文。'),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      child: const Text('解释该术语'),
                    ),
                  ],
                ),
                if (canonical != null &&
                    canonical.isNotEmpty &&
                    canonical.toLowerCase() != entry.word.toLowerCase()) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '规范形：',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        canonical,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(entry.explanation, style: theme.textTheme.bodyMedium),
                if (context != null && context.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _QuoteBox(text: context, label: '原文语境'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList(ThemeData theme, BookInsightProvider provider) {
    final coverage = provider.coverage;
    if (coverage == null) return _buildEmptyTab(theme, '暂无章节数据');
    final chapterGroups = _chapterGroups(provider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 96),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCoverageStrip(theme, provider),
                const SizedBox(height: 18),
                for (var i = 0; i < coverage.totalChapters; i++)
                  _buildChapterTimelineItem(
                    theme,
                    provider,
                    chapterIndex: i,
                    group: chapterGroups[i],
                    readChapters: coverage.readChapters,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterTimelineItem(
    ThemeData theme,
    BookInsightProvider provider, {
    required int chapterIndex,
    required _ChapterInsightGroup? group,
    required int readChapters,
  }) {
    final isUnlocked = chapterIndex <= provider.boundaryChapter;
    final isRead = chapterIndex < readChapters;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineRail(
          chapterNumber: chapterIndex + 1,
          locked: !isUnlocked,
          active: isUnlocked && group != null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: !isUnlocked
                ? _buildLockedCard(
                    theme,
                    nextChapter: chapterIndex + 1,
                    message: '第 ${chapterIndex + 1} 章后解锁更多内容。',
                  )
                : group != null
                ? _buildChapterSummaryCard(theme, chapterIndex, group)
                : _buildChapterMissingCard(theme, chapterIndex, isRead),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterSummaryCard(
    ThemeData theme,
    int chapterIndex,
    _ChapterInsightGroup group,
  ) {
    final summary = group.summary;
    final events = group.events;
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: chapterIndex < 2,
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Row(
          children: [
            Text(
              '第 ${chapterIndex + 1} 章',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                events.isNotEmpty ? events.first.description : '已总结',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final eventPanel = _ChapterEventPanel(events: events);
              final guidancePanel = _ReadingGuidancePanel(
                guidance: summary?.readingGuidance ?? '',
              );
              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    eventPanel,
                    const SizedBox(height: 14),
                    guidancePanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: eventPanel),
                  const SizedBox(width: 22),
                  Expanded(child: guidancePanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChapterMissingCard(
    ThemeData theme,
    int chapterIndex,
    bool isRead,
  ) {
    final isGenerating = _generatingChapterIndexes.contains(chapterIndex);
    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第 ${chapterIndex + 1} 章',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRead ? '已读，尚未生成洞察' : '未读章节',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isRead)
            FlowButton.secondary(
              onPressed: isGenerating
                  ? null
                  : () => unawaited(_generateChapterSummary(chapterIndex)),
              icon: isGenerating
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              child: Text(isGenerating ? '生成中' : '生成'),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverageStrip(ThemeData theme, BookInsightProvider provider) {
    final coverage = provider.coverage;
    if (coverage == null) return const SizedBox.shrink();
    final readMissingChapters = _readMissingChapters(coverage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final status = Text(
          '已总结 ${coverage.summarizedChapters}/${coverage.totalChapters} 章',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );
        final progress = Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: coverage.percentage,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF2EEE8),
                  valueColor: const AlwaysStoppedAnimation(_insightPrimary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${(coverage.percentage * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: _insightMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
        final button = OutlinedButton.icon(
          onPressed:
              _isBackfillingSummaries ||
                  readMissingChapters.isEmpty ||
                  widget.onGenerateMissingReadChapters == null
              ? null
              : () => unawaited(
                  _generateMissingReadSummaries(readMissingChapters),
                ),
          icon: _isBackfillingSummaries
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add_check, size: 16),
          label: Text(_isBackfillingSummaries ? '补齐中' : '补齐已读'),
          style: ButtonStyle(
            fixedSize: WidgetStateProperty.all(const Size(132, 40)),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return _insightMuted;
              }
              return _insightPrimary;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return _insightCard;
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFEAF4FF);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return _insightHover;
              }
              return _insightCard;
            }),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(color: Color(0xFFE5DDD2));
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)) {
                return const BorderSide(color: _insightPrimary, width: 1.2);
              }
              return const BorderSide(color: Color(0xFF9BC5FF));
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textStyle: WidgetStateProperty.all(
              theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: _insightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _insightBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: status,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: progress,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: button,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const SizedBox(width: 18),
                      SizedBox(width: 160, child: status),
                      Expanded(child: progress),
                      const SizedBox(width: 20),
                      button,
                      const SizedBox(width: 18),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLockedCard(
    ThemeData theme, {
    required int nextChapter,
    required String message,
  }) {
    return CustomPaint(
      painter: const _DashedRoundedBorderPainter(
        color: Color(0xFFD5CDC2),
        radius: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _insightCard.withValues(alpha: 0.72),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFC7C7C7), Color(0xFFE4E1DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第 $nextChapter 章后解锁',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _insightMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _insightMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  List<_CharacterInsightItem> _characterItems(BookInsightProvider provider) {
    final registryEntries = provider.characterRegistryEntries;
    final analysisCards =
        provider.analysisData?.characters ?? const <CharacterCard>[];
    final legacyCards = provider.characterCards;
    final registeredNames = registryEntries
        .map((entry) => entry.canonicalName.toLowerCase())
        .toSet();
    final analysisByName = {
      for (final card in analysisCards) card.canonicalName.toLowerCase(): card,
    };
    final legacyByName = {
      for (final card in legacyCards) card.canonicalName.toLowerCase(): card,
    };

    final items = <_CharacterInsightItem>[
      for (final entry in registryEntries)
        _CharacterInsightItem.fromRegistry(
          entry,
          analysis: analysisByName[entry.canonicalName.toLowerCase()],
          legacy: legacyByName[entry.canonicalName.toLowerCase()],
        ),
      for (final card in analysisCards)
        if (!registeredNames.contains(card.canonicalName.toLowerCase()))
          _CharacterInsightItem.fromAnalysis(card),
      for (final card in legacyCards)
        if (!registeredNames.contains(card.canonicalName.toLowerCase()) &&
            !analysisByName.containsKey(card.canonicalName.toLowerCase()))
          _CharacterInsightItem.fromLegacy(card),
    ];

    items.sort((a, b) {
      final first = a.firstChapter.compareTo(b.firstChapter);
      if (first != 0) return first;
      return a.canonicalName.compareTo(b.canonicalName);
    });
    return items;
  }

  Map<int, _ChapterInsightGroup> _chapterGroups(BookInsightProvider provider) {
    final groups = <int, _ChapterInsightGroup>{};
    for (final entry in provider.chapterSummaries.entries) {
      groups[entry.key] = _ChapterInsightGroup(summary: entry.value);
    }
    for (final event
        in provider.analysisData?.storyEvents ?? const <StoryEvent>[]) {
      groups
          .putIfAbsent(event.chapterIndex, () => const _ChapterInsightGroup())
          .storyEvents
          .add(event);
    }
    return groups;
  }

  List<int> _readMissingChapters(BookInsightCoverage coverage) {
    return coverage.missingChapters
        .where((chapterIndex) => chapterIndex < coverage.readChapters)
        .toList(growable: false);
  }

  bool _hasLockedFuture(BookInsightProvider provider) {
    return !provider.showFullBook &&
        provider.totalChapters > 0 &&
        provider.boundaryChapter < provider.totalChapters - 1;
  }

  String _boundaryLabel(BookInsightProvider provider) {
    if (provider.showFullBook) return '全书范围';
    if (provider.isFollowingProgress) {
      return '截至第 ${provider.boundaryChapter + 1} 章';
    }
    return '回看到第 ${provider.boundaryChapter + 1} 章';
  }

  String? _effectiveSelectedCharacter(
    List<_CharacterInsightItem> items,
    CharacterRelationGraph graph,
  ) {
    final current = _selectedCharacterName;
    if (current != null &&
        (items.any((item) => item.canonicalName == current) ||
            graph.nodes.any((node) => node.label == current))) {
      return current;
    }
    if (items.isNotEmpty) return items.first.canonicalName;
    if (graph.nodes.isNotEmpty) return graph.nodes.first.label;
    return null;
  }

  Future<void> _selectBoundaryMode(
    BookInsightProvider provider,
    _SpoilerBoundaryMode mode,
  ) async {
    switch (mode) {
      case _SpoilerBoundaryMode.follow:
        await provider.followReadingProgress();
      case _SpoilerBoundaryMode.manual:
        await _showReadBoundaryDialog(provider);
      case _SpoilerBoundaryMode.full:
        await _confirmFullBookMode(provider);
    }
  }

  Future<void> _showReadBoundaryDialog(BookInsightProvider provider) async {
    final maxChapter = math.max(0, provider.currentChapter);
    var selected = provider.boundaryChapter.clamp(0, maxChapter);
    final confirmed = await showFlowDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => FlowDialog(
          title: const Text('回看到章节'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前边界：第 ${selected + 1} 章'),
                Slider(
                  min: 0,
                  max: maxChapter.toDouble(),
                  divisions: maxChapter == 0 ? null : maxChapter,
                  value: selected.toDouble(),
                  label: '第 ${selected + 1} 章',
                  onChanged: (value) {
                    setDialogState(() => selected = value.round());
                  },
                ),
              ],
            ),
          ),
          actions: [
            FlowButton.text(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FlowButton.primary(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null) return;
    await provider.setReadBoundaryChapter(confirmed);
  }

  Future<void> _confirmFullBookMode(BookInsightProvider provider) async {
    if (provider.showFullBook) return;
    final confirmed = await showFlowDialog<bool>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: const Text('开启全书剧透模式'),
        content: const Text('全书洞察会展示尚未阅读章节中的人物关系、事件和术语。'),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FlowButton.destructive(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('开启'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.setFullBookMode(true);
  }

  Future<void> _generateChapterSummary(int chapterIndex) async {
    if (_generatingChapterIndexes.contains(chapterIndex)) return;
    setState(() => _generatingChapterIndexes.add(chapterIndex));
    try {
      final result = await widget.onGenerateChapter(chapterIndex);
      await widget.provider.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isGenerated
                ? '已生成第 ${chapterIndex + 1} 章洞察'
                : '未生成第 ${chapterIndex + 1} 章洞察：${result.message ?? 'AI 未返回可用总结，请稍后重试或检查模型服务响应。'}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('第 ${chapterIndex + 1} 章洞察生成失败：$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingChapterIndexes.remove(chapterIndex));
      }
    }
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
        content: Text('已生成当前范围梗概'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmAndGenerateFullBook(BookInsightProvider provider) async {
    final confirmed = await showFlowDialog<bool>(
      context: context,
      builder: (dialogContext) => FlowDialog(
        title: const Text('生成全书梗概'),
        content: const Text('全书梗概可能包含尚未阅读章节的情节和人物关系。'),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FlowButton.destructive(
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
        content: Text('已生成全书梗概'),
        behavior: SnackBarBehavior.floating,
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

  void _showFeatureSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _BookInsightsHeader extends StatelessWidget {
  const _BookInsightsHeader({
    required this.bookTitle,
    required this.provider,
    required this.onBack,
    required this.onSelectBoundary,
    required this.onAskAI,
  });

  final String bookTitle;
  final BookInsightProvider provider;
  final VoidCallback onBack;
  final ValueChanged<_SpoilerBoundaryMode> onSelectBoundary;
  final VoidCallback? onAskAI;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1100 ? 52.0 : 16.0;
    final compact = width < 900;

    return Container(
      height: compact ? 108 : 116,
      decoration: const BoxDecoration(
        color: _insightBackground,
        border: Border(bottom: BorderSide(color: _insightBorder)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: compact ? 12 : 18,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '书籍洞察',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _insightText,
                ),
              ),
            ),
          ),
          Positioned(
            left: horizontal,
            top: compact ? 38 : 40,
            child: _RoundBackButton(onPressed: onBack),
          ),
          Positioned(
            left: horizontal,
            right: compact ? 96 : null,
            top: compact ? 78 : 82,
            child: _BookTitleLine(
              title: bookTitle,
              maxWidth: compact ? null : 420,
            ),
          ),
          Positioned(
            right: horizontal,
            top: compact ? 34 : 36,
            child: _ToolbarActions(
              provider: provider,
              onSelectBoundary: onSelectBoundary,
              onAskAI: onAskAI,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: '返回',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFEAF4FF);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return _insightHover;
            }
            return _insightCard;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return _insightPrimary;
            }
            return _insightText;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(const CircleBorder()),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return const BorderSide(color: Color(0xFF9BC5FF));
            }
            return const BorderSide(color: _insightBorder);
          }),
        ),
      ),
    );
  }
}

class _BookTitleLine extends StatelessWidget {
  const _BookTitleLine({
    required this.title,
    required this.maxWidth,
  });

  final String title;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF314A63),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.menu_book,
            size: 12,
            color: Color(0xFFE8DCC7),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2E3442),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.keyboard_arrow_down, size: 16, color: _insightMuted),
      ],
    );

    if (maxWidth == null) return content;
    return SizedBox(width: maxWidth, child: content);
  }
}

class _BookInsightsTabStrip extends StatelessWidget {
  const _BookInsightsTabStrip({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: _insightBackground,
        border: Border(bottom: BorderSide(color: _insightBorder)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: TabBar(
            controller: controller,
            indicatorColor: _insightPrimary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 42),
            dividerColor: Colors.transparent,
            labelColor: _insightPrimary,
            unselectedLabelColor: _insightMuted,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFE5F1FF);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return _insightHover;
              }
              return Colors.transparent;
            }),
            splashBorderRadius: BorderRadius.circular(8),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(
                child: _TabLabel(icon: Icons.home_work_outlined, label: '故事线'),
              ),
              Tab(
                child: _TabLabel(icon: Icons.person_outline, label: '人物'),
              ),
              Tab(
                child: _TabLabel(icon: Icons.menu_book_outlined, label: '术语'),
              ),
              Tab(
                child: _TabLabel(icon: Icons.list_alt_outlined, label: '章节'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineActionBar extends StatelessWidget {
  const _StorylineActionBar({
    required this.provider,
    required this.onGenerateReadScope,
    required this.onGenerateFullBook,
  });

  final BookInsightProvider provider;
  final VoidCallback onGenerateReadScope;
  final VoidCallback onGenerateFullBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: _insightBackground.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: _insightBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 10,
          children: [
            _StoryActionButton.primary(
              onPressed:
                  provider.canGenerateSynthesis &&
                      !provider.isGeneratingReadScopeSynthesis
                  ? onGenerateReadScope
                  : null,
              loading: provider.isGeneratingReadScopeSynthesis,
              icon: Icons.refresh,
              label: provider.isGeneratingReadScopeSynthesis
                  ? '生成中'
                  : '生成 / 刷新当前范围梗概',
            ),
            _StoryActionButton.danger(
              onPressed:
                  provider.canGenerateSynthesis &&
                      !provider.isGeneratingFullBookSynthesis
                  ? onGenerateFullBook
                  : null,
              loading: provider.isGeneratingFullBookSynthesis,
              icon: Icons.warning_amber_outlined,
              label: provider.isGeneratingFullBookSynthesis
                  ? '生成中'
                  : '生成全书梗概（含剧透）',
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryActionButton extends StatelessWidget {
  const _StoryActionButton._({
    required this.onPressed,
    required this.loading,
    required this.icon,
    required this.label,
    required this.danger,
  });

  const _StoryActionButton.primary({
    required VoidCallback? onPressed,
    required bool loading,
    required IconData icon,
    required String label,
  }) : this._(
         onPressed: onPressed,
         loading: loading,
         icon: icon,
         label: label,
         danger: false,
       );

  const _StoryActionButton.danger({
    required VoidCallback? onPressed,
    required bool loading,
    required IconData icon,
    required String label,
  }) : this._(
         onPressed: onPressed,
         loading: loading,
         icon: icon,
         label: label,
         danger: true,
       );

  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final spinner = SizedBox.square(
      dimension: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: danger ? _insightDanger : Colors.white,
      ),
    );

    if (danger) {
      return SizedBox(
        width: 292,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: loading ? spinner : Icon(icon, size: 18),
          label: Text(label),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return _insightMuted;
              }
              return _insightDanger;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return _insightDangerPressed;
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return _insightDangerHover;
              }
              return _insightCard;
            }),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(color: Color(0xFFE5DDD2));
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)) {
                return const BorderSide(color: _insightDanger, width: 1.2);
              }
              return const BorderSide(color: Color(0xFFFF6B6B));
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textStyle: WidgetStateProperty.all(textStyle),
            fixedSize: WidgetStateProperty.all(const Size(292, 48)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 320,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: loading ? spinner : Icon(icon, size: 18),
        label: Text(label),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF9BCBFF);
            }
            if (states.contains(WidgetState.pressed)) {
              return _insightPrimaryPressed;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return _insightPrimaryHover;
            }
            return _insightPrimary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(textStyle),
          fixedSize: WidgetStateProperty.all(const Size(320, 48)),
        ),
      ),
    );
  }
}

class _ToolbarActions extends StatelessWidget {
  const _ToolbarActions({
    required this.provider,
    required this.onSelectBoundary,
    required this.onAskAI,
  });

  final BookInsightProvider provider;
  final ValueChanged<_SpoilerBoundaryMode> onSelectBoundary;
  final VoidCallback? onAskAI;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 980) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<_SpoilerBoundaryMode>(
            tooltip: '剧透边界',
            icon: const Icon(Icons.visibility_outlined),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFEAF4FF);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return _insightHover;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return _insightPrimary;
                }
                return _insightText;
              }),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            onSelected: onSelectBoundary,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SpoilerBoundaryMode.follow,
                child: Text('跟随进度'),
              ),
              PopupMenuItem(
                value: _SpoilerBoundaryMode.manual,
                child: Text('回看到第 ${provider.boundaryChapter + 1} 章'),
              ),
              const PopupMenuItem(
                value: _SpoilerBoundaryMode.full,
                child: Text('全书（含剧透）'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'AI 提问',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: onAskAI,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFEAF4FF);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return _insightHover;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return _insightPrimary;
                }
                return _insightText;
              }),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }

    final mode = provider.showFullBook
        ? _SpoilerBoundaryMode.full
        : provider.isManualReadBoundary
        ? _SpoilerBoundaryMode.manual
        : _SpoilerBoundaryMode.follow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 380,
          child: SegmentedButton<_SpoilerBoundaryMode>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return const BorderSide(color: Color(0xFFB7D7FF));
                }
                return const BorderSide(color: _insightBorder);
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  if (states.contains(WidgetState.pressed)) {
                    return const Color(0xFFD8EBFF);
                  }
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)) {
                    return const Color(0xFFDFF0FF);
                  }
                  return const Color(0xFFEAF4FF);
                }
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFFEAF4FF);
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return _insightHover;
                }
                return _insightCard;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _insightPrimary;
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused) ||
                    states.contains(WidgetState.pressed)) {
                  return _insightPrimary;
                }
                return const Color(0xFF2E3442);
              }),
              textStyle: WidgetStateProperty.all(
                Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
            segments: [
              const ButtonSegment(
                value: _SpoilerBoundaryMode.follow,
                label: Text('跟随进度'),
              ),
              ButtonSegment(
                value: _SpoilerBoundaryMode.manual,
                label: Text('回看到第 ${provider.boundaryChapter + 1} 章'),
              ),
              const ButtonSegment(
                value: _SpoilerBoundaryMode.full,
                label: Text('全书'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (values) => onSelectBoundary(values.single),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: onAskAI,
          icon: const Icon(Icons.auto_awesome_outlined, size: 16),
          label: const Text('AI 提问'),
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(112, 40)),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return _insightMuted;
              }
              return _insightPrimary;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFEAF4FF);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return _insightHover;
              }
              return _insightCard;
            }),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(color: Color(0xFFE5DDD2));
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)) {
                return const BorderSide(color: _insightPrimary, width: 1.2);
              }
              return const BorderSide(color: Color(0xFF9BC5FF));
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textStyle: WidgetStateProperty.all(
              Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _SpoilerBoundaryMode { follow, manual, full }

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _insightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _insightBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SquareIcon(
          icon: icon,
          background: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.55,
          ),
          foreground: theme.colorScheme.primary,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _insightText,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _insightMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: foreground),
    );
  }
}

class _InlinePrimaryButton extends StatelessWidget {
  const _InlinePrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFB9DFFF);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF66B1FF);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const Color(0xFF78BCFF);
            }
            return const Color(0xFF8DC5FF);
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF354154),
      fontWeight: FontWeight.w500,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _insightCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _insightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: _insightPrimary),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(label, style: textStyle, softWrap: true),
          ),
        ],
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)),
      );

    const dashLength = 6.0;
    const gapLength = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _textLines(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: _insightText,
          ),
        ),
        const SizedBox(height: 8),
        if (lines.isEmpty)
          Text(
            '暂无内容',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _insightMuted,
            ),
          )
        else
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: const Color(0xFF354154),
                ),
              ),
            ),
      ],
    );
  }
}

class _InsightAssistantEmptyState extends StatelessWidget {
  const _InsightAssistantEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: _insightMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _insightMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _insightPrimary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _insightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _insightMuted,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterInsightCard extends StatelessWidget {
  const _CharacterInsightCard({
    required this.item,
    required this.selected,
    required this.canMaintainCharacters,
    required this.onTap,
    this.onConfirm,
    this.onAddAlias,
    this.onDelete,
    this.onRemoveAlias,
  });

  final _CharacterInsightItem item;
  final bool selected;
  final bool canMaintainCharacters;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onAddAlias;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onRemoveAlias;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    child: Text(
                      _avatarLetter(item.canonicalName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.canonicalName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.role != null)
                              _SmallChip(
                                label: item.role!,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '首次出现: 第 ${item.firstChapter + 1} 章',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isRegistered)
                    _StatusPill(
                      label: '已登记',
                      foreground: Colors.green.shade700,
                      background: Colors.green.withValues(alpha: 0.12),
                    )
                  else ...[
                    _StatusPill(
                      label: 'AI 待登记',
                      foreground: Colors.orange.shade800,
                      background: Colors.orange.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 8),
                    FlowButton.secondary(
                      onPressed: canMaintainCharacters ? onConfirm : null,
                      icon: const Icon(Icons.check, size: 16),
                      child: const Text('登记'),
                    ),
                  ],
                  if (item.isRegistered)
                    PopupMenuButton<String>(
                      tooltip: '人物操作',
                      onSelected: (value) {
                        switch (value) {
                          case 'alias':
                            onAddAlias?.call();
                          case 'delete':
                            onDelete?.call();
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
              if (item.aliases.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.aliases
                      .map(
                        (alias) => Chip(
                          label: Text(alias),
                          onDeleted: item.isRegistered && canMaintainCharacters
                              ? () => onRemoveAlias?.call(alias)
                              : null,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (item.traits.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.traits
                      .take(6)
                      .map(
                        (trait) => _SmallChip(
                          label: trait,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (item.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '人物弧光 / 关键行动',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final action in item.actions.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      action,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCharacterDetail extends StatelessWidget {
  const _SelectedCharacterDetail({
    required this.item,
    required this.relatedEdges,
    required this.graph,
  });

  final _CharacterInsightItem item;
  final List<GraphEdge> relatedEdges;
  final CharacterRelationGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _avatarLetter(item.canonicalName),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.canonicalName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.role != null)
                          _SmallChip(
                            label: item.role!,
                            color: theme.colorScheme.primary,
                          ),
                        _StatusPill(
                          label: item.isRegistered ? '已登记' : 'AI 待登记',
                          foreground: item.isRegistered
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          background:
                              (item.isRegistered ? Colors.green : Colors.orange)
                                  .withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.status?.trim().isNotEmpty == true
                          ? item.status!
                          : '该人物的更多定位会随章节洞察逐步补全。',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.traits.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.traits
                  .map(
                    (trait) => _SmallChip(
                      label: trait,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (relatedEdges.isNotEmpty) ...[
            const SizedBox(height: 18),
            _RelationEvidenceList(edges: relatedEdges, graph: graph),
          ],
        ],
      ),
    );
  }
}

class _RelationEvidenceList extends StatelessWidget {
  const _RelationEvidenceList({required this.edges, required this.graph});

  final List<GraphEdge> edges;
  final CharacterRelationGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '关系证据',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FlowButton.text(
              onPressed: null,
              icon: const Icon(Icons.auto_awesome, size: 16),
              child: const Text('解释这段关系'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final edge in edges)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_labelForNode(graph, edge.fromCharacterId)} · ${edge.relation} · ${_labelForNode(graph, edge.toCharacterId)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final anchor in edge.anchors.take(2))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _QuoteBox(
                      text: anchor.quoteSnippet,
                      label: '原文引证 · 第 ${anchor.chapterIndex + 1} 章',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RelationGraphView extends StatelessWidget {
  const _RelationGraphView({
    required this.graph,
    required this.selectedName,
    required this.onSelected,
  });

  final CharacterRelationGraph graph;
  final String? selectedName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodes = _graphNodes(graph);
    if (nodes.isEmpty) {
      return _EmptyState(
        icon: Icons.hub_outlined,
        title: '图谱暂无节点',
        message: '当前综合结果没有可展示的人物关系节点。',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(360.0, constraints.maxWidth);
        final height = width >= 620 ? 300.0 : 260.0;
        final positions = _nodePositions(nodes, Size(width, height));
        final selectedNode = nodes
            .where(
              (node) => node.label == selectedName || node.id == selectedName,
            )
            .firstOrNull;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RelationGraphPainter(
                    graph: graph,
                    positions: positions,
                    nodes: nodes,
                    selectedNodeId: selectedNode?.id,
                    colorScheme: theme.colorScheme,
                  ),
                ),
              ),
              for (final node in nodes)
                Positioned(
                  left: positions[node.id]!.dx - 58,
                  top: positions[node.id]!.dy - 18,
                  width: 116,
                  height: 38,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: node.id == selectedNode?.id
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      foregroundColor: node.id == selectedNode?.id
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: node.id == selectedNode?.id
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => onSelected(node.label),
                    child: Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RelationGraphPainter extends CustomPainter {
  const _RelationGraphPainter({
    required this.graph,
    required this.positions,
    required this.nodes,
    required this.selectedNodeId,
    required this.colorScheme,
  });

  final CharacterRelationGraph graph;
  final Map<String, Offset> positions;
  final List<GraphNode> nodes;
  final String? selectedNodeId;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeIds = nodes.map((node) => node.id).toSet();
    for (final edge in graph.edges) {
      if (!nodeIds.contains(edge.fromCharacterId) ||
          !nodeIds.contains(edge.toCharacterId)) {
        continue;
      }
      final start = positions[edge.fromCharacterId];
      final end = positions[edge.toCharacterId];
      if (start == null || end == null) continue;
      final selected =
          edge.fromCharacterId == selectedNodeId ||
          edge.toCharacterId == selectedNodeId;
      final paint = Paint()
        ..color = selected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.62)
        ..strokeWidth = selected ? 2.4 : 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, paint);
      final label = edge.relation.trim();
      if (label.isEmpty) continue;
      final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 110);
      final labelRect = Rect.fromLTWH(
        midpoint.dx - textPainter.width / 2 - 4,
        midpoint.dy - textPainter.height / 2 - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = colorScheme.surface.withValues(alpha: 0.88),
      );
      textPainter.paint(
        canvas,
        Offset(
          midpoint.dx - textPainter.width / 2,
          midpoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RelationGraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({required this.text, this.label});

  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.44,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(
            '“$text”',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.chapterNumber,
    required this.locked,
    required this.active,
  });

  final int chapterNumber;
  final bool locked;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = locked
        ? theme.colorScheme.outline
        : active
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: active ? 1 : 0.18),
            child: locked
                ? Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : Text(
                    '$chapterNumber',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: active ? theme.colorScheme.onPrimary : color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          Container(
            width: 2,
            height: 76,
            color: color.withValues(alpha: 0.38),
          ),
        ],
      ),
    );
  }
}

class _ChapterEventPanel extends StatelessWidget {
  const _ChapterEventPanel({required this.events});

  final List<_ChapterEventView> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键事件',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Text(
            '暂无事件',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${event.description}',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  if (event.participants.isNotEmpty ||
                      event.location != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final participant in event.participants.take(6))
                          _SmallChip(
                            label: participant,
                            color: theme.colorScheme.primary,
                          ),
                        if (event.location != null)
                          _SmallChip(
                            label: event.location!,
                            color: theme.colorScheme.tertiary,
                          ),
                      ],
                    ),
                  ],
                  if (event.significance?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.significance!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (event.source?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _QuoteBox(text: event.source!, label: '原文引证'),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

class _ReadingGuidancePanel extends StatelessWidget {
  const _ReadingGuidancePanel({required this.guidance});

  final String guidance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '阅读引导',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          guidance.trim().isEmpty ? '暂无阅读引导。' : guidance.trim(),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: guidance.trim().isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ],
    );
  }
}

class _CharacterInsightItem {
  const _CharacterInsightItem({
    required this.canonicalName,
    required this.aliases,
    required this.role,
    required this.status,
    required this.traits,
    required this.actions,
    required this.firstChapter,
    required this.lastChapter,
    required this.evidence,
    required this.isRegistered,
    required this.confirmationCard,
  });

  final String canonicalName;
  final List<String> aliases;
  final String? role;
  final String? status;
  final List<String> traits;
  final List<String> actions;
  final int firstChapter;
  final int lastChapter;
  final List<String> evidence;
  final bool isRegistered;
  final BookCharacterCard? confirmationCard;

  factory _CharacterInsightItem.fromRegistry(
    CharacterRegistryEntry entry, {
    CharacterCard? analysis,
    BookCharacterCard? legacy,
  }) {
    final aliases =
        {
            ...entry.aliases,
            ...entry.userOverrides,
            ...?analysis?.aliases,
          }.where((alias) => alias.trim().isNotEmpty).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final firstChapter =
        entry.firstAppearanceChapter ??
        analysis?.firstChapter ??
        legacy?.firstSeenChapter ??
        0;
    return _CharacterInsightItem(
      canonicalName: entry.canonicalName,
      aliases: aliases,
      role: analysis?.role,
      status: analysis?.status,
      traits: analysis?.traits ?? const [],
      actions: _characterActions(analysis: analysis, legacy: legacy),
      firstChapter: firstChapter,
      lastChapter:
          analysis?.lastChapter ?? legacy?.firstSeenChapter ?? firstChapter,
      evidence: _characterEvidence(analysis: analysis, legacy: legacy),
      isRegistered: true,
      confirmationCard: null,
    );
  }

  factory _CharacterInsightItem.fromAnalysis(CharacterCard card) {
    return _CharacterInsightItem(
      canonicalName: card.canonicalName,
      aliases: card.aliases.toList()..sort(),
      role: card.role,
      status: card.status,
      traits: card.traits,
      actions: _characterActions(analysis: card),
      firstChapter: card.firstChapter,
      lastChapter: card.lastChapter,
      evidence: _characterEvidence(analysis: card),
      isRegistered: false,
      confirmationCard: _confirmationCardFor(card),
    );
  }

  factory _CharacterInsightItem.fromLegacy(BookCharacterCard card) {
    return _CharacterInsightItem(
      canonicalName: card.canonicalName,
      aliases: const [],
      role: null,
      status: card.currentState,
      traits: const [],
      actions: _characterActions(legacy: card),
      firstChapter: card.firstSeenChapter,
      lastChapter:
          card.firstSeenChapter + math.max(0, card.developments.length - 1),
      evidence: card.evidenceSnippets,
      isRegistered: false,
      confirmationCard: card,
    );
  }
}

class _ChapterInsightGroup {
  const _ChapterInsightGroup({this.summary, List<StoryEvent>? storyEvents})
    : storyEvents = storyEvents ?? const [];

  final AISummary? summary;
  final List<StoryEvent> storyEvents;

  List<_ChapterEventView> get events {
    final items = <_ChapterEventView>[];
    final seen = <String>{};
    for (final event in summary?.events ?? const <SummaryEvent>[]) {
      final key = event.description.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      items.add(_ChapterEventView.fromSummary(event));
    }
    for (final event in storyEvents) {
      final key = event.description.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      items.add(_ChapterEventView.fromStoryEvent(event));
    }
    return items;
  }
}

class _ChapterEventView {
  const _ChapterEventView({
    required this.description,
    this.source,
    this.significance,
    this.participants = const [],
    this.location,
  });

  final String description;
  final String? source;
  final String? significance;
  final List<String> participants;
  final String? location;

  factory _ChapterEventView.fromSummary(SummaryEvent event) {
    return _ChapterEventView(
      description: event.description,
      source: event.source,
      significance: event.significance,
    );
  }

  factory _ChapterEventView.fromStoryEvent(StoryEvent event) {
    return _ChapterEventView(
      description: event.description,
      source: event.anchors.isEmpty ? null : event.anchors.first.quoteSnippet,
      participants: event.participants,
      location: event.location,
    );
  }
}

List<String> _characterActions({
  CharacterCard? analysis,
  BookCharacterCard? legacy,
}) {
  final actions = <String>[];
  if (analysis != null) {
    final prefix = analysis.firstChapter == analysis.lastChapter
        ? 'Ch ${analysis.firstChapter + 1}'
        : 'Ch ${analysis.firstChapter + 1}-${analysis.lastChapter + 1}';
    actions.addAll(
      analysis.actions
          .where((action) => action.trim().isNotEmpty)
          .map((action) => '$prefix: $action'),
    );
  }
  if (legacy != null) {
    for (var i = 0; i < legacy.developments.length; i++) {
      final development = legacy.developments[i];
      if (development.change.trim().isEmpty) continue;
      actions.add(
        'Ch ${legacy.firstSeenChapter + i + 1}: ${development.change}',
      );
    }
  }
  return actions;
}

List<String> _characterEvidence({
  CharacterCard? analysis,
  BookCharacterCard? legacy,
}) {
  return [
    ...?analysis?.anchors.map((anchor) => anchor.quoteSnippet),
    ...?legacy?.evidenceSnippets,
  ].where((snippet) => snippet.trim().isNotEmpty).toList(growable: false);
}

BookCharacterCard _confirmationCardFor(CharacterCard card) {
  final fallbackSource = card.anchors.isNotEmpty
      ? card.anchors.first.quoteSnippet
      : '';
  return BookCharacterCard(
    canonicalName: card.canonicalName,
    firstSeenChapter: card.firstChapter,
    developments: [
      for (final action in card.actions)
        CharacterDevelopment(
          character: card.canonicalName,
          change: action,
          source: fallbackSource,
          confidence: 'medium',
        ),
    ],
    evidenceSnippets: card.anchors
        .map((anchor) => anchor.quoteSnippet)
        .toList(),
  );
}

List<GraphNode> _graphNodes(CharacterRelationGraph graph) {
  if (graph.nodes.isNotEmpty) return graph.nodes;
  final ids = <String>{};
  for (final edge in graph.edges) {
    ids.add(edge.fromCharacterId);
    ids.add(edge.toCharacterId);
  }
  return [
    for (final id in ids) GraphNode(id: id, label: id),
  ];
}

Map<String, Offset> _nodePositions(List<GraphNode> nodes, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  final radiusX = math.max(110.0, size.width / 2 - 90);
  final radiusY = math.max(70.0, size.height / 2 - 58);
  if (nodes.length == 1) return {nodes.single.id: center};
  return {
    for (var i = 0; i < nodes.length; i++)
      nodes[i].id: Offset(
        center.dx +
            math.cos(-math.pi / 2 + (math.pi * 2 * i / nodes.length)) * radiusX,
        center.dy +
            math.sin(-math.pi / 2 + (math.pi * 2 * i / nodes.length)) * radiusY,
      ),
  };
}

GraphNode? _nodeForCharacter(CharacterRelationGraph graph, String? name) {
  if (name == null) return null;
  final lower = name.toLowerCase();
  return _graphNodes(graph)
      .where(
        (node) =>
            node.id.toLowerCase() == lower || node.label.toLowerCase() == lower,
      )
      .firstOrNull;
}

List<GraphEdge> _edgesForSelected(
  CharacterRelationGraph graph,
  GraphNode? node,
  String? selectedName,
) {
  if (node == null && selectedName == null) return const [];
  final lower = selectedName?.toLowerCase();
  return graph.edges
      .where((edge) {
        if (node != null &&
            (edge.fromCharacterId == node.id ||
                edge.toCharacterId == node.id)) {
          return true;
        }
        if (lower == null) return false;
        return edge.fromCharacterId.toLowerCase() == lower ||
            edge.toCharacterId.toLowerCase() == lower;
      })
      .toList(growable: false);
}

String _labelForNode(CharacterRelationGraph graph, String id) {
  return _graphNodes(graph).where((node) => node.id == id).firstOrNull?.label ??
      id;
}

String _avatarLetter(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

List<String> _textLines(String text) {
  return text
      .split(RegExp(r'[\n；;]+'))
      .map((line) => line.trim().replaceFirst(RegExp(r'^[-•]\s*'), ''))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
