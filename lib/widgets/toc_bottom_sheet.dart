import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../providers/reading/current_book_notifier.dart';
import 'reader_shell/reader_toc_panel.dart';

class TocBottomSheet extends riverpod.ConsumerWidget {
  final ValueChanged<int>? onGoToChapter;

  const TocBottomSheet({super.key, this.onGoToChapter});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final book = currentBookNotifier.book;
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
              onGoToChapter: onGoToChapter,
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
  final ValueChanged<int>? onGoToChapter;
  final ValueChanged<int>? onChapterSelected;
  final double? width;
  final double maxHeight;

  const TocDropdownPanel({
    super.key,
    this.onClose,
    this.onGoToChapter,
    this.onChapterSelected,
    this.width,
    this.maxHeight = 430,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final book = currentBookNotifier.book;
    if (book == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth =
        width ?? (screenSize.width * 0.36).clamp(300.0, 380.0).toDouble();
    final panelMaxHeight = (screenSize.height - 112)
        .clamp(260.0, maxHeight)
        .toDouble();
    final tocItems = buildReaderTocItems(book);
    final panelHeight = (96 + tocItems.length * _tocTileExtent).clamp(
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
          onGoToChapter: onGoToChapter,
          onChapterSelected: onChapterSelected,
        ),
      ),
    );
  }
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
  final ValueChanged<int>? onGoToChapter;
  final ValueChanged<int>? onChapterSelected;

  const _TocPanelContent({
    required this.showDragHandle,
    this.scrollController,
    this.onClose,
    this.onGoToChapter,
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
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final theme = Theme.of(context);
    final book = currentBookNotifier.book;
    if (book == null) return const SizedBox.shrink();
    final tocItems = buildReaderTocItems(book);
    if (tocItems.isEmpty) return const SizedBox.shrink();
    final selectedIndex = selectedReaderTocIndexForChapter(
      tocItems,
      currentBookState.currentChapter,
    );
    _queueInitialChapterPosition(
      selectedIndex,
      tocItems.length,
    );

    return Column(
      children: [
        _TocPanelHeader(
          itemCount: tocItems.length,
          currentIndex: selectedIndex,
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
                itemCount: tocItems.length,
                itemBuilder: (context, index) {
                  final item = tocItems[index];
                  final isSelected = index == selectedIndex;
                  return _TocChapterTile(
                    index: index,
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      final onGoToChapter = widget.onGoToChapter;
                      if (onGoToChapter == null) {
                        currentBookNotifier.goToChapter(
                          item.targetChapterIndex,
                        );
                      } else {
                        onGoToChapter(item.targetChapterIndex);
                      }
                      widget.onChapterSelected?.call(item.targetChapterIndex);
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
  final int currentIndex;
  final bool showDragHandle;
  final VoidCallback? onClose;

  const _TocPanelHeader({
    required this.itemCount,
    required this.currentIndex,
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
              '共 $itemCount 项 · 当前第 ${(currentIndex + 1).clamp(1, itemCount)} 项',
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
  final ReaderTocItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TocChapterTile({
    required this.index,
    required this.item,
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
    final levelIndent = widget.item.level * 12.0;

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
                                        '${widget.item.ordinal}',
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
                                      '${widget.item.ordinal}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: numberColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: levelIndent),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.title,
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
                                if (widget.item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.subtitle!,
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
