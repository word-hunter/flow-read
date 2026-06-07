import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../models/ai_text_analysis.dart';
import '../models/analysis_result.dart';
import '../models/learning_item.dart';
import '../models/sentence_breakdown.dart';
import '../providers/reading/ai_notifier.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../utils/syntax_helpers.dart';

class SelectedTextSheet extends riverpod.ConsumerStatefulWidget {
  final String selectedText;
  final AnalysisResult? analysis; // 兼容旧的分析结果
  final List<SentenceBreakdown>? breakdowns; // 新的逐句分析
  final String analyzerName;
  final bool embedded;
  final VoidCallback? onClose;

  const SelectedTextSheet({
    super.key,
    required this.selectedText,
    required this.analysis,
    this.breakdowns,
    this.analyzerName = '规则引擎',
    this.embedded = false,
    this.onClose,
  });

  @override
  riverpod.ConsumerState<SelectedTextSheet> createState() =>
      _SelectedTextSheetState();
}

class _SelectedTextSheetState
    extends riverpod.ConsumerState<SelectedTextSheet> {
  final ScrollController _embeddedScrollController = ScrollController();
  int? _hoveredStructureIndex;

  @override
  void dispose() {
    _embeddedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.embedded) {
      return Container(
        width: 420,
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
              child: _buildAnalysisTab(theme, _embeddedScrollController),
            ),
          ],
        ),
      );
    }

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
              _buildSheetTitle(theme),
              Expanded(child: _buildAnalysisTab(theme, scrollController)),
            ],
          ),
        );
      },
    );
  }

  // ======== Header ========

  Widget _buildHeader(ThemeData theme) {
    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 10, 0),
        child: Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '结构分析',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: '收起侧栏',
              onPressed: _close,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    }

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
            onPressed: _close,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    Navigator.pop(context);
  }

  // ======== Title ========

  Widget _buildSheetTitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '结构分析',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ======== 分析 Tab ========

  Widget _buildAnalysisTab(ThemeData theme, ScrollController scrollController) {
    final aiState = ref.watch(aiNotifierProvider);
    final aiAnalysis = aiState.aiTextAnalysis;
    final isAnalyzing = aiState.isAnalyzingText;
    final error = aiState.errorMessage;
    final analysisError =
        error != null &&
        (error.startsWith('AI 解析失败') ||
            error == 'AI 服务未初始化' ||
            error.startsWith('请先在设置中配置 '));
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
    addSection(_buildSelectedTextLearningAction(theme));

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

    if (analysis.structureNotes.isNotEmpty) {
      addSection(_buildStructureSection(theme, analysis.structureNotes));
    }

    if (analysis.grammarPoints.isNotEmpty) {
      addSection(_buildGrammarSection(theme, analysis.grammarPoints));
    }

    if (analysis.vocabularyNotes.isNotEmpty) {
      addSection(_buildVocabularySection(theme, analysis.vocabularyNotes));
    }

    if (analysis.expressionNotes.isNotEmpty) {
      addSection(_buildExpressionSection(theme, analysis.expressionNotes));
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

  Widget _buildSelectedTextLearningAction(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: ref.read(vocabularyNotifierProvider.notifier).canCreateLearningItems
            ? () => _saveLearningItem(
                ref.read(vocabularyNotifierProvider.notifier).addSelectedTextLearningItem(),
              )
            : null,
        icon: const Icon(Icons.add_card_outlined, size: 18),
        label: const Text('加入学习卡片'),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
          SizedBox(width: double.infinity, child: child),
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
                    const SizedBox(width: 2),
                    _buildInlineSaveButton(
                      theme,
                      onPressed: () => _saveLearningItem(
                        ref
                            .read(aiNotifierProvider.notifier)
                            .addAIGrammarLearningItem(point),
                      ),
                    ),
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

  Widget _buildStructureSection(
    ThemeData theme,
    List<StructureNote> structureNotes,
  ) {
    final sourceText = _structureDisplayText(structureNotes);
    return _buildAISection(
      theme,
      icon: Icons.schema_outlined,
      title: '结构',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStructureSourceText(theme, sourceText, structureNotes),
          const SizedBox(height: 12),
          ...structureNotes.asMap().entries.map((entry) {
            return _buildStructureExplanationItem(
              theme,
              entry.value,
              entry.key,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStructureSourceText(
    ThemeData theme,
    String sourceText,
    List<StructureNote> structureNotes,
  ) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'Serif',
      height: 1.7,
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: RichText(
        key: const ValueKey('structure-source-text'),
        text: TextSpan(
          style: baseStyle,
          children: _buildStructureSourceSpans(
            theme,
            sourceText,
            structureNotes,
            baseStyle,
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildStructureSourceSpans(
    ThemeData theme,
    String sourceText,
    List<StructureNote> structureNotes,
    TextStyle? baseStyle,
  ) {
    if (sourceText.isEmpty) {
      return const [];
    }

    final ranges = <_StructureTextRange>[];
    for (var index = 0; index < structureNotes.length; index += 1) {
      final range = _findStructureTextRange(
        sourceText,
        structureNotes[index].source,
        index,
      );
      if (range != null) {
        ranges.add(range);
      }
    }

    ranges.sort((a, b) {
      final startComparison = a.start.compareTo(b.start);
      if (startComparison != 0) return startComparison;
      return b.length.compareTo(a.length);
    });

    final visibleRanges = <_StructureTextRange>[];
    var lastEnd = -1;
    for (final range in ranges) {
      if (range.start < lastEnd) continue;
      visibleRanges.add(range);
      lastEnd = range.end;
    }

    if (visibleRanges.isEmpty) {
      return [TextSpan(text: sourceText, style: baseStyle)];
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in visibleRanges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: sourceText.substring(cursor, range.start)));
      }

      final isActive = _hoveredStructureIndex == range.noteIndex;
      final accent = _structureAccentColor(theme, range.noteIndex);
      spans.add(
        TextSpan(
          text: sourceText.substring(range.start, range.end),
          style: baseStyle?.copyWith(
            color: isActive ? accent : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: accent.withValues(alpha: isActive ? 0.95 : 0.72),
            decorationThickness: 1.7,
            backgroundColor: isActive ? accent.withValues(alpha: 0.14) : null,
          ),
        ),
      );
      cursor = range.end;
    }

    if (cursor < sourceText.length) {
      spans.add(TextSpan(text: sourceText.substring(cursor)));
    }

    return spans;
  }

  Widget _buildStructureExplanationItem(
    ThemeData theme,
    StructureNote note,
    int index,
  ) {
    final role = note.role.trim();
    final source = note.source.trim();
    final title = role.isNotEmpty ? role : source;
    final isActive = _hoveredStructureIndex == index;
    final accent = _structureAccentColor(theme, index);

    return MouseRegion(
      key: ValueKey('structure-explanation-$index'),
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHoveredStructureIndex(index),
      onExit: (_) {
        if (_hoveredStructureIndex == index) {
          _setHoveredStructureIndex(null);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setHoveredStructureIndex(isActive ? null : index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? accent.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 3,
                height: 34,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isActive ? 0.9 : 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      note.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _structureDisplayText(List<StructureNote> structureNotes) {
    final selectedText = widget.selectedText.trim();
    final source = selectedText.isNotEmpty
        ? selectedText
        : structureNotes
              .map((note) => note.source.trim())
              .where((text) => text.isNotEmpty)
              .join(' ... ');

    const maxLength = 520;
    if (source.length <= maxLength) {
      return source;
    }

    final ranges = structureNotes
        .map((note) => _findStructureTextRange(source, note.source, 0))
        .whereType<_StructureTextRange>()
        .toList(growable: false);
    if (ranges.isEmpty) {
      return '${source.substring(0, maxLength).trimRight()}...';
    }

    final firstStart = ranges.map((range) => range.start).reduce(math.min);
    final lastEnd = ranges.map((range) => range.end).reduce(math.max);
    var start = math.max(0, firstStart - 90);
    var end = math.min(source.length, lastEnd + 120);

    if (end - start > maxLength) {
      end = math.min(source.length, start + maxLength);
    }

    final prefix = start > 0 ? '...' : '';
    final suffix = end < source.length ? '...' : '';
    return '$prefix${source.substring(start, end).trim()}$suffix';
  }

  _StructureTextRange? _findStructureTextRange(
    String text,
    String source,
    int noteIndex,
  ) {
    final target = source.trim();
    if (target.isEmpty) return null;

    final exactStart = text.indexOf(target);
    if (exactStart >= 0) {
      return _StructureTextRange(
        start: exactStart,
        end: exactStart + target.length,
        noteIndex: noteIndex,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerTarget = target.toLowerCase();
    final caseInsensitiveStart = lowerText.indexOf(lowerTarget);
    if (caseInsensitiveStart >= 0) {
      return _StructureTextRange(
        start: caseInsensitiveStart,
        end: caseInsensitiveStart + target.length,
        noteIndex: noteIndex,
      );
    }

    final words = target
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(RegExp.escape)
        .join(r'\s+');
    if (words.isEmpty) return null;

    final match = RegExp(words, caseSensitive: false).firstMatch(text);
    if (match == null) return null;

    return _StructureTextRange(
      start: match.start,
      end: match.end,
      noteIndex: noteIndex,
    );
  }

  void _setHoveredStructureIndex(int? index) {
    if (_hoveredStructureIndex == index) return;
    setState(() => _hoveredStructureIndex = index);
  }

  Color _structureAccentColor(ThemeData theme, int index) {
    return switch (index % 3) {
      0 => theme.colorScheme.primary,
      1 => theme.colorScheme.tertiary,
      _ => theme.colorScheme.secondary,
    };
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
        children: vocabularyNotes.asMap().entries.map((entry) {
          final index = entry.key;
          final note = entry.value;
          final pos = note.pos.trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: note.word),
                            if (pos.isNotEmpty) ...[
                              const TextSpan(text: '  '),
                              TextSpan(
                                text: pos,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
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
                ),
                const SizedBox(width: 12),
                _buildInlineSaveButton(
                  theme,
                  key: ValueKey('vocabulary-save-$index'),
                  onPressed: () => _saveLearningItem(
                    ref
                        .read(aiNotifierProvider.notifier)
                        .addAIVocabularyLearningItem(note),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpressionSection(
    ThemeData theme,
    List<ExpressionNote> expressionNotes,
  ) {
    return _buildAISection(
      theme,
      icon: Icons.format_quote_outlined,
      title: '表达',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: expressionNotes.map((note) {
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
                        note.source,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _buildInlineSaveButton(
                      theme,
                      onPressed: () => _saveLearningItem(
                        ref
                            .read(aiNotifierProvider.notifier)
                            .addAIExpressionLearningItem(note),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.meaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (note.usage.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.usage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInlineSaveButton(
    ThemeData theme, {
    Key? key,
    required VoidCallback onPressed,
  }) {
    final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
    return Tooltip(
      message: '加入学习卡片',
      child: IconButton(
        key: key,
        onPressed: vocabularyNotifier.canCreateLearningItems ? onPressed : null,
        icon: const Icon(Icons.add_card_outlined, size: 18),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        color: theme.colorScheme.primary,
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

  Future<void> _saveLearningItem(
    Future<LearningItemSaveResult?> saveFuture,
  ) async {
    final result = await saveFuture;
    if (!mounted) return;
    final message = result == null
        ? '无法加入学习卡片'
        : result.created
        ? '已加入学习卡片'
        : '学习卡片已存在';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

class _StructureTextRange {
  const _StructureTextRange({
    required this.start,
    required this.end,
    required this.noteIndex,
  });

  final int start;
  final int end;
  final int noteIndex;

  int get length => end - start;
}
