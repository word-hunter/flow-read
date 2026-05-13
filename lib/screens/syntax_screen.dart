import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../providers/reading_provider.dart';
import '../utils/syntax_helpers.dart';
import '../widgets/syntax_breakdown.dart';

class SyntaxScreen extends StatelessWidget {
  const SyntaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ReadingProvider>().result;
    if (result == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '句型分析',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: result.syntaxPatterns.isEmpty
          ? Center(
              child: Text(
                '暂无复杂句型',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: result.syntaxPatterns.length,
              itemBuilder: (context, index) {
                return _SyntaxCardItem(
                  pattern: result.syntaxPatterns[index],
                  index: index,
                );
              },
            ),
    );
  }
}

class _SyntaxCardItem extends StatefulWidget {
  final SyntaxPattern pattern;
  final int index;

  const _SyntaxCardItem({required this.pattern, required this.index});

  @override
  State<_SyntaxCardItem> createState() => _SyntaxCardItemState();
}

class _SyntaxCardItemState extends State<_SyntaxCardItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _expanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      SyntaxHelpers.typeIcon(widget.pattern.type),
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SyntaxHelpers.typeLabel(widget.pattern.type),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pattern.originalSentence,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Serif',
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            SyntaxBreakdown(pattern: widget.pattern),
          ],
        ],
      ),
    );
  }
}
