import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../models/chapter.dart';
import '../models/content_block.dart';
import '../providers/reading/current_book_provider.dart';

class TocBottomSheet extends riverpod.ConsumerWidget {
  const TocBottomSheet({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentBook = ref.watch(currentBookProvider);
    final book = currentBook.book;
    if (book == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return _TocPanelSurface(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: _TocPanelContent(
              scrollController: scrollController,
              showDragHandle: true,
              onClose: () => Navigator.pop(context),
              onChapterSelected: (_) => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}

class TocDropdownPanel extends riverpod.ConsumerWidget {
  final VoidCallback? onClose;
  final ValueChanged<int>? onChapterSelected;
  final double? width;
  final double maxHeight;

  const TocDropdownPanel({
    super.key,
    this.onClose,
    this.onChapterSelected,
    this.width,
    this.maxHeight = 430,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentBook = ref.watch(currentBookProvider);
    final book = currentBook.book;
    if (book == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth =
        width ?? (screenSize.width * 0.36).clamp(300.0, 380.0).toDouble();
    final panelMaxHeight = (screenSize.height - 112)
        .clamp(260.0, maxHeight)
        .toDouble();
    final panelHeight = (96 + book.chapters.length * 50.0).clamp(
      220.0,
      panelMaxHeight,
    );

    return SizedBox(
      width: panelWidth,
      height: panelHeight.toDouble(),
      child: _TocPanelSurface(
        borderRadius: BorderRadius.circular(8),
        elevation: 8,
        child: _TocPanelContent(
          showDragHandle: false,
          onClose: onClose,
          onChapterSelected: onChapterSelected,
        ),
      ),
    );
  }
}

class _ChapterTocLabel {
  final String title;
  final String? subtitle;

  const _ChapterTocLabel({required this.title, this.subtitle});
}

_ChapterTocLabel _chapterLabel(Chapter chapter, int index) {
  final title = chapter.title.replaceAll(RegExp(r'\s+'), ' ').trim();
  final fallbackTitle = '第 ${index + 1} 节';
  final isGenericTitle =
      title.isEmpty ||
      RegExp(
        r'^(section|chapter|part)\s*\d+$',
        caseSensitive: false,
      ).hasMatch(title) ||
      RegExp(r'^第\s*\d+\s*[章节回]$').hasMatch(title);

  if (!isGenericTitle) {
    return _ChapterTocLabel(title: title);
  }

  final opening = _chapterOpeningSnippet(chapter);
  if (opening.isEmpty) {
    return _ChapterTocLabel(title: title.isEmpty ? fallbackTitle : title);
  }

  return _ChapterTocLabel(
    title: opening,
    subtitle: title.isEmpty ? fallbackTitle : title,
  );
}

String _chapterOpeningSnippet(Chapter chapter) {
  final blockText = _firstReadableTextBlock(chapter.blocks);
  final normalized = _cleanOpeningText(
    blockText.isEmpty ? chapter.plainText : blockText,
  );
  if (normalized.isEmpty) return '';

  final words = normalized.split(' ');
  if (words.length > 8) {
    final snippet = words.take(8).join(' ');
    if (snippet.length <= 72) return '$snippet...';
  }

  if (normalized.length <= 72) return normalized;
  return '${normalized.substring(0, 72).trimRight()}...';
}

String _firstReadableTextBlock(List<ContentBlock> blocks) {
  for (final block in blocks) {
    if (block is! TextBlock) continue;
    final text = _cleanOpeningText(block.plainText);
    if (text.isEmpty) continue;
    return text;
  }
  return '';
}

String _cleanOpeningText(String text) {
  var normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  while (normalized.isNotEmpty) {
    final withoutImagePrefix = normalized.replaceFirst(
      RegExp(r'^(?:image|img|figure)\b[\s:：\-—–]*', caseSensitive: false),
      '',
    );
    if (withoutImagePrefix == normalized) break;
    normalized = withoutImagePrefix.trimLeft();
  }
  return normalized;
}

class _TocPanelSurface extends StatelessWidget {
  final BorderRadius borderRadius;
  final double elevation;
  final Widget child;

  const _TocPanelSurface({
    required this.borderRadius,
    required this.child,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: elevation,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

const double _tocTileExtent = 52;

class _TocPanelContent extends riverpod.ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final bool showDragHandle;
  final VoidCallback? onClose;
  final ValueChanged<int>? onChapterSelected;

  const _TocPanelContent({
    required this.showDragHandle,
    this.scrollController,
    this.onClose,
    this.onChapterSelected,
  });

  @override
  riverpod.ConsumerState<_TocPanelContent> createState() =>
      _TocPanelContentState();
}

class _TocPanelContentState extends riverpod.ConsumerState<_TocPanelContent> {
  final ScrollController _ownedScrollController = ScrollController();
  bool _initialChapterPositionQueued = false;
  int _initialChapterPositionAttempts = 0;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _ownedScrollController;

  @override
  void dispose() {
    _ownedScrollController.dispose();
    super.dispose();
  }

  void _queueInitialChapterPosition(int currentChapter, int itemCount) {
    if (_initialChapterPositionQueued) return;
    _initialChapterPositionQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _effectiveScrollController;
      if (!controller.hasClients) {
        _initialChapterPositionAttempts += 1;
        if (_initialChapterPositionAttempts < 3) {
          _initialChapterPositionQueued = false;
          _queueInitialChapterPosition(currentChapter, itemCount);
        }
        return;
      }

      final visibleAnchorIndex = (currentChapter - 2).clamp(0, itemCount - 1);
      final target = (visibleAnchorIndex * _tocTileExtent)
          .clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          )
          .toDouble();
      if ((controller.offset - target).abs() > 0.5) {
        controller.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBook = ref.watch(currentBookProvider);
    final theme = Theme.of(context);
    final book = currentBook.book;
    if (book == null) return const SizedBox.shrink();
    _queueInitialChapterPosition(
      currentBook.currentChapter,
      book.chapters.length,
    );

    return Column(
      children: [
        _TocPanelHeader(
          itemCount: book.chapters.length,
          currentChapter: currentBook.currentChapter,
          showDragHandle: widget.showDragHandle,
          onClose: widget.onClose,
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _effectiveScrollController,
                primary: false,
                itemExtent: _tocTileExtent,
                padding: EdgeInsets.fromLTRB(
                  8,
                  widget.showDragHandle ? 8 : 6,
                  8,
                  28,
                ),
                itemCount: book.chapters.length,
                itemBuilder: (context, index) {
                  final isSelected = index == currentBook.currentChapter;
                  return _TocChapterTile(
                    index: index,
                    label: _chapterLabel(book.chapters[index], index),
                    isSelected: isSelected,
                    onTap: () {
                      currentBook.goToChapter(index);
                      widget.onChapterSelected?.call(index);
                    },
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.surface.withValues(alpha: 0),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TocPanelHeader extends StatelessWidget {
  final int itemCount;
  final int currentChapter;
  final bool showDragHandle;
  final VoidCallback? onClose;

  const _TocPanelHeader({
    required this.itemCount,
    required this.currentChapter,
    required this.showDragHandle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, showDragHandle ? 14 : 14, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '目录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '关闭目录',
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '共 $itemCount 节 · 当前第 ${currentChapter + 1} 节',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final numberColor = _isHovered && !widget.isSelected
        ? primary
        : theme.colorScheme.onSurfaceVariant;

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
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    key: ValueKey('toc-chapter-hover-overlay-${widget.index}'),
                    opacity: _isHovered ? 1 : 0,
                    duration: const Duration(milliseconds: 110),
                    curve: Curves.easeOutCubic,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.isSelected
                              ? [
                                  primary.withValues(alpha: 0.05),
                                  primary.withValues(alpha: 0.02),
                                ]
                              : [
                                  theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.62),
                                  theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.18,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHover: _setHovered,
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: SizedBox(
                    height: _tocTileExtent,
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
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      '${widget.index + 1}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: numberColor,
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
                            _CurrentChapterBadge(color: primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentChapterBadge extends StatelessWidget {
  final Color color;

  const _CurrentChapterBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '当前',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
