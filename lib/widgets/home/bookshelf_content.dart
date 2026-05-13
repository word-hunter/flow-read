import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/reading_provider.dart';
import 'featured_book_card.dart';
import 'book_shelf_row.dart';

class BookshelfContent extends StatefulWidget {
  const BookshelfContent({super.key});

  @override
  State<BookshelfContent> createState() => _BookshelfContentState();
}

class _BookshelfContentState extends State<BookshelfContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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

    final filteredBooks = _searchQuery.isEmpty
        ? allBooks
        : allBooks
              .where(
                (b) =>
                    b.title.toLowerCase().contains(_searchQuery) ||
                    b.author.toLowerCase().contains(_searchQuery),
              )
              .toList();

    if (allBooks.isEmpty) {
      return _buildEmptyState(context, provider, theme);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
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
            ),
          ],
          const SizedBox(height: 32),
          _buildSectionHeader(theme, '最近阅读'),
          const SizedBox(height: 12),
          BookShelfRow(
            books: filteredBooks
                .map(
                  (b) => BookShelfData(
                    title: b.title,
                    coverBytes: provider.getCoverBytes(b.id),
                    progressPercent: (b.globalProgress * 100).toInt(),
                    onTap: () => _openBook(provider, b.id),
                  ),
                )
                .toList(),
            onAddBook: () => _importEpub(provider),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(theme, '想读书籍'),
          const SizedBox(height: 12),
          BookShelfRow(
            books: const [],
            onAddBook: () => _importEpub(provider),
            emptyText: '暂无想读书籍',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
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
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.grid_view, size: 18),
            label: const Text('分类'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('查看全部 >')),
        ],
      ),
    );
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
