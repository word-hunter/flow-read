import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import 'book_difficulty_chip.dart';
import 'book_cover_view.dart';
import 'home_hover_surface.dart';

enum BookShelfAction { open, rename, remove }

class BookShelfItem extends StatefulWidget {
  static const double itemHeight = 274;

  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final BookDifficultyRating? difficulty;
  final bool isDifficultyLoading;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  const BookShelfItem({
    super.key,
    required this.title,
    required this.author,
    this.coverBytes,
    required this.progressPercent,
    this.difficulty,
    this.isDifficultyLoading = false,
    this.onTap,
    this.onRename,
    this.onRemove,
  });

  @override
  State<BookShelfItem> createState() => _BookShelfItemState();
}

class _BookShelfItemState extends State<BookShelfItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: SizedBox(
          width: 156,
          height: BookShelfItem.itemHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        BookCoverView.borderRadius,
                      ),
                      border: Border.all(
                        color: _isHovering
                            ? theme.colorScheme.primary.withValues(alpha: 0.46)
                            : Colors.transparent,
                      ),
                      boxShadow: _isHovering
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : const [],
                    ),
                    child: BookCoverView(
                      coverBytes: widget.coverBytes,
                      progressPercent: widget.progressPercent,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedOpacity(
                      opacity: _isHovering ? 1 : 0,
                      duration: const Duration(milliseconds: 140),
                      child: IgnorePointer(
                        ignoring: !_isHovering,
                        child: _BookActionsButton(
                          onSelected: _handleAction,
                          canRename: widget.onRename != null,
                          canRemove: widget.onRemove != null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.difficulty != null || widget.isDifficultyLoading) ...[
                const SizedBox(height: 6),
                BookDifficultyChip(
                  rating: widget.difficulty,
                  isLoading: widget.isDifficultyLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<BookShelfAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: _buildMenuItems(context),
    );
    if (selected != null) _handleAction(selected);
  }

  List<PopupMenuEntry<BookShelfAction>> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    return [
      const PopupMenuItem(
        value: BookShelfAction.open,
        child: _BookMenuItem(icon: Icons.menu_book_outlined, label: '继续阅读'),
      ),
      if (widget.onRename != null)
        const PopupMenuItem(
          value: BookShelfAction.rename,
          child: _BookMenuItem(
            icon: Icons.drive_file_rename_outline,
            label: '重命名',
          ),
        ),
      if (widget.onRemove != null) const PopupMenuDivider(),
      if (widget.onRemove != null)
        PopupMenuItem(
          value: BookShelfAction.remove,
          child: _BookMenuItem(
            icon: Icons.remove_circle_outline,
            label: '移出书架',
            color: theme.colorScheme.error,
          ),
        ),
    ];
  }

  void _handleAction(BookShelfAction action) {
    switch (action) {
      case BookShelfAction.open:
        widget.onTap?.call();
        return;
      case BookShelfAction.rename:
        widget.onRename?.call();
        return;
      case BookShelfAction.remove:
        widget.onRemove?.call();
        return;
    }
  }
}

class _BookActionsButton extends StatelessWidget {
  final ValueChanged<BookShelfAction> onSelected;
  final bool canRename;
  final bool canRemove;

  const _BookActionsButton({
    required this.onSelected,
    required this.canRename,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<BookShelfAction>(
      tooltip: '书籍操作',
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: BookShelfAction.open,
          child: _BookMenuItem(icon: Icons.menu_book_outlined, label: '继续阅读'),
        ),
        if (canRename)
          const PopupMenuItem(
            value: BookShelfAction.rename,
            child: _BookMenuItem(
              icon: Icons.drive_file_rename_outline,
              label: '重命名',
            ),
          ),
        if (canRemove) const PopupMenuDivider(),
        if (canRemove)
          PopupMenuItem(
            value: BookShelfAction.remove,
            child: _BookMenuItem(
              icon: Icons.remove_circle_outline,
              label: '移出书架',
              color: theme.colorScheme.error,
            ),
          ),
      ],
      child: HomeHoverSurface(
        width: 34,
        height: 34,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
        hoverBackgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.96,
        ),
        borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        hoverBorderColor: theme.colorScheme.primary.withValues(alpha: 0.48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        hoverBoxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        builder: (context, isHovering) => Icon(
          Icons.more_horiz,
          size: 20,
          color: isHovering
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _BookMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _BookMenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ),
      ],
    );
  }
}
