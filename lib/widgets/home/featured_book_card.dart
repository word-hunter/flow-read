import 'dart:typed_data';
import 'package:flutter/material.dart';

class FeaturedBookCard extends StatelessWidget {
  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final DateTime? lastReadAt;
  final VoidCallback onContinueReading;
  final VoidCallback? onMore;

  const FeaturedBookCard({
    super.key,
    required this.title,
    required this.author,
    this.coverBytes,
    required this.progressPercent,
    this.lastReadAt,
    required this.onContinueReading,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _buildCover(theme),
          const SizedBox(width: 24),
          Expanded(child: _buildDetails(theme)),
        ],
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverBytes != null
            ? Image.memory(
                coverBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(theme),
              )
            : _buildPlaceholder(theme),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 48,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    final lastReadText = lastReadAt != null
        ? '上次阅读: ${lastReadAt!.year}.${lastReadAt!.month.toString().padLeft(2, '0')}.${lastReadAt!.day.toString().padLeft(2, '0')}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          author,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '阅读进度',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$progressPercent%',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (lastReadText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            lastReadText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: onContinueReading,
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('继续阅读'),
            ),
            const SizedBox(width: 8),
            if (onMore != null)
              IconButton.outlined(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz),
              ),
          ],
        ),
      ],
    );
  }
}
