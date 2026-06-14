import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../app/flow_read_feature_flags.dart';
import '../models/book_difficulty.dart';
import '../models/book_metadata.dart';
import '../providers/reading/bookshelf_notifier.dart';
import '../providers/settings_provider.dart';
import '../services/app_links.dart';
import '../services/epub_import_source.dart';
import '../services/external_url_launcher.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/home/book_cover_view.dart';
import '../widgets/home/today_review_card.dart';

const _logoAsset = 'assets/brand/flow_read_logo.png';

void _queueDifficultyRatings(
  BuildContext context,
  BookshelfNotifier notifier,
  List<BookMetadata> books,
) {
  if (books.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    unawaited(notifier.ensureBookDifficulties(books));
  });
}

class BookshelfScreen extends StatelessWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.layoutBreakpoint) {
          return const _WideBookshelf();
        }
        return const _NarrowBookshelf();
      },
    );
  }
}

class _NarrowBookshelf extends riverpod.ConsumerWidget {
  const _NarrowBookshelf();

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final bookshelfState = ref.watch(bookshelfNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final books = bookshelfState.books;
    _queueDifficultyRatings(context, bookshelfNotifier, books);

    return Scaffold(
      appBar: FlowToolbar(
        title: const Text(
          '我的书架',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          _LanguageSwitcher(
            settings: settings,
            onChanged: () => bookshelfNotifier.reloadBooks(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: books.isNotEmpty
          ? _buildBookListWithDifficultyStatus(
              context,
              books,
              bookshelfNotifier,
              settings,
              theme,
              isNarrow: true,
            )
          : _buildEmptyState(context, bookshelfState, bookshelfNotifier, theme),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: bookshelfState.isLoading
                  ? null
                  : () => _importEpub(context, bookshelfNotifier),
              icon: const Icon(Icons.add),
              label: const Text('导入'),
            )
          : null,
    );
  }
}

class _WideBookshelf extends riverpod.ConsumerStatefulWidget {
  const _WideBookshelf();

  @override
  riverpod.ConsumerState<_WideBookshelf> createState() => _WideBookshelfState();
}

class _WideBookshelfState extends riverpod.ConsumerState<_WideBookshelf> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final bookshelfState = ref.watch(bookshelfNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final books = bookshelfState.books;
    _queueDifficultyRatings(context, bookshelfNotifier, books);

    return Scaffold(
      appBar: FlowToolbar(
        title: const Text(
          '我的书架',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          _LanguageSwitcher(
            settings: settings,
            onChanged: () => bookshelfNotifier.reloadBooks(),
          ),
          if (books.isNotEmpty)
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              tooltip: _isGridView ? 'List view' : 'Grid view',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: books.isNotEmpty
          ? _buildBookListWithDifficultyStatus(
              context,
              books,
              bookshelfNotifier,
              settings,
              theme,
              isNarrow: false,
              isGrid: _isGridView,
            )
          : _buildEmptyState(context, bookshelfState, bookshelfNotifier, theme),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: bookshelfState.isLoading
                  ? null
                  : () => _importEpub(context, bookshelfNotifier),
              icon: const Icon(Icons.add),
              label: const Text('导入新书'),
            )
          : null,
    );
  }
}

Widget _buildBookListWithDifficultyStatus(
  BuildContext context,
  List<BookMetadata> books,
  BookshelfNotifier notifier,
  SettingsService settings,
  ThemeData theme, {
  required bool isNarrow,
  bool isGrid = false,
}) {
  return Column(
    children: [
      if (notifier.isLoadingBookDifficulties)
        _buildDifficultyLoadingBanner(theme, notifier),
      if (settings.reviewFeatureEnabled && notifier.learningItemCount > 0) ...[
        const SizedBox(height: 12),
        TodayReviewCard(
          dueCount: notifier.todayReviewDueCount,
          totalLearningItems: notifier.learningItemCount,
          onStart: () => Navigator.pushNamed(context, '/spaced_review'),
        ),
      ],
      Expanded(
        child: _buildBookList(
          context,
          books,
          notifier,
          settings,
          theme,
          isNarrow: isNarrow,
          isGrid: isGrid,
        ),
      ),
    ],
  );
}

Widget _buildDifficultyLoadingBanner(
  ThemeData theme,
  BookshelfNotifier notifier,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

Widget _buildBookList(
  BuildContext context,
  List<BookMetadata> books,
  BookshelfNotifier notifier,
  SettingsService settings,
  ThemeData theme, {
  required bool isNarrow,
  bool isGrid = false,
}) {
  if (isNarrow) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: index < books.length - 1 ? 16 : 0),
        child: _buildBookCard(
          context,
          books[index],
          theme,
          _BookCardSize.compact,
          notifier,
          settings,
        ),
      ),
    );
  }

  if (isGrid) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) => _buildBookCard(
          context,
          books[index],
          theme,
          _BookCardSize.medium,
          notifier,
          settings,
        ),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: books.length,
    itemBuilder: (context, index) => Padding(
      padding: EdgeInsets.only(bottom: index < books.length - 1 ? 16 : 0),
      child: _buildBookCard(
        context,
        books[index],
        theme,
        _BookCardSize.large,
        notifier,
        settings,
      ),
    ),
  );
}

enum _BookCardSize { compact, medium, large }

Widget _buildBookCard(
  BuildContext context,
  BookMetadata meta,
  ThemeData theme,
  _BookCardSize size,
  BookshelfNotifier notifier,
  SettingsService settings,
) {
  final isCompact = size == _BookCardSize.compact;
  final isMedium = size == _BookCardSize.medium;
  final coverWidth = isCompact ? 120.0 : (isMedium ? double.infinity : 200.0);
  final coverHeight = isCompact ? 160.0 : (isMedium ? 220.0 : 280.0);
  final progressPercent = (meta.globalProgress * 100).toInt();

  final coverWidget = _buildCover(
    notifier,
    meta,
    theme,
    coverWidth,
    coverHeight,
    isCompact,
    settings,
  );
  final bookDetails = _buildBookDetails(
    context,
    meta,
    theme,
    progressPercent,
    notifier,
  );

  if (isMedium) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _openBook(context, notifier, meta.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [coverWidget, const SizedBox(height: 12), bookDetails],
          ),
        ),
      ),
    );
  }

  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    ),
    child: InkWell(
      onTap: () => _openBook(context, notifier, meta.id),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            coverWidget,
            const SizedBox(width: 24),
            Expanded(child: bookDetails),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCover(
  BookshelfNotifier notifier,
  BookMetadata meta,
  ThemeData theme,
  double width,
  double height,
  bool isCompact,
  SettingsService settings,
) {
  final coverBytes = notifier.getCoverBytes(meta.id);

  if (FlowReadFeatureFlags.v2Enabled) {
    return BookCoverView(
      coverBytes: coverBytes,
      progressPercent: (meta.globalProgress * 100).toInt(),
      title: meta.title,
      author: meta.author,
      width: width,
      height: height,
      forceDefaultCover: settings.forceDefaultBookCover,
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: coverBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              coverBytes,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _buildPlaceholderCover(theme, isCompact),
            ),
          )
        : _buildPlaceholderCover(theme, isCompact),
  );
}

Widget _buildPlaceholderCover(ThemeData theme, bool isCompact) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.6),
          theme.colorScheme.tertiary.withValues(alpha: 0.8),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: Icon(
        Icons.menu_book,
        size: isCompact ? 36 : 48,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
      ),
    ),
  );
}

Widget _buildBookDetails(
  BuildContext context,
  BookMetadata meta,
  ThemeData theme,
  int progressPercent,
  BookshelfNotifier notifier,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        meta.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        meta.author,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (notifier.difficultyForBook(meta.id) != null ||
          notifier.isBookDifficultyLoading(meta.id)) ...[
        const SizedBox(height: 12),
        _BookDifficultySummary(
          rating: notifier.difficultyForBook(meta.id),
          isLoading: notifier.isBookDifficultyLoading(meta.id),
        ),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          Icon(Icons.schedule, size: 16, color: theme.colorScheme.primary),
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
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: progressPercent / 100,
          minHeight: 8,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '$progressPercent%',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      const SizedBox(height: 16),
      FlowButton.primary(
        onPressed: () => _openBook(context, notifier, meta.id),
        icon: const Icon(Icons.menu_book, size: 18),
        child: const Text('继续阅读'),
      ),
    ],
  );
}

class _BookDifficultySummary extends StatelessWidget {
  final BookDifficultyRating? rating;
  final bool isLoading;

  const _BookDifficultySummary({required this.rating, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = rating == null
        ? theme.colorScheme.onSurfaceVariant
        : _difficultyColor(rating!.level);
    final showLoading = isLoading && rating == null;
    final title = showLoading ? '难度计算中' : rating?.levelText ?? '暂无评级';
    final tooltip = showLoading
        ? '正在异步计算难易度\n完成后会根据当前生词量和已掌握词汇给出评级。'
        : rating?.tooltipText ?? '暂无足够内容生成难度说明。';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(BookDifficultyLevel level) {
    switch (level) {
      case BookDifficultyLevel.l1:
        return const Color(0xFF2E7D32);
      case BookDifficultyLevel.l2:
        return const Color(0xFF00897B);
      case BookDifficultyLevel.l3:
        return const Color(0xFFF9A825);
      case BookDifficultyLevel.l4:
        return const Color(0xFFE67E22);
      case BookDifficultyLevel.l5:
        return const Color(0xFFC62828);
    }
  }
}

void _openBook(
  BuildContext context,
  BookshelfNotifier notifier,
  String bookId,
) async {
  await notifier.switchToBook(bookId);
  if (context.mounted) {
    notifier.enterReader();
  }
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
          Image.asset(
            _logoAsset,
            width: 96,
            height: 96,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 24),
          Text(
            'Flow Read',
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
            Column(
              children: [
                const LinearProgressIndicator(minHeight: 4),
                const SizedBox(height: 12),
                Text(
                  state.importStage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else
            FlowButton.primary(
              onPressed: state.isLoading
                  ? null
                  : () => _importEpub(context, notifier),
              icon: state.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.file_open),
              child: Text(state.isLoading ? '导入中...' : '导入 EPUB'),
            ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: notifier.clearError,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<void> _importEpub(
  BuildContext context,
  BookshelfNotifier notifier,
) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['epub'],
    withReadStream: true,
  );

  final file = result?.files.single;
  if (file == null || !context.mounted) return;

  final source = EpubImportSource.tryFromPlatformFile(file);
  if (source == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法读取 EPUB 文件')));
    return;
  }

  await notifier.importBookFromSource(source);
}

void _showAbout(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (ctx) => FlowDialog(
      title: const Text('Flow Read'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A Reading Training System that transforms novel text into '
            'structured language training — improving vocabulary, sentence '
            'comprehension, and reading inference.',
          ),
          const SizedBox(height: 18),
          Text(
            '开发者',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLinks.developerName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'GitHub',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            AppLinks.repositoryUrl.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        FlowButton.text(
          onPressed: () =>
              unawaited(_openAboutLink(context, AppLinks.repositoryUrl)),
          icon: const Icon(Icons.open_in_new),
          child: const Text('GitHub'),
        ),
        FlowButton.text(
          onPressed: () =>
              unawaited(_openAboutLink(context, AppLinks.issueFeedbackUrl)),
          icon: const Icon(Icons.bug_report_outlined),
          child: const Text('反馈问题'),
        ),
        FlowButton.text(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

Future<void> _openAboutLink(BuildContext context, Uri uri) async {
  try {
    await const ExternalUrlLauncher().open(uri);
  } catch (error) {
    if (!context.mounted) return;
    final message = error is ExternalUrlOpenException
        ? error.message
        : '打开链接失败';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.settings,
    this.onChanged,
  });

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
