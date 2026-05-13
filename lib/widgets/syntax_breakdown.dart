import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../utils/syntax_helpers.dart';

class SyntaxBreakdown extends StatefulWidget {
  final SyntaxPattern pattern;

  const SyntaxBreakdown({super.key, required this.pattern});

  @override
  State<SyntaxBreakdown> createState() => _SyntaxBreakdownState();
}

class _SyntaxBreakdownState extends State<SyntaxBreakdown> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = _parseSentence(widget.pattern.originalSentence);
    final typeLabel = SyntaxHelpers.typeLabel(widget.pattern.type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 10),
              Text(
                typeLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOriginalSentenceCard(theme),
          const SizedBox(height: 16),
          Text(
            '结构解析',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...parts.map((part) => _buildParseNode(part, theme, 0)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _showTranslation = !_showTranslation),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _showTranslation
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '直译',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.translate,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showTranslation) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.pattern.simplifiedSentence,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.pattern.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalSentenceCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '原句',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.pattern.originalSentence,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              fontFamily: 'Serif',
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParseNode(_ClausePart part, ThemeData theme, int depth) {
    final isMainClause = part.isMain;
    final color = isMainClause
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    final bgColor = isMainClause
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
        : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2);

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (depth > 0) ...[
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            SizedBox(
              width: 24,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          part.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    part.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isMainClause
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
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

  List<_ClausePart> _parseSentence(String sentence) {
    final parts = <_ClausePart>[];
    final lower = sentence.toLowerCase();
    final words = sentence.split(RegExp(r'\s+'));

    final markers = [
      'which',
      'who',
      'whom',
      'whose',
      'that',
      'because',
      'since',
      'although',
      'though',
      'unless',
      'until',
      'while',
      'whereas',
      'wherever',
      'whenever',
      'where',
      'when',
      'if',
    ];

    int? splitIndex;
    String? foundMarker;

    for (final marker in markers) {
      final pattern = RegExp(r'\b' + marker + r'\b');
      final match = pattern.firstMatch(lower);
      if (match != null) {
        splitIndex = match.start;
        foundMarker = marker;
        break;
      }
    }

    if (splitIndex != null && foundMarker != null) {
      final before = sentence.substring(0, splitIndex).trim();
      final markerPart = sentence.substring(
        splitIndex,
        splitIndex + foundMarker.length,
      );
      final after = sentence.substring(splitIndex + foundMarker.length).trim();
      final subClause = '$markerPart $after';

      if (before.isNotEmpty) {
        parts.add(
          _ClausePart(text: before, label: '主句 (Main Clause)', isMain: true),
        );
      }
      parts.add(
        _ClausePart(text: subClause, label: '从句 ($foundMarker)', isMain: false),
      );
    } else if (words.length > 25) {
      final mid = words.length ~/ 2;
      final firstHalf = words.sublist(0, mid).join(' ');
      final secondHalf = words.sublist(mid).join(' ');

      parts.add(_ClausePart(text: firstHalf, label: '前半部分', isMain: true));
      parts.add(_ClausePart(text: secondHalf, label: '后半部分', isMain: false));
    } else {
      parts.add(
        _ClausePart(text: sentence, label: '主句 (Main Clause)', isMain: true),
      );
    }

    return parts;
  }
}

class _ClausePart {
  final String text;
  final String label;
  final bool isMain;

  const _ClausePart({
    required this.text,
    required this.label,
    required this.isMain,
  });
}
