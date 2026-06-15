import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/book_difficulty.dart';
import '../../theme/city_theme_tokens.dart';
import '../book_difficulty_chip.dart';
import '../flow/flow_components.dart';
import 'book_cover_view.dart';
import 'home_hover_surface.dart';

enum BookShelfAction { open, rename, remove }

class BookShelfItem extends StatefulWidget {
  static const double itemWidth = 164;
  static const double itemHeight = 286;

  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final BookDifficultyRating? difficulty;
  final bool isDifficultyLoading;
  final bool forceDefaultCover;
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
    this.forceDefaultCover = false,
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
    final city = Theme.of(context).extension<CityThemeTokens>();

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
          width: BookShelfItem.itemWidth,
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
                            ? (city?.activeBlue ?? theme.colorScheme.primary)
                                  .withValues(alpha: 0.46)
                            : Colors.transparent,
                      ),
                      boxShadow: _isHovering
                          ? [
                              BoxShadow(
                                color:
                                    (city?.activeBlue ??
                                            theme.colorScheme.primary)
                                        .withValues(
                                          alpha: city == null ? 0.12 : 0.18,
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
                      title: widget.title,
                      author: widget.author,
                      forceDefaultCover: widget.forceDefaultCover,
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
                  color: city?.textPrimary ?? theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
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
    final selected = await showFlowMenuAt<BookShelfAction>(
      context: context,
      position: position,
      entries: _buildMenuEntries(),
    );
    if (selected != null) _handleAction(selected);
  }

  List<FlowMenuEntry<BookShelfAction>> _buildMenuEntries() {
    return [
      const FlowMenuItem(
        value: BookShelfAction.open,
        icon: Icons.menu_book_outlined,
        label: '继续阅读',
      ),
      if (widget.onRename != null)
        const FlowMenuItem(
          value: BookShelfAction.rename,
          icon: Icons.drive_file_rename_outline,
          label: '重命名',
        ),
      if (widget.onRemove != null) const FlowMenuDivider(),
      if (widget.onRemove != null)
        const FlowMenuItem(
          value: BookShelfAction.remove,
          icon: Icons.remove_circle_outline,
          label: '移出书架',
          destructive: true,
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
    final city = Theme.of(context).extension<CityThemeTokens>();

    return FlowMenuButton<BookShelfAction>(
      tooltip: '书籍操作',
      onSelected: onSelected,
      entries: [
        const FlowMenuItem(
          value: BookShelfAction.open,
          icon: Icons.menu_book_outlined,
          label: '继续阅读',
        ),
        if (canRename)
          const FlowMenuItem(
            value: BookShelfAction.rename,
            icon: Icons.drive_file_rename_outline,
            label: '重命名',
          ),
        if (canRemove) const FlowMenuDivider(),
        if (canRemove)
          const FlowMenuItem(
            value: BookShelfAction.remove,
            icon: Icons.remove_circle_outline,
            label: '移出书架',
            destructive: true,
          ),
      ],
      child: HomeHoverSurface(
        width: 34,
        height: 34,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: (city?.cardSurface ?? theme.colorScheme.surface)
            .withValues(alpha: 0.9),
        hoverBackgroundColor:
            city?.panelSurface ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.96),
        borderColor: (city?.warmBorder ?? theme.colorScheme.outlineVariant)
            .withValues(alpha: city == null ? 0.65 : 1),
        hoverBorderColor: (city?.activeBlue ?? theme.colorScheme.primary)
            .withValues(alpha: 0.48),
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
              ? city?.activeBlue ?? theme.colorScheme.primary
              : city?.textPrimary ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
