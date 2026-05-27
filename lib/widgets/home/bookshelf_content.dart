import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/book_metadata.dart';
import '../../providers/reading_provider.dart';
import '../../services/epub_import_source.dart';
import '../../services/settings_service.dart';
import 'featured_book_card.dart';
import 'book_shelf_row.dart';
import 'today_review_card.dart';

enum _BookSortMode { recent, title, author, progress, difficulty }

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
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);
    final allBooks = provider.allBooks;
    _queueDifficultyRatings(provider, allBooks);

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
      provider,
    );

    if (allBooks.isEmpty) {
      return _buildEmptyState(context, provider, theme);
    }

    final featuredCandidates = [...filteredBooks]..sort(_compareByRecent);
    final featuredBook = featuredCandidates.isEmpty
        ? null
        : featuredCandidates.first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, provider),
          if (provider.isLoadingBookDifficulties) ...[
            const SizedBox(height: 14),
            _buildDifficultyLoadingBanner(theme, provider),
          ],
          if (settings.reviewFeatureEnabled &&
              provider.learningItemCount > 0) ...[
            const SizedBox(height: 14),
            TodayReviewCard(
              dueCount: provider.todayReviewDueCount,
              totalLearningItems: provider.learningItemCount,
              onStart: () => Navigator.pushNamed(context, '/spaced_review'),
            ),
          ],
          const SizedBox(height: 28),
          if (featuredBook != null) ...[
            _buildSectionHeader(theme, title: '继续阅读'),
            const SizedBox(height: 12),
            FeaturedBookCard(
              title: featuredBook.title,
              author: featuredBook.author,
              coverBytes: provider.getCoverBytes(featuredBook.id),
              progressPercent: (featuredBook.globalProgress * 100).toInt(),
              currentChapter: featuredBook.currentChapter,
              totalChapters: featuredBook.totalChapters,
              readingTimeSeconds: provider.readingTimeSecondsForBook(
                featuredBook.id,
              ),
              dailyReadingGoalSeconds: settings.dailyReadingGoalSeconds,
              noteCount: provider.noteCountForBook(featuredBook.id),
              latestExcerpt: provider.latestReadingExcerptForBook(
                featuredBook.id,
              ),
              difficulty: provider.difficultyForBook(featuredBook.id),
              isDifficultyLoading: provider.isBookDifficultyLoading(
                featuredBook.id,
              ),
              lastReadAt: featuredBook.lastReadAt,
              onContinueReading: () => _openBook(provider, featuredBook.id),
              onRename: () => _renameBook(provider, featuredBook),
              onRemove: () => _confirmRemoveBook(provider, featuredBook),
            ),
            const SizedBox(height: 34),
          ],
          _buildSectionHeader(
            theme,
            title: '全部书籍',
            trailing:
                '${filteredBooks.length} 本'
                '${provider.isLoadingBookDifficulties ? ' · 计算中' : ''}',
          ),
          const SizedBox(height: 12),
          BookShelfRow(
            books: filteredBooks
                .map(
                  (b) => BookShelfData(
                    title: b.title,
                    author: b.author,
                    coverBytes: provider.getCoverBytes(b.id),
                    progressPercent: (b.globalProgress * 100).toInt(),
                    difficulty: provider.difficultyForBook(b.id),
                    isDifficultyLoading: provider.isBookDifficultyLoading(b.id),
                    onTap: () => _openBook(provider, b.id),
                    onRename: () => _renameBook(provider, b),
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

  void _queueDifficultyRatings(
    ReadingProvider provider,
    List<BookMetadata> books,
  ) {
    if (books.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ReadingProvider>().ensureBookDifficulties(books));
    });
  }

  List<BookMetadata> _sortedBooks(
    List<BookMetadata> books,
    ReadingProvider provider,
  ) {
    final sorted = [...books];
    int byTitle(BookMetadata a, BookMetadata b) {
      final result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return result == 0 ? _compareByRecent(a, b) : result;
    }

    int byAuthor(BookMetadata a, BookMetadata b) {
      final result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
      return result == 0 ? byTitle(a, b) : result;
    }

    int byProgress(BookMetadata a, BookMetadata b) {
      final result = b.globalProgress.compareTo(a.globalProgress);
      return result == 0 ? _compareByRecent(a, b) : result;
    }

    int byDifficulty(BookMetadata a, BookMetadata b) {
      final aRating = provider.difficultyForBook(a.id);
      final bRating = provider.difficultyForBook(b.id);
      if (aRating == null && bRating == null) return _compareByRecent(a, b);
      if (aRating == null) return 1;
      if (bRating == null) return -1;

      final levelResult = aRating.level.index.compareTo(bRating.level.index);
      if (levelResult != 0) return levelResult;

      final scoreResult = aRating.score.compareTo(bRating.score);
      return scoreResult == 0 ? _compareByRecent(a, b) : scoreResult;
    }

    sorted.sort(switch (_sortMode) {
      _BookSortMode.recent => _compareByRecent,
      _BookSortMode.title => byTitle,
      _BookSortMode.author => byAuthor,
      _BookSortMode.progress => byProgress,
      _BookSortMode.difficulty => byDifficulty,
    });
    return sorted;
  }

  int _compareByRecent(BookMetadata a, BookMetadata b) {
    final aTime = a.lastReadAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.lastReadAt?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  }

  Widget _buildHeader(ThemeData theme, ReadingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sortMenu = _buildSortMenu(theme, provider);
          final addButton = FilledButton.icon(
            onPressed: provider.isLoading ? null : () => _importEpub(provider),
            icon: const Icon(Icons.add, size: 18),
            label: Text(provider.isLoading ? '导入中' : '添加书籍'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
          final title = Text(
            '我的书架',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          );

          if (constraints.maxWidth < 860) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSearchField(theme)),
                    const SizedBox(width: 12),
                    sortMenu,
                    const SizedBox(width: 12),
                    addButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              title,
              const Spacer(),
              _buildSearchField(theme, width: 320),
              const SizedBox(width: 12),
              sortMenu,
              const SizedBox(width: 12),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDifficultyLoadingBanner(
    ThemeData theme,
    ReadingProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '正在异步计算 ${provider.loadingBookDifficultyCount} 本书的难易度，完成后会显示评级和生词量依据。',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, {double? width}) {
    final field = SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索书籍或作者',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );

    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortMenu(ThemeData theme, ReadingProvider provider) {
    return PopupMenuButton<_BookSortMode>(
      tooltip: '排序',
      initialValue: _sortMode,
      onSelected: (value) => _onSortSelected(provider, value),
      itemBuilder: (context) => [
        _sortMenuItem(_BookSortMode.recent, '最近阅读', Icons.schedule),
        _sortMenuItem(_BookSortMode.title, '书名 A-Z', Icons.sort_by_alpha),
        _sortMenuItem(_BookSortMode.author, '作者 A-Z', Icons.person_outline),
        _sortMenuItem(_BookSortMode.progress, '阅读进度', Icons.trending_up),
        _sortMenuItem(_BookSortMode.difficulty, '难易度', Icons.speed_outlined),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
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

  void _onSortSelected(ReadingProvider provider, _BookSortMode value) {
    setState(() => _sortMode = value);
    if (value == _BookSortMode.difficulty) {
      unawaited(provider.ensureBookDifficulties(provider.allBooks));
    }
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
      _BookSortMode.difficulty => '难易度',
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
    final opened = await provider.switchToBook(bookId);
    if (!mounted) return;
    if (!opened) {
      final message = provider.errorMessage ?? '打开书籍失败';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    provider.enterReader();
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

  Future<void> _renameBook(ReadingProvider provider, BookMetadata book) async {
    final controller = TextEditingController(text: book.title);
    final renamedTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重命名书籍'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '书名'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final trimmed = renamedTitle?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == book.title) return;
    await provider.renameBook(book.id, trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已重命名为《$trimmed》')));
  }

  Future<void> _importEpub(ReadingProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withReadStream: true,
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;

    final source = EpubImportSource.tryFromPlatformFile(file);
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法读取 EPUB 文件')));
      return;
    }

    await provider.importBookFromSource(source);
  }
}
