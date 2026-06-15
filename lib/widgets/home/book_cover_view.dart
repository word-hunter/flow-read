import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'default_book_cover.dart';

class BookCoverView extends StatelessWidget {
  static const double borderRadius = 8;
  static const double shelfWidth = 128;
  static const double shelfHeight = 184;
  static const double featuredWidth = 152;
  static const double featuredHeight = 224;
  static const Size shelfSize = Size(shelfWidth, shelfHeight);
  static const Size featuredSize = Size(featuredWidth, featuredHeight);
  static const double tooltipMaxWidth = 420;

  final Uint8List? coverBytes;
  final int progressPercent;
  final double width;
  final double height;
  final bool showProgressBadge;
  final String title;
  final String author;
  final bool forceDefaultCover;

  const BookCoverView({
    super.key,
    required this.coverBytes,
    required this.progressPercent,
    this.title = '',
    this.author = '',
    this.width = shelfWidth,
    this.height = shelfHeight,
    this.showProgressBadge = true,
    this.forceDefaultCover = false,
  });

  @override
  Widget build(BuildContext context) {
    final forceGeneratedCover = forceDefaultCover;
    final showDefaultProgressBadge =
        showProgressBadge && (coverBytes == null || forceGeneratedCover);
    final tooltipTitle = title.trim().isEmpty ? 'Untitled Book' : title.trim();

    return Tooltip(
      richMessage: WidgetSpan(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: tooltipMaxWidth),
          child: Text(tooltipTitle),
        ),
      ),
      waitDuration: const Duration(milliseconds: 400),
      child: SizedBox(
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
                child: forceGeneratedCover || coverBytes == null
                    ? _buildPlaceholder(
                        context,
                        showDefaultProgressBadge: showDefaultProgressBadge,
                      )
                    : Image.memory(
                        coverBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(
                          context,
                          showDefaultProgressBadge: false,
                        ),
                      ),
              ),
            ),
            if (showProgressBadge && coverBytes != null && !forceGeneratedCover)
              Positioned(
                left: 8,
                bottom: 8,
                child: _ProgressBadge(progressPercent: progressPercent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context, {
    required bool showDefaultProgressBadge,
  }) {
    return DefaultBookCover(
      title: title,
      author: author,
      progressPercent: progressPercent,
      showProgressBadge: showDefaultProgressBadge,
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
