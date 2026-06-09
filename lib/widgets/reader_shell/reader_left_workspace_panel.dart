import 'package:flutter/material.dart';

import 'reader_workspace_controller.dart';
import 'reader_toc_panel.dart';

class ReaderLeftWorkspacePanel extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final ReaderLeftPanelTab currentTab;
  final ValueChanged<int>? onGoToChapter;

  const ReaderLeftWorkspacePanel({
    super.key,
    required this.workspaceController,
    required this.currentTab,
    this.onGoToChapter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          _ReaderLeftPanelHeader(
            bookTitle: '当前书籍',
            chapterProgress: null,
          ),
          _buildTabBar(context),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
          Expanded(child: _buildTabContent(context)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = [
      (ReaderLeftPanelTab.toc, Icons.menu, '目录'),
      (ReaderLeftPanelTab.bookmarks, Icons.bookmark_outline, '书签'),
      (ReaderLeftPanelTab.search, Icons.search, '搜索'),
      (ReaderLeftPanelTab.goals, Icons.track_changes_outlined, '目标'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (final (_, (tab, icon, label)) in tabs.indexed)
            Expanded(
              child: _TabButton(
                icon: icon,
                label: label,
                isSelected: currentTab == tab,
                onTap: () => workspaceController.setLeftTab(tab),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return IndexedStack(
      index: ReaderLeftPanelTab.values.indexOf(currentTab),
      children: [
        ReaderTocPanel(
          onGoToChapter: onGoToChapter,
          onChapterSelected: (_) {},
        ),
        _buildPlaceholderTab(context, Icons.bookmark_outline, '书签'),
        _buildPlaceholderTab(context, Icons.search, '搜索'),
        _buildPlaceholderTab(context, Icons.track_changes_outlined, '阅读目标'),
      ],
    );
  }

  Widget _buildPlaceholderTab(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '即将推出',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderLeftPanelHeader extends StatelessWidget {
  final String bookTitle;
  final String? chapterProgress;

  const _ReaderLeftPanelHeader({
    required this.bookTitle,
    this.chapterProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (chapterProgress != null) ...[
            const SizedBox(height: 2),
            Text(
              chapterProgress!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primary.withValues(alpha: 0.1)
                : (_isHovered
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.isSelected
                        ? primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.normal,
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
