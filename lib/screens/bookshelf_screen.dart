import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book_metadata.dart';
import '../providers/reading_provider.dart';
import '../theme/app_constants.dart';

const _logoAsset = 'assets/brand/flow_read_logo.png';

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

class _NarrowBookshelf extends StatelessWidget {
  const _NarrowBookshelf();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final books = provider.allBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的书架',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: books.isNotEmpty
          ? _buildBookList(context, books, provider, theme, isNarrow: true)
          : _buildEmptyState(context, provider, theme),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: provider.isLoading
                  ? null
                  : () => _importEpub(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('导入'),
            )
          : null,
    );
  }
}

class _WideBookshelf extends StatefulWidget {
  const _WideBookshelf();

  @override
  State<_WideBookshelf> createState() => _WideBookshelfState();
}

class _WideBookshelfState extends State<_WideBookshelf> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final books = provider.allBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的书架',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
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
          ? _buildBookList(
              context,
              books,
              provider,
              theme,
              isNarrow: false,
              isGrid: _isGridView,
            )
          : _buildEmptyState(context, provider, theme),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: provider.isLoading
                  ? null
                  : () => _importEpub(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('导入新书'),
            )
          : null,
    );
  }
}

Widget _buildBookList(
  BuildContext context,
  List<BookMetadata> books,
  ReadingProvider provider,
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
          provider,
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
          provider,
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
        provider,
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
  ReadingProvider provider,
) {
  final isCompact = size == _BookCardSize.compact;
  final isMedium = size == _BookCardSize.medium;
  final coverWidth = isCompact ? 120.0 : (isMedium ? double.infinity : 200.0);
  final coverHeight = isCompact ? 160.0 : (isMedium ? 220.0 : 280.0);
  final progressPercent = (meta.globalProgress * 100).toInt();

  final coverWidget = _buildCover(
    context,
    meta,
    theme,
    coverWidth,
    coverHeight,
    isCompact,
  );
  final bookDetails = _buildBookDetails(
    context,
    meta,
    theme,
    progressPercent,
    provider,
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
        onTap: () => _openBook(context, provider, meta.id),
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
      onTap: () => _openBook(context, provider, meta.id),
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
  BuildContext context,
  BookMetadata meta,
  ThemeData theme,
  double width,
  double height,
  bool isCompact,
) {
  final coverBytes = context.read<ReadingProvider>().getCoverBytes(meta.id);

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
  ReadingProvider provider,
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
      FilledButton.icon(
        onPressed: () => _openBook(context, provider, meta.id),
        icon: const Icon(Icons.menu_book, size: 18),
        label: const Text('继续阅读'),
      ),
    ],
  );
}

void _openBook(
  BuildContext context,
  ReadingProvider provider,
  String bookId,
) async {
  await provider.switchToBook(bookId);
  if (context.mounted) {
    provider.enterReader();
  }
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
          if (provider.isLoading && provider.importStage.isNotEmpty) ...[
            Column(
              children: [
                const LinearProgressIndicator(minHeight: 4),
                const SizedBox(height: 12),
                Text(
                  provider.importStage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else
            FilledButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => _importEpub(context, provider),
              icon: provider.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.file_open),
              label: Text(provider.isLoading ? '导入中...' : '导入 EPUB'),
            ),
          if (provider.errorMessage != null) ...[
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
                      provider.errorMessage!,
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
                    onPressed: provider.clearError,
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

Future<void> _importEpub(BuildContext context, ReadingProvider provider) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['epub'],
  );

  if (result != null && result.files.single.path != null) {
    if (context.mounted) {
      await provider.importBook(result.files.single.path!);
    }
  }
}

void _showAbout(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Flow Read'),
      content: const Text(
        'A Reading Training System that transforms novel text into structured '
        'language training — improving vocabulary, sentence comprehension, '
        'and reading inference.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
