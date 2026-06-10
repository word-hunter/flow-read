import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../providers/reading/current_book_notifier.dart';
import '../../theme/app_surface_tokens.dart';
import 'reader_workspace_controller.dart';
import 'reader_toc_panel.dart';

class ReaderLeftWorkspacePanel extends riverpod.ConsumerWidget {
  final ReaderWorkspaceController workspaceController;
  final ValueChanged<int>? onGoToChapter;

  const ReaderLeftWorkspacePanel({
    super.key,
    required this.workspaceController,
    this.onGoToChapter,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final book = currentBookNotifier.book;
    final currentChapter = currentBookState.currentChapter + 1;
    final chapterCount = currentBookNotifier.chapterCount;
    final progress = (currentBookState.readingProgress * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.leftWorkspaceColor,
      ),
      child: Column(
        children: [
          _ReaderLeftPanelTitleBar(
            onClose: () => workspaceController.setLeftPanelOpen(false),
          ),
          _ReaderLeftPanelHeader(
            bookTitle: book?.title ?? '当前书籍',
            author: book?.author,
            chapterProgress: chapterCount > 0
                ? '第 $currentChapter / $chapterCount 节 · $progress%'
                : null,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
          Expanded(
            child: ReaderTocPanel(
              onGoToChapter: onGoToChapter,
              onChapterSelected: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderLeftPanelTitleBar extends StatelessWidget {
  final VoidCallback onClose;

  const _ReaderLeftPanelTitleBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 0),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '目录',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Tooltip(
              message: '收起目录',
              waitDuration: const Duration(milliseconds: 500),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  hoverColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderLeftPanelHeader extends StatelessWidget {
  final String bookTitle;
  final String? author;
  final String? chapterProgress;

  const _ReaderLeftPanelHeader({
    required this.bookTitle,
    this.author,
    this.chapterProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 38,
                  height: 50,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 22,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    if (author != null && author!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                    if (chapterProgress != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        chapterProgress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
