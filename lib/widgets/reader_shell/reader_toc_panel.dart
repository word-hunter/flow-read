import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/chapter.dart';
import '../../models/content_block.dart';
import '../../providers/reading/current_book_notifier.dart';

class ReaderTocPanel extends riverpod.ConsumerStatefulWidget {
  final ValueChanged<int>? onGoToChapter;
  final ValueChanged<int>? onChapterSelected;

  const ReaderTocPanel({
    super.key,
    this.onGoToChapter,
    this.onChapterSelected,
  });

  @override
  riverpod.ConsumerState<ReaderTocPanel> createState() =>
      _ReaderTocPanelState();
}

class _ReaderTocPanelState extends riverpod.ConsumerState<ReaderTocPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _initialChapterPositionQueued = false;
  int _initialChapterPositionAttempts = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _queueInitialChapterPosition(int currentChapter, int itemCount) {
    if (_initialChapterPositionQueued) return;
    _initialChapterPositionQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        _initialChapterPositionAttempts += 1;
        if (_initialChapterPositionAttempts < 3) {
          _initialChapterPositionQueued = false;
          _queueInitialChapterPosition(currentChapter, itemCount);
        }
        return;
      }

      final visibleAnchorIndex = (currentChapter - 2).clamp(0, itemCount - 1);
      final target = (visibleAnchorIndex * 52.0).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      if ((_scrollController.offset - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final theme = Theme.of(context);
    final book = currentBookNotifier.book;
    if (book == null) return _buildEmptyState(theme);

    _queueInitialChapterPosition(
      currentBookState.currentChapter,
      book.chapters.length,
    );

    final labels = <_ChapterTocLabel>[];
    for (var i = 0; i < book.chapters.length; i++) {
      labels.add(_chapterLabelForWorkspace(book.chapters[i], i));
    }

    return Column(
      children: [
        _TocWorkspaceHeader(
          itemCount: book.chapters.length,
          currentChapter: currentBookState.currentChapter,
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            primary: false,
            itemExtent: 52,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 28),
            itemCount: labels.length,
            itemBuilder: (context, index) {
              final isSelected = index == currentBookState.currentChapter;
              return _TocChapterTile(
                index: index,
                label: labels[index],
                isSelected: isSelected,
                onTap: () {
                  final onGoToChapter = widget.onGoToChapter;
                  if (onGoToChapter == null) {
                    currentBookNotifier.goToChapter(index);
                  } else {
                    onGoToChapter(index);
                  }
                  widget.onChapterSelected?.call(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '暂无目录',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TocWorkspaceHeader extends StatelessWidget {
  final int itemCount;
  final int currentChapter;

  const _TocWorkspaceHeader({
    required this.itemCount,
    required this.currentChapter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目录',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 $itemCount 节 · 当前第 ${currentChapter + 1} 节',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTocLabel {
  final String title;
  final String? subtitle;

  const _ChapterTocLabel({required this.title, this.subtitle});
}

_ChapterTocLabel _chapterLabelForWorkspace(Chapter chapter, int index) {
  final title = chapter.title.replaceAll(RegExp(r'\s+'), ' ').trim();
  final fallbackTitle = '第 ${index + 1} 节';
  final isGenericTitle =
      title.isEmpty ||
      RegExp(r'^(section|chapter|part)\s*\d+$', caseSensitive: false)
          .hasMatch(title) ||
      RegExp(r'^第\s*\d+\s*[章节回]$').hasMatch(title);

  if (!isGenericTitle) {
    return _ChapterTocLabel(title: title);
  }

  final opening = _chapterOpeningSnippet(chapter);
  if (opening.isEmpty) {
    return _ChapterTocLabel(
        title: title.isEmpty ? fallbackTitle : title);
  }

  return _ChapterTocLabel(
    title: opening,
    subtitle: title.isEmpty ? fallbackTitle : title,
  );
}

String _chapterOpeningSnippet(Chapter chapter) {
  var text = '';
  for (final block in chapter.blocks) {
    if (block is TextBlock) {
      text = block.plainText;
      break;
    }
  }
  if (text.isEmpty) {
    text = chapter.plainText;
  }
  var normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  while (normalized.isNotEmpty) {
    final withoutImagePrefix = normalized.replaceFirst(
      RegExp(r'^(?:image|img|figure)\b[\s:：\-—–]*', caseSensitive: false),
      '',
    );
    if (withoutImagePrefix == normalized) break;
    normalized = withoutImagePrefix.trimLeft();
  }
  if (normalized.isEmpty) return '';

  final words = normalized.split(' ');
  if (words.length > 8) {
    final snippet = words.take(8).join(' ');
    if (snippet.length <= 72) return '$snippet...';
  }
  if (normalized.length <= 72) return normalized;
  return '${normalized.substring(0, 72).trimRight()}...';
}

class _TocChapterTile extends StatefulWidget {
  final int index;
  final _ChapterTocLabel label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TocChapterTile({
    required this.index,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TocChapterTile> createState() => _TocChapterTileState();
}

class _TocChapterTileState extends State<_TocChapterTile> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final backgroundColor = widget.isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
        : Colors.transparent;
    final borderColor = widget.isSelected
        ? primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DecoratedBox(
        key: ValueKey('toc-chapter-tile-${widget.index}'),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHover: _setHovered,
              mouseCursor: SystemMouseCursors.click,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 10, 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 6,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            width: widget.isSelected ? 3 : 0,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: widget.isSelected
                              ? CircleAvatar(
                                  radius: 13,
                                  backgroundColor: primary.withValues(
                                    alpha: 0.86,
                                  ),
                                  child: Text(
                                    '${widget.index + 1}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                )
                              : Text(
                                  '${widget.index + 1}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            if (widget.label.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.label.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '当前',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
