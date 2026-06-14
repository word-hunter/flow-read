import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import 'package:flow_design_system/flow_design_system.dart';
import '../utils/syntax_helpers.dart';
import 'flow/flow_components.dart';

class PracticeCard extends StatefulWidget {
  const PracticeCard({
    super.key,
    required this.practice,
    required this.index,
    required this.total,
  });

  final Practice practice;
  final int index;
  final int total;

  @override
  State<PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<PracticeCard> {
  final TextEditingController _controller = TextEditingController();
  bool _showAnswer = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = switch (widget.practice.type) {
      'inference' => FunctionalColors.practiceInference,
      'vocabulary_in_context' => FunctionalColors.practiceVocab,
      'sentence_structure' => FunctionalColors.practiceSentence,
      'paraphrasing' => FunctionalColors.practiceParaphrasing,
      _ => FunctionalColors.practiceDefault,
    };
    final hasDraft = _controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    SyntaxHelpers.practiceTypeIcon(widget.practice.type),
                    size: 22,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '练习 ${widget.index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SyntaxHelpers.practiceTypeLabel(widget.practice.type),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.index + 1}/${widget.total}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              widget.practice.question,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (widget.practice.sourceExcerpt.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SourceExcerptBox(
                label: _sourceLabel(widget.practice.type),
                text: widget.practice.sourceExcerpt,
                accentColor: typeColor,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '先根据原文写下你的判断，再查看参考思路。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            FlowTextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _draftHint(widget.practice.type),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.34,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: typeColor, width: 1.4),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  hasDraft
                      ? '已输入 ${_controller.text.trim().length} 个字符'
                      : '未填写答案也可以先查看参考思路',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlowButton.text(
                      onPressed: hasDraft
                          ? () {
                              _controller.clear();
                              setState(() {});
                            }
                          : null,
                      icon: const Icon(Icons.restart_alt, size: 18),
                      child: const Text('清空'),
                    ),
                    const SizedBox(width: 8),
                    FlowButton.tonal(
                      onPressed: () {
                        setState(() => _showAnswer = !_showAnswer);
                      },
                      icon: Icon(
                        _showAnswer ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      child: Text(_showAnswer ? '收起参考思路' : '查看参考思路'),
                    ),
                  ],
                ),
              ],
            ),
            if (_showAnswer) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '参考思路',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.practice.expectedReasoning,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sourceLabel(String type) {
    switch (type) {
      case 'sentence_structure':
        return '目标句子';
      case 'inference':
        return '阅读片段';
      case 'paraphrasing':
        return '改写原句';
      default:
        return '原文线索';
    }
  }

  String _draftHint(String type) {
    switch (type) {
      case 'sentence_structure':
        return '先拆分句子结构，再写下你的判断。';
      case 'paraphrasing':
        return '尝试用更简单的表达改写这句话。';
      case 'inference':
        return '用自己的话概括主旨或推断含义。';
      default:
        return '写下你根据上下文得到的词义、词性或理解。';
    }
  }
}

class _SourceExcerptBox extends StatelessWidget {
  const _SourceExcerptBox({
    required this.label,
    required this.text,
    required this.accentColor,
  });

  final String label;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.26,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
