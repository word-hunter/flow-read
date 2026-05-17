import 'dart:typed_data';

import 'package:flutter/material.dart';

class BookCoverView extends StatelessWidget {
  static const double borderRadius = 8;
  static const double shelfWidth = 128;
  static const double shelfHeight = 184;
  static const double featuredWidth = 140;
  static const double featuredHeight = 200;
  static const Size shelfSize = Size(shelfWidth, shelfHeight);
  static const Size featuredSize = Size(featuredWidth, featuredHeight);

  final Uint8List? coverBytes;
  final int progressPercent;
  final double width;
  final double height;
  final bool showProgressBadge;

  const BookCoverView({
    super.key,
    required this.coverBytes,
    required this.progressPercent,
    this.width = shelfWidth,
    this.height = shelfHeight,
    this.showProgressBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: coverBytes != null
                  ? Image.memory(
                      coverBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholder(theme),
                    )
                  : _buildPlaceholder(theme),
            ),
          ),
          if (showProgressBadge)
            Positioned(
              left: 8,
              bottom: 8,
              child: _ProgressBadge(progressPercent: progressPercent),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: width >= 140 ? 42 : 34,
          color: theme.colorScheme.primary.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int progressPercent;

  const _ProgressBadge({required this.progressPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          '$progressPercent%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
