import 'package:flutter/material.dart';

import '../models/book_difficulty.dart';

class BookDifficultyChip extends StatelessWidget {
  final BookDifficultyRating? rating;
  final bool isLoading;
  final bool compact;
  final bool labelOnly;
  final double? maxWidth;

  const BookDifficultyChip({
    super.key,
    required this.rating,
    required this.isLoading,
    this.compact = false,
    this.labelOnly = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = rating == null
        ? BookDifficultyChipPalette.neutral(theme.colorScheme)
        : BookDifficultyChipPalette.forLevel(rating!.level);
    final showLoading = isLoading && rating == null;
    final title = labelOnly
        ? _shortTitleText(showLoading: showLoading)
        : showLoading
        ? '难度计算中'
        : _titleText;
    final tooltip = showLoading
        ? '正在异步计算难易度\n完成后会根据当前生词量和已掌握词汇给出评级。'
        : rating?.tooltipText ?? '暂无足够内容生成难度说明。';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        constraints: BoxConstraints(
          minWidth: labelOnly ? 30 : 0,
          maxWidth:
              maxWidth ??
              (labelOnly
                  ? 44
                  : compact
                  ? 124
                  : 156),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: labelOnly
              ? 6
              : compact
              ? 7
              : 10,
          vertical: labelOnly
              ? 3
              : compact
              ? 4
              : 5,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(
            labelOnly
                ? 7
                : compact
                ? 8
                : 10,
          ),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (labelOnly || compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: labelOnly
                        ? 10
                        : compact
                        ? 10
                        : null,
                  ),
        ),
      ),
    );
  }

  String get _titleText {
    final level = rating?.level;
    if (level == null) return '暂无评级';
    return '${level.shortLabel} · ${level.label}';
  }

  String _shortTitleText({required bool showLoading}) {
    if (showLoading) return '...';
    return rating?.level.shortLabel ?? 'L?';
  }
}

class BookDifficultyChipPalette {
  final Color foreground;
  final Color background;
  final Color border;

  const BookDifficultyChipPalette({
    required this.foreground,
    required this.background,
    required this.border,
  });

  static const l1 = BookDifficultyChipPalette(
    foreground: Color(0xFF2E7D5B),
    background: Color(0xFFEEF8F2),
    border: Color(0xFFCBE8D6),
  );

  static const l2 = BookDifficultyChipPalette(
    foreground: Color(0xFF2F7E86),
    background: Color(0xFFEDF8F8),
    border: Color(0xFFC4E6E8),
  );

  static const l3 = BookDifficultyChipPalette(
    foreground: Color(0xFF9A6A10),
    background: Color(0xFFFFF7E6),
    border: Color(0xFFF1D59B),
  );

  static const l4 = BookDifficultyChipPalette(
    foreground: Color(0xFFB35C18),
    background: Color(0xFFFFF1E8),
    border: Color(0xFFEDBE9B),
  );

  static const l5 = BookDifficultyChipPalette(
    foreground: Color(0xFFB13A3A),
    background: Color(0xFFFFF0F0),
    border: Color(0xFFEAB8B8),
  );

  static BookDifficultyChipPalette forLevel(BookDifficultyLevel level) {
    switch (level) {
      case BookDifficultyLevel.l1:
        return l1;
      case BookDifficultyLevel.l2:
        return l2;
      case BookDifficultyLevel.l3:
        return l3;
      case BookDifficultyLevel.l4:
        return l4;
      case BookDifficultyLevel.l5:
        return l5;
    }
  }

  static BookDifficultyChipPalette neutral(ColorScheme colorScheme) {
    return BookDifficultyChipPalette(
      foreground: colorScheme.onSurfaceVariant,
      background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
      border: colorScheme.outlineVariant.withValues(alpha: 0.78),
    );
  }
}
