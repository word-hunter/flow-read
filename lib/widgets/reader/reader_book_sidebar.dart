import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reading_provider.dart';
import '../../services/settings_service.dart';
import '../theme_transition.dart';
import '../toc_bottom_sheet.dart';

class ReaderBookSidebar extends StatelessWidget {
  const ReaderBookSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    final bookTitle = provider.book?.title ?? '';
    final bookAuthor = provider.book?.chapters.isNotEmpty == true ? '' : '';
    final meta = provider.allBooks
        .where((b) => b.id == provider.activeBookId)
        .firstOrNull;
    final coverBytes = meta != null ? provider.getCoverBytes(meta.id) : null;
    final progressPercent = (provider.readingProgress * 100).toInt();
    final locationNum = provider.currentChapter + 1;
    final totalLocations = provider.chapterCount;
    final bookmarkCount = provider.readingBookmarks.length;
    final highlightCount = provider.bookmarkedWords.length;

    return Container(
      width: 240,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildCover(theme, coverBytes),
          const SizedBox(height: 12),
          _buildBookInfo(
            theme,
            meta?.title ?? bookTitle,
            meta?.author ?? bookAuthor,
          ),
          const SizedBox(height: 20),
          _buildProgress(theme, progressPercent),
          if (totalLocations > 0) ...[
            const SizedBox(height: 4),
            Text(
              '位置 $locationNum / $totalLocations',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildTocButton(context, theme, provider),
          const SizedBox(height: 16),
          _buildInfoItem(theme, Icons.bookmark_outline, '书签', bookmarkCount),
          _buildInfoItem(theme, Icons.description_outlined, '笔记', 0),
          _buildInfoItem(theme, Icons.edit_outlined, '划线', highlightCount),
          const Spacer(),
          _buildBottomActions(context, theme, settings),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCover(ThemeData theme, Uint8List? coverBytes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AspectRatio(
        aspectRatio: 0.65,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: coverBytes != null
                ? Image.memory(
                    coverBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildPlaceholderCover(theme),
                  )
                : _buildPlaceholderCover(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildBookInfo(ThemeData theme, String title, String author) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgress(ThemeData theme, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
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
              const Spacer(),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTocButton(
    BuildContext context,
    ThemeData theme,
    ReadingProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: provider.chapterCount > 1 ? () => _showToc(context) : null,
        icon: const Icon(Icons.list, size: 18),
        label: const Text('目录'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    IconData icon,
    String label,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    ThemeData theme,
    SettingsService settings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.light_mode_outlined, size: 20),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () {},
            tooltip: '亮度',
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () =>
                runThemeTransition(context, settings.toggleThemeMode),
            tooltip: '切换主题',
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () {},
            tooltip: '更多',
          ),
        ],
      ),
    );
  }

  void _showToc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TocBottomSheet(),
    );
  }
}
