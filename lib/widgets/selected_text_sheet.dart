import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_text_analysis.dart';
import '../models/analysis_result.dart';
import '../models/sentence_breakdown.dart';
import '../providers/reading_provider.dart';
import '../utils/syntax_helpers.dart';

enum SelectedTextTab { analysis, translate }

class SelectedTextSheet extends StatefulWidget {
  final String selectedText;
  final AnalysisResult? analysis; // 兼容旧的分析结果
  final List<SentenceBreakdown>? breakdowns; // 新的逐句分析
  final SelectedTextTab tab;
  final String analyzerName;

  const SelectedTextSheet({
    super.key,
    required this.selectedText,
    required this.analysis,
    required this.tab,
    this.breakdowns,
    this.analyzerName = '规则引擎',
  });

  @override
  State<SelectedTextSheet> createState() => _SelectedTextSheetState();
}

class _SelectedTextSheetState extends State<SelectedTextSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tab == SelectedTextTab.analysis ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(theme),
              _buildTabBar(theme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalysisTab(theme, scrollController),
                    _buildTranslateTab(theme, scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======== Header ========

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ======== Tab Bar ========

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: theme.colorScheme.onPrimaryContainer,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge,
        tabs: const [
          Tab(text: '结构分析'),
          Tab(text: '翻译'),
        ],
      ),
    );
  }

  // ======== 分析 Tab ========

  Widget _buildAnalysisTab(ThemeData theme, ScrollController scrollController) {
    final provider = context.watch<ReadingProvider>();
    final aiAnalysis = provider.aiTextAnalysis;
    final isAnalyzing = provider.isAnalyzingText;
    final error = provider.errorMessage;
    final analysisError =
        error != null && (error.startsWith('AI 解析失败') || error == 'AI 服务未初始化');
    final breakdowns = widget.breakdowns;
    final hasBreakdowns = breakdowns != null && breakdowns.isNotEmpty;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedTextCard(theme),
          const SizedBox(height: 16),

          if (isAnalyzing)
            _buildLoadingState(theme, '正在解析...')
          else if (aiAnalysis != null && !aiAnalysis.isEmpty)
            _buildAIAnalysisResult(theme, aiAnalysis)
          else if (analysisError)
            _buildErrorState(theme, error)
          else if (aiAnalysis != null && aiAnalysis.isEmpty)
            _buildEmptyState(
              theme,
              icon: Icons.auto_awesome_outlined,
              title: 'AI 暂无结果',
              subtitle: '模型没有返回可展示的解析内容。',
            )
          else if (hasBreakdowns) ...[
            // 分析器标签
            _buildAnalyzerBadge(theme),
            const SizedBox(height: 12),

            // 逐句卡片
            ...breakdowns.asMap().entries.map((entry) {
              final idx = entry.key;
              final bd = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSentenceCard(bd, idx + 1, theme),
              );
            }),
          ] else if (widget.analysis != null &&
              widget.analysis!.syntaxPatterns.isNotEmpty) ...[
            // fallback: 旧格式
            Text(
              '句型解析',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.analysis!.syntaxPatterns.map(
              (pattern) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildLegacySyntaxCard(pattern, theme),
              ),
            ),
          ] else ...[
            _buildEmptyState(
              theme,
              icon: Icons.check_circle_outline,
              title: '无复杂句型',
              subtitle: '选中的文本句子结构较为简单，无需特殊分析。',
            ),
          ],
        ],
      ),
    );
  }

  // ======== 分析器标签 ========

  Widget _buildAnalyzerBadge(ThemeData theme) {
    final isAI = widget.analyzerName.toLowerCase().contains('ai');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAI
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAI ? Icons.auto_awesome : Icons.rule,
                size: 14,
                color: isAI
                    ? theme.colorScheme.onTertiaryContainer
                    : theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                widget.analyzerName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAI
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIAnalysisResult(ThemeData theme, AITextAnalysis analysis) {
    final sections = <Widget>[];

    void addSection(Widget section) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 12));
      }
      sections.add(section);
    }

    addSection(_buildAnalyzerBadge(theme));

    final translation = analysis.translation.trim();
    if (translation.isNotEmpty) {
      addSection(
        _buildAISection(
          theme,
          icon: Icons.translate,
          title: '译文',
          child: Text(
            translation,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    if (analysis.grammarPoints.isNotEmpty) {
      addSection(_buildGrammarSection(theme, analysis.grammarPoints));
    }

    if (analysis.vocabularyNotes.isNotEmpty) {
      addSection(_buildVocabularySection(theme, analysis.vocabularyNotes));
    }

    final readingTip = analysis.readingTip.trim();
    if (readingTip.isNotEmpty) {
      addSection(
        _buildAISection(
          theme,
          icon: Icons.lightbulb_outline,
          title: '阅读提示',
          child: Text(
            readingTip,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildAISection(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildGrammarSection(
    ThemeData theme,
    List<GrammarPoint> grammarPoints,
  ) {
    return _buildAISection(
      theme,
      icon: Icons.account_tree_outlined,
      title: '语法要点',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grammarPoints.map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        point.source,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Serif',
                          height: 1.5,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyPill(theme, point.difficulty),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  point.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVocabularySection(
    ThemeData theme,
    List<VocabularyNote> vocabularyNotes,
  ) {
    return _buildAISection(
      theme,
      icon: Icons.menu_book_outlined,
      title: '词汇说明',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: vocabularyNotes.map((note) {
          final pos = note.pos.trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        note.word,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (pos.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        pos,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.contextMeaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultyPill(ThemeData theme, String difficulty) {
    final label = switch (difficulty.toLowerCase()) {
      'easy' => '基础',
      'medium' => '中等',
      'hard' => '较难',
      _ => difficulty,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ======== 逐句卡片 ========

  Widget _buildSentenceCard(
    SentenceBreakdown breakdown,
    int index,
    ThemeData theme,
  ) {
    final typeColor = _structureColor(breakdown.structureLabel, theme);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 句子头部 ----
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '句子 $index',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    breakdown.structureLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 原句
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    breakdown.original,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Serif',
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // 从句分解
                if (breakdown.clauses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...breakdown.clauses.map(
                    (clause) => _buildClauseRow(clause, typeColor, theme),
                  ),
                ],

                // 整体说明
                const SizedBox(height: 10),
                Text(
                  breakdown.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======== 从句行 ========

  Widget _buildClauseRow(ClauseInfo clause, Color typeColor, ThemeData theme) {
    final isMain = clause.type == ClauseType.main;
    final barColor = isMain ? typeColor : _clauseTypeColor(clause.type, theme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧色条
          Container(
            width: 3,
            height: 24 + (clause.slots.length * 22.0),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 从句标签 + 文本
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    clause.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Serif',
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // 从句类型标签
                Text(
                  clause.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
                // 成分槽位
                if (clause.slots.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...clause.slots.map((slot) => _buildSlotRow(slot, theme)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======== 成分行 ========

  Widget _buildSlotRow(SlotInfo slot, ThemeData theme) {
    final iconData = _slotIcon(slot.role);
    final color = _slotColor(slot.role, theme);

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            slot.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              slot.text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Serif',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======== 翻译 Tab ========

  Widget _buildTranslateTab(
    ThemeData theme,
    ScrollController scrollController,
  ) {
    final provider = context.watch<ReadingProvider>();
    final translation = provider.aiTranslation;
    final isTranslating = provider.isTranslatingText;
    final error = provider.errorMessage;
    final translationError =
        error != null && (error.startsWith('翻译失败') || error == 'AI 服务未初始化');

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedTextCard(theme),
          const SizedBox(height: 20),
          if (isTranslating)
            _buildLoadingState(theme, '正在翻译...')
          else if (translation != null && translation.isNotEmpty)
            _buildTranslationResult(theme, translation)
          else if (translationError)
            _buildErrorState(theme, error)
          else
            _buildEmptyTranslation(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResult(ThemeData theme, String translation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI 翻译',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            translation,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 28),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTranslation(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.translate,
            size: 36,
            color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '选中文本后点击翻译',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ======== 选中文本卡片 ========

  Widget _buildSelectedTextCard(ThemeData theme) {
    final selectedText = widget.selectedText.trim();
    final hasSelectedText = selectedText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选中的文本',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSelectedText ? widget.selectedText : '未获取到选中文本，请重新选择后再试。',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              fontFamily: 'Serif',
              color: hasSelectedText
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ======== 旧格式兼容卡片 ========

  Widget _buildLegacySyntaxCard(SyntaxPattern pattern, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  SyntaxHelpers.typeIcon(pattern.type),
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                SyntaxHelpers.typeLabel(pattern.type),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pattern.originalSentence,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Serif',
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pattern.explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ======== 空状态 ========

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ======== 颜色辅助 ========

  Color _structureColor(String label, ThemeData theme) {
    switch (label) {
      case '简单句':
        return const Color(0xFF27AE60);
      case '并列句':
        return const Color(0xFF2980B9);
      case '主从复合句':
        return const Color(0xFF8E44AD);
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _clauseTypeColor(ClauseType type, ThemeData theme) {
    switch (type) {
      case ClauseType.relative:
        return const Color(0xFFE67E22);
      case ClauseType.adverbial:
        return const Color(0xFF3498DB);
      case ClauseType.nominal:
        return const Color(0xFF9B59B6);
      case ClauseType.participial:
        return const Color(0xFF1ABC9C);
      case ClauseType.infinitive:
        return const Color(0xFF16A085);
      case ClauseType.coordinate:
        return const Color(0xFF95A5A6);
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _slotIcon(SlotRole role) {
    switch (role) {
      case SlotRole.subject:
        return Icons.person_outline;
      case SlotRole.verb:
        return Icons.play_circle_outline;
      case SlotRole.object:
        return Icons.inbox_outlined;
      case SlotRole.complement:
        return Icons.check_box_outline_blank;
      case SlotRole.adverbial:
        return Icons.map_outlined;
      case SlotRole.modifier:
        return Icons.brush_outlined;
      case SlotRole.connector:
        return Icons.link;
    }
  }

  Color _slotColor(SlotRole role, ThemeData theme) {
    switch (role) {
      case SlotRole.subject:
        return const Color(0xFFE74C3C);
      case SlotRole.verb:
        return const Color(0xFF2980B9);
      case SlotRole.object:
        return const Color(0xFF27AE60);
      case SlotRole.complement:
        return const Color(0xFF8E44AD);
      case SlotRole.adverbial:
        return const Color(0xFF7F8C8D);
      case SlotRole.modifier:
        return const Color(0xFFD35400);
      case SlotRole.connector:
        return const Color(0xFF95A5A6);
    }
  }
}
