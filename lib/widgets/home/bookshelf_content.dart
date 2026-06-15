import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/book_metadata.dart';
import '../../models/reading_memory.dart';
import '../../providers/reading/bookshelf_notifier.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/settings_provider.dart';
import '../../services/epub_import_source.dart';
import '../../services/settings_service.dart';
import '../../theme/city_theme_tokens.dart';
import '../flow/flow_components.dart';
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
  final Map<String, Future<List<String>>> _featuredExcerptFutures = {};
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
      return Column(
        children: [
          _buildBookshelfHeader(
            theme,
            bookshelfNotifier,
            bookCount: 0,
            isDifficultyLoading: false,
          ),
          Expanded(
            child: _buildEmptyState(
              context,
              bookshelfState,
              bookshelfNotifier,
              theme,
            ),
          ),
        ],
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
            LayoutBuilder(
              builder: (context, constraints) {
                final shouldLoadExcerpts = constraints.maxWidth >= 920;
                if (!shouldLoadExcerpts) {
                  return _buildFeaturedBookCard(
                    state: bookshelfState,
                    notifier: bookshelfNotifier,
                    settings: settings,
                    featuredBook: featuredBook,
                  );
                }

                return FutureBuilder<List<String>>(
                  future: _featuredExcerptFutureFor(
                    featuredBook,
                    bookshelfNotifier,
                  ),
                  builder: (context, snapshot) {
                    return _buildFeaturedBookCard(
                      state: bookshelfState,
                      notifier: bookshelfNotifier,
                      settings: settings,
                      featuredBook: featuredBook,
                      readingExcerpts: snapshot.data ?? const [],
                      isLoadingReadingExcerpts:
                          snapshot.connectionState != ConnectionState.done,
                    );
                  },
                );
              },
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

  Widget _buildFeaturedBookCard({
    required BookshelfState state,
    required BookshelfNotifier notifier,
    required SettingsService settings,
    required BookMetadata featuredBook,
    List<String> readingExcerpts = const [],
    bool isLoadingReadingExcerpts = false,
  }) {
    return FeaturedBookCard(
      title: featuredBook.title,
      author: featuredBook.author,
      coverBytes: notifier.getCoverBytes(featuredBook.id),
      progressPercent: (featuredBook.globalProgress * 100).toInt(),
      currentChapter: featuredBook.currentChapter,
      totalChapters: featuredBook.totalChapters,
      readingExcerpts: readingExcerpts,
      isLoadingReadingExcerpts: isLoadingReadingExcerpts,
      difficulty: notifier.difficultyForBook(featuredBook.id),
      isDifficultyLoading: notifier.isBookDifficultyLoading(featuredBook.id),
      forceDefaultCover: settings.forceDefaultBookCover,
      lastReadAt: featuredBook.lastReadAt,
      onContinueReading: () => _openBook(state, notifier, featuredBook.id),
      onRename: () => _renameBook(notifier, featuredBook),
      onRemove: () => _confirmRemoveBook(notifier, featuredBook),
    );
  }

  Future<List<String>> _featuredExcerptFutureFor(
    BookMetadata book,
    BookshelfNotifier notifier,
  ) {
    final key = [
      book.id,
      book.currentChapter,
      book.totalChapters,
      book.lastReadAt?.millisecondsSinceEpoch ?? 0,
    ].join(':');
    final cached = _featuredExcerptFutures[key];
    if (cached != null) return cached;

    if (_featuredExcerptFutures.length >= 12) {
      _featuredExcerptFutures.remove(_featuredExcerptFutures.keys.first);
    }
    return _featuredExcerptFutures[key] = notifier.previewExcerptsForBook(book);
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
          final addButton = FlowButton.primary(
            onPressed: state.isLoading ? null : () => _importEpub(notifier),
            icon: const Icon(Icons.add, size: 18),
            child: Text(state.isLoading ? '导入中' : '添加书籍'),
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
    final city = Theme.of(context).extension<CityThemeTokens>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              city?.panelSurface ??
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                city?.warmBorder ??
                theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: city?.activeBlue ?? theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '正在异步计算 ${notifier.loadingBookDifficultyCount} 本书的难易度，完成后会显示评级和生词量依据。',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: city?.textPrimary ?? theme.colorScheme.onSurface,
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
    final city = Theme.of(context).extension<CityThemeTokens>();
    final borderColor = city?.warmBorder ?? theme.colorScheme.outlineVariant;
    final field = SizedBox(
      height: 40,
      child: FlowTextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索书籍或作者',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: city?.textSecondary),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: city?.activeBlue ?? theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
          filled: true,
          fillColor: city?.cardSurface ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: city?.textPrimary ?? theme.colorScheme.onSurface,
        ),
      ),
    );

    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }

  Widget _buildBookshelfHeader(
    ThemeData theme,
    BookshelfNotifier notifier, {
    required int bookCount,
    required bool isDifficultyLoading,
  }) {
    final city = Theme.of(context).extension<CityThemeTokens>();
    final settings = ref.read(settingsProvider);
    final countText = '$bookCount 本${isDifficultyLoading ? ' · 计算中' : ''}';
    final titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '书架',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: city?.textPrimary ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          countText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        _BookshelfLanguageSwitcher(
          settings: settings,
          onChanged: () =>
              ref.read(bookshelfNotifierProvider.notifier).reloadBooks(),
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
    final city = Theme.of(context).extension<CityThemeTokens>();
    return FlowMenuButton<_BookSortMode>(
      tooltip: '排序',
      entries: [
        FlowMenuItem(
          value: _BookSortMode.recent,
          label: '最近阅读',
          icon: Icons.schedule,
          selected: _sortMode == _BookSortMode.recent,
        ),
        FlowMenuItem(
          value: _BookSortMode.title,
          label: '书名 A-Z',
          icon: Icons.sort_by_alpha,
          selected: _sortMode == _BookSortMode.title,
        ),
        FlowMenuItem(
          value: _BookSortMode.author,
          label: '作者 A-Z',
          icon: Icons.person_outline,
          selected: _sortMode == _BookSortMode.author,
        ),
        FlowMenuItem(
          value: _BookSortMode.progress,
          label: '阅读进度',
          icon: Icons.trending_up,
          selected: _sortMode == _BookSortMode.progress,
        ),
        FlowMenuItem(
          value: _BookSortMode.difficulty,
          label: '难易度',
          icon: Icons.speed_outlined,
          selected: _sortMode == _BookSortMode.difficulty,
        ),
      ],
      onSelected: (value) => _onSortSelected(notifier, value),
      child: HomeHoverSurface(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: city?.cardSurface ?? Colors.transparent,
        hoverBackgroundColor: (city?.activeBlue ?? theme.colorScheme.primary)
            .withValues(alpha: city == null ? 0.06 : 0.08),
        borderColor: city?.warmBorder ?? theme.colorScheme.outline,
        hoverBorderColor:
            city?.activeBlue ??
            theme.colorScheme.primary.withValues(alpha: 0.46),
        hoverBoxShadow: [
          BoxShadow(
            color: (city?.activeBlue ?? theme.colorScheme.primary).withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        builder: (context, isHovering) {
          final foreground = isHovering
              ? city?.activeBlue ?? theme.colorScheme.primary
              : city?.textPrimary ?? theme.colorScheme.onSurface;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 18,
                color: city?.activeBlue ?? theme.colorScheme.primary,
              ),
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
    final city = Theme.of(context).extension<CityThemeTokens>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 80,
              color: (city?.activeBlue ?? theme.colorScheme.primary).withValues(
                alpha: 0.5,
              ),
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
                color:
                    city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
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
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              FlowButton.primary(
                onPressed: state.isLoading ? null : () => _importEpub(notifier),
                icon: const Icon(Icons.file_open),
                child: Text(state.isLoading ? '导入中...' : '导入 EPUB'),
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
    var selectedPolicy = EvidenceRetentionPolicy.keepSnippet;
    final policy = await showDialog<EvidenceRetentionPolicy>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final screenWidth = MediaQuery.sizeOf(dialogContext).width;
        final dialogWidth = math.min(360.0, math.max(280.0, screenWidth - 80));
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return FlowDialog(
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
                      '阅读进度、阅读书签、AI 缓存以及本地 EPUB/封面文件会被清空。请选择学习记忆的处理方式。',
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<EvidenceRetentionPolicy>(
                      groupValue: selectedPolicy,
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedPolicy = value);
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BookRemovalPolicyTile(
                            value: EvidenceRetentionPolicy.keepSnippet,
                          ),
                          _BookRemovalPolicyTile(
                            value: EvidenceRetentionPolicy.keepMetadataOnly,
                          ),
                          _BookRemovalPolicyTile(
                            value: EvidenceRetentionPolicy.deleteWithSource,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FlowButton.text(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                FlowButton.destructive(
                  onPressed: () => Navigator.pop(dialogContext, selectedPolicy),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  child: Text(_removeBookActionLabel(selectedPolicy)),
                ),
              ],
            );
          },
        );
      },
    );

    if (policy == null) return;
    await notifier.removeBook(book.id, memoryRetentionPolicy: policy);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_removedBookMessage(book, policy))));
  }

  String _removeBookActionLabel(EvidenceRetentionPolicy policy) {
    return switch (policy) {
      EvidenceRetentionPolicy.keepSnippet => '移除书籍',
      EvidenceRetentionPolicy.keepMetadataOnly => '移除并保留元数据',
      EvidenceRetentionPolicy.deleteWithSource => '移除并删除记忆',
    };
  }

  String _removedBookMessage(
    BookMetadata book,
    EvidenceRetentionPolicy policy,
  ) {
    return switch (policy) {
      EvidenceRetentionPolicy.keepSnippet => '已移除《${book.title}》，学习记忆已保留',
      EvidenceRetentionPolicy.keepMetadataOnly => '已移除《${book.title}》，仅保留学习元数据',
      EvidenceRetentionPolicy.deleteWithSource => '已移除《${book.title}》及相关学习记忆',
    };
  }

  Future<void> _renameBook(
    BookshelfNotifier notifier,
    BookMetadata book,
  ) async {
    final controller = TextEditingController(text: book.title);
    final renamedTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return FlowDialog(
          title: const Text('重命名书籍'),
          content: FlowTextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '书名'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            FlowButton.text(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FlowButton.primary(
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

class _BookRemovalPolicyTile extends StatelessWidget {
  const _BookRemovalPolicyTile({
    required this.value,
  });

  final EvidenceRetentionPolicy value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<EvidenceRetentionPolicy>(
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(_title),
      subtitle: Text(_subtitle),
    );
  }

  String get _title {
    return switch (value) {
      EvidenceRetentionPolicy.keepSnippet => '保留学习记忆和短例句',
      EvidenceRetentionPolicy.keepMetadataOnly => '仅保留学习元数据',
      EvidenceRetentionPolicy.deleteWithSource => '删除本书相关学习记忆',
    };
  }

  String get _subtitle {
    return switch (value) {
      EvidenceRetentionPolicy.keepSnippet => '默认选项，单词状态、保存解释和短例句会继续可用。',
      EvidenceRetentionPolicy.keepMetadataOnly => '保留单词状态、事件和来源记录，不再保留原文片段。',
      EvidenceRetentionPolicy.deleteWithSource =>
        '同时删除由这本书产生的证据、事件、缓存和仅来自本书的记忆。',
    };
  }
}

class _BookshelfLanguageSwitcher extends StatelessWidget {
  const _BookshelfLanguageSwitcher({required this.settings, this.onChanged});

  final SettingsService settings;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final modules = LanguageRegistry.instance.modules;
    if (modules.length <= 1) return const SizedBox.shrink();

    final active = settings.activeSourceLanguage;
    final activeModule = modules.firstWhere(
      (m) => m.languageCode == active,
      orElse: () => modules.first,
    );

    return FlowMenuButton<String>(
      tooltip: '切换书架语言',
      entries: [
        for (final module in modules)
          FlowMenuItem<String>(
            value: module.languageCode,
            label: module.languageName,
            icon: Icons.translate_outlined,
            selected: module.languageCode == active,
          ),
      ],
      onSelected: (code) {
        settings.setActiveSourceLanguage(code);
        onChanged?.call();
      },
      builder: (context, isOpen, toggle) {
        return _LanguageSwitcherTrigger(
          label: activeModule.languageCode.toUpperCase(),
          isOpen: isOpen,
          onTap: toggle,
        );
      },
    );
  }
}

class _LanguageSwitcherTrigger extends StatefulWidget {
  const _LanguageSwitcherTrigger({
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  State<_LanguageSwitcherTrigger> createState() =>
      _LanguageSwitcherTriggerState();
}

class _LanguageSwitcherTriggerState extends State<_LanguageSwitcherTrigger> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = widget.isOpen || _hovering;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
