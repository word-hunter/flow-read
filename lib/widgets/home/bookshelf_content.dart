import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/book_metadata.dart';
import '../../providers/reading/bookshelf_notifier.dart';
import '../../providers/reading/reading_time_notifier.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/settings_provider.dart';
import '../../services/epub_import_source.dart';
import 'book_shelf_row.dart';
import 'featured_book_card.dart';
import 'home_hover_surface.dart';
import 'today_review_card.dart';

enum _BookSortMode { recent, title, author, progress, difficulty }

class BookshelfContent extends riverpod.ConsumerStatefulWidget {
  const BookshelfContent({super.key});

  @override
  riverpod.ConsumerState<BookshelfContent> createState() =>
      _BookshelfContentState();
}

class _BookshelfContentState extends riverpod.ConsumerState<BookshelfContent> {
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
    final bookshelfState = ref.watch(bookshelfNotifierProvider);
    ref.watch(vocabularyNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider.notifier);
    final readingTimeNotifier = ref.read(readingTimeNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final allBooks = bookshelfState.books;
    _queueDifficultyRatings(bookshelfNotifier, allBooks);

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
      bookshelfNotifier,
    );

    if (allBooks.isEmpty) {
      return _buildEmptyState(
        context,
        bookshelfState,
        bookshelfNotifier,
        theme,
      );
    }

    final featuredCandidates = [...filteredBooks]..sort(_compareByRecent);
    final featuredBook = featuredCandidates.isEmpty
        ? null
        : featuredCandidates.first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, bookshelfState, bookshelfNotifier),
          if (bookshelfNotifier.isLoadingBookDifficulties) ...[
            const SizedBox(height: 14),
            _buildDifficultyLoadingBanner(theme, bookshelfNotifier),
          ],
          if (settings.reviewFeatureEnabled &&
              bookshelfNotifier.learningItemCount > 0) ...[
            const SizedBox(height: 14),
            TodayReviewCard(
              dueCount: bookshelfNotifier.todayReviewDueCount,
              totalLearningItems: bookshelfNotifier.learningItemCount,
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
              coverBytes: bookshelfNotifier.getCoverBytes(featuredBook.id),
              progressPercent: (featuredBook.globalProgress * 100).toInt(),
              currentChapter: featuredBook.currentChapter,
              totalChapters: featuredBook.totalChapters,
              readingTimeSeconds: readingTimeNotifier.readingTimeSecondsForBook(
                featuredBook.id,
              ),
              difficulty: bookshelfNotifier.difficultyForBook(featuredBook.id),
              isDifficultyLoading: bookshelfNotifier.isBookDifficultyLoading(
                featuredBook.id,
              ),
              forceDefaultCover: settings.forceDefaultBookCover,
              lastReadAt: featuredBook.lastReadAt,
              onContinueReading: () =>
                  _openBook(bookshelfState, bookshelfNotifier, featuredBook.id),
              onRename: () => _renameBook(bookshelfNotifier, featuredBook),
              onRemove: () =>
                  _confirmRemoveBook(bookshelfNotifier, featuredBook),
            ),
            const SizedBox(height: 34),
          ],
          _buildBookshelfHeader(
            theme,
            bookshelfNotifier,
            bookCount: filteredBooks.length,
            isDifficultyLoading: bookshelfNotifier.isLoadingBookDifficulties,
          ),
          const SizedBox(height: 12),
          BookShelfRow(
            books: filteredBooks
                .map(
                  (b) => BookShelfData(
                    title: b.title,
                    author: b.author,
                    coverBytes: bookshelfNotifier.getCoverBytes(b.id),
                    progressPercent: (b.globalProgress * 100).toInt(),
                    difficulty: bookshelfNotifier.difficultyForBook(b.id),
                    isDifficultyLoading: bookshelfNotifier
                        .isBookDifficultyLoading(b.id),
                    forceDefaultCover: settings.forceDefaultBookCover,
                    onTap: () =>
                        _openBook(bookshelfState, bookshelfNotifier, b.id),
                    onRename: () => _renameBook(bookshelfNotifier, b),
                    onRemove: () => _confirmRemoveBook(bookshelfNotifier, b),
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
    BookshelfNotifier notifier,
    List<BookMetadata> books,
  ) {
    if (books.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(notifier.ensureBookDifficulties(books));
    });
  }

  List<BookMetadata> _sortedBooks(
    List<BookMetadata> books,
    BookshelfNotifier notifier,
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
      final aRating = notifier.difficultyForBook(a.id);
      final bRating = notifier.difficultyForBook(b.id);
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

  Widget _buildHeader(
    ThemeData theme,
    BookshelfState state,
    BookshelfNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final addButton = FilledButton.icon(
            onPressed: state.isLoading ? null : () => _importEpub(notifier),
            icon: const Icon(Icons.add, size: 18),
            label: Text(state.isLoading ? '导入中' : '添加书籍'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              enabledMouseCursor: SystemMouseCursors.click,
            ),
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(theme),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: addButton),
              ],
            );
          }

          final searchWidth = math.min(
            560.0,
            math.max(280.0, constraints.maxWidth - 190),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSearchField(theme, width: searchWidth),
                ),
              ),
              const SizedBox(width: 16),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDifficultyLoadingBanner(
    ThemeData theme,
    BookshelfNotifier notifier,
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
                '正在异步计算 ${notifier.loadingBookDifficultyCount} 本书的难易度，完成后会显示评级和生词量依据。',
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

  Widget _buildBookshelfHeader(
    ThemeData theme,
    BookshelfNotifier notifier, {
    required int bookCount,
    required bool isDifficultyLoading,
  }) {
    final countText = '$bookCount 本${isDifficultyLoading ? ' · 计算中' : ''}';
    final titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '书架',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          countText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final sortMenu = _buildSortMenu(theme, notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleGroup,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: sortMenu),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleGroup),
              const SizedBox(width: 16),
              sortMenu,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortMenu(ThemeData theme, BookshelfNotifier notifier) {
    return PopupMenuButton<_BookSortMode>(
      tooltip: '排序',
      initialValue: _sortMode,
      onSelected: (value) => _onSortSelected(notifier, value),
      itemBuilder: (context) => [
        _sortMenuItem(_BookSortMode.recent, '最近阅读', Icons.schedule),
        _sortMenuItem(_BookSortMode.title, '书名 A-Z', Icons.sort_by_alpha),
        _sortMenuItem(_BookSortMode.author, '作者 A-Z', Icons.person_outline),
        _sortMenuItem(_BookSortMode.progress, '阅读进度', Icons.trending_up),
        _sortMenuItem(_BookSortMode.difficulty, '难易度', Icons.speed_outlined),
      ],
      child: HomeHoverSurface(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Colors.transparent,
        hoverBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderColor: theme.colorScheme.outline,
        hoverBorderColor: theme.colorScheme.primary.withValues(alpha: 0.46),
        hoverBoxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        builder: (context, isHovering) {
          final foreground = isHovering
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _sortLabel(_sortMode),
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: foreground),
            ],
          );
        },
      ),
    );
  }

  void _onSortSelected(BookshelfNotifier notifier, _BookSortMode value) {
    setState(() => _sortMode = value);
    if (value == _BookSortMode.difficulty) {
      unawaited(notifier.ensureBookDifficulties(notifier.allBooks));
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
    BookshelfState state,
    BookshelfNotifier notifier,
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
            if (state.isLoading && state.importStage.isNotEmpty) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 12),
              Text(
                state.importStage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: state.isLoading ? null : () => _importEpub(notifier),
                icon: const Icon(Icons.file_open),
                label: Text(state.isLoading ? '导入中...' : '导入 EPUB'),
              ),
          ],
        ),
      ),
    );
  }

  void _openBook(
    BookshelfState state,
    BookshelfNotifier notifier,
    String bookId,
  ) async {
    final opened = await notifier.switchToBook(bookId);
    if (!mounted) return;
    if (!opened) {
      final message = state.errorMessage ?? '打开书籍失败';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    notifier.enterReader();
  }

  Future<void> _confirmRemoveBook(
    BookshelfNotifier notifier,
    BookMetadata book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final screenWidth = MediaQuery.sizeOf(dialogContext).width;
        final dialogWidth = math.min(
          360.0,
          math.max(280.0, screenWidth - 80),
        );
        return AlertDialog(
          title: const Text('移除书籍？'),
          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('将从书架移除这本书：'),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '并清空该书的阅读进度、生词本、阅读书签、AI 缓存以及本地 EPUB/封面文件。此操作不可撤销。',
                ),
              ],
            ),
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
    await notifier.removeBook(book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已移除《${book.title}》')));
  }

  Future<void> _renameBook(
    BookshelfNotifier notifier,
    BookMetadata book,
  ) async {
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
    await notifier.renameBook(book.id, trimmed);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已重命名为《$trimmed》')));
  }

  Future<void> _importEpub(BookshelfNotifier notifier) async {
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

    await notifier.importBookFromSource(source);
  }
}
