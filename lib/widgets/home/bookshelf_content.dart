import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/book_metadata.dart';
import '../../providers/reading_provider.dart';
import 'featured_book_card.dart';
import 'book_shelf_row.dart';

enum _BookSortMode { recent, title, author, progress }

class BookshelfContent extends StatefulWidget {
  const BookshelfContent({super.key});

  @override
  State<BookshelfContent> createState() => _BookshelfContentState();
}

class _BookshelfContentState extends State<BookshelfContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _BookSortMode _sortMode = _BookSortMode.recent;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final allBooks = provider.allBooks;

    final filteredBooks = _sortedBooks(
      _searchQuery.isEmpty
          ? allBooks
          : allBooks
                .where(
                  (b) =>
                      b.title.toLowerCase().contains(_searchQuery) ||
                      b.author.toLowerCase().contains(_searchQuery),
                )
                .toList(),
    );

    if (allBooks.isEmpty) {
      return _buildEmptyState(context, provider, theme);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, provider),
          const SizedBox(height: 24),
          if (filteredBooks.isNotEmpty) ...[
            FeaturedBookCard(
              title: filteredBooks.first.title,
              author: filteredBooks.first.author,
              coverBytes: provider.getCoverBytes(filteredBooks.first.id),
              progressPercent: (filteredBooks.first.globalProgress * 100)
                  .toInt(),
              lastReadAt: filteredBooks.first.lastReadAt,
              onContinueReading: () =>
                  _openBook(provider, filteredBooks.first.id),
              onRemove: () => _confirmRemoveBook(provider, filteredBooks.first),
            ),
          ],
          const SizedBox(height: 32),
          BookShelfRow(
            books: filteredBooks
                .map(
                  (b) => BookShelfData(
                    title: b.title,
                    coverBytes: provider.getCoverBytes(b.id),
                    progressPercent: (b.globalProgress * 100).toInt(),
                    onTap: () => _openBook(provider, b.id),
                    onRemove: () => _confirmRemoveBook(provider, b),
                  ),
                )
                .toList(),
            emptyText: _searchQuery.isEmpty ? '暂无书籍' : '没有匹配的书籍',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<BookMetadata> _sortedBooks(List<BookMetadata> books) {
    final sorted = [...books];
    int byRecent(BookMetadata a, BookMetadata b) {
      final aTime = a.lastReadAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastReadAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    }

    int byTitle(BookMetadata a, BookMetadata b) {
      final result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return result == 0 ? byRecent(a, b) : result;
    }

    int byAuthor(BookMetadata a, BookMetadata b) {
      final result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
      return result == 0 ? byTitle(a, b) : result;
    }

    int byProgress(BookMetadata a, BookMetadata b) {
      final result = b.globalProgress.compareTo(a.globalProgress);
      return result == 0 ? byRecent(a, b) : result;
    }

    sorted.sort(switch (_sortMode) {
      _BookSortMode.recent => byRecent,
      _BookSortMode.title => byTitle,
      _BookSortMode.author => byAuthor,
      _BookSortMode.progress => byProgress,
    });
    return sorted;
  }

  Widget _buildHeader(ThemeData theme, ReadingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Text(
            '我的书架',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索书籍或作者',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          _buildSortMenu(theme),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: provider.isLoading ? null : () => _importEpub(provider),
            icon: const Icon(Icons.add, size: 18),
            label: Text(provider.isLoading ? '导入中' : '添加书籍'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenu(ThemeData theme) {
    return PopupMenuButton<_BookSortMode>(
      tooltip: '排序',
      initialValue: _sortMode,
      onSelected: (value) => setState(() => _sortMode = value),
      itemBuilder: (context) => [
        _sortMenuItem(_BookSortMode.recent, '最近阅读', Icons.schedule),
        _sortMenuItem(_BookSortMode.title, '书名 A-Z', Icons.sort_by_alpha),
        _sortMenuItem(_BookSortMode.author, '作者 A-Z', Icons.person_outline),
        _sortMenuItem(_BookSortMode.progress, '阅读进度', Icons.trending_up),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(_sortLabel(_sortMode), style: theme.textTheme.labelLarge),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_BookSortMode> _sortMenuItem(
    _BookSortMode value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          if (_sortMode == value) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }

  String _sortLabel(_BookSortMode mode) {
    return switch (mode) {
      _BookSortMode.recent => '最近阅读',
      _BookSortMode.title => '书名',
      _BookSortMode.author => '作者',
      _BookSortMode.progress => '进度',
    };
  }

  Widget _buildEmptyState(
    BuildContext context,
    ReadingProvider provider,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'FlowRead',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '导入 EPUB 电子书，开始英文阅读训练',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (provider.isLoading && provider.importStage.isNotEmpty) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 12),
              Text(
                provider.importStage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => _importEpub(provider),
                icon: const Icon(Icons.file_open),
                label: Text(provider.isLoading ? '导入中...' : '导入 EPUB'),
              ),
          ],
        ),
      ),
    );
  }

  void _openBook(ReadingProvider provider, String bookId) async {
    await provider.switchToBook(bookId);
    if (mounted) {
      provider.enterReader();
    }
  }

  Future<void> _confirmRemoveBook(
    ReadingProvider provider,
    BookMetadata book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('移除书籍？'),
          content: Text(
            '将从书架移除《${book.title}》，并清空该书的阅读进度、生词本、阅读书签、AI 缓存以及本地 EPUB/封面文件。此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('移除并清空'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await provider.removeBook(book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已移除《${book.title}》')));
  }

  Future<void> _importEpub(ReadingProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    if (result != null && result.files.single.path != null) {
      await provider.importBook(result.files.single.path!);
    }
  }
}
