import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import '../book_difficulty_chip.dart';

class ReaderLocationSummary extends StatelessWidget {
  final String title;
  final String? metaLabel;
  final BookDifficultyRating? difficulty;
  final Color textColor;

  const ReaderLocationSummary({
    super.key,
    required this.title,
    required this.metaLabel,
    required this.difficulty,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = metaLabel;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            key: const ValueKey('reader-toolbar-title'),
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        if (meta != null) ...[
          const SizedBox(width: 8),
          Text(
            key: const ValueKey('reader-toolbar-meta'),
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
        if (difficulty != null) ...[
          const SizedBox(width: 8),
          BookDifficultyChip(
            rating: difficulty,
            isLoading: false,
            labelOnly: true,
          ),
        ],
      ],
    );
  }
}
