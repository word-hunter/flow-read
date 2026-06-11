import 'package:flutter/material.dart';

import '../../theme/app_surface_tokens.dart';
import 'reader_workspace_controller.dart';

class ReaderRightAssistantPanel extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final Widget dictionaryContent;
  final Widget aiContent;
  final Widget chapterContent;
  final Widget? currentContent;
  final ValueChanged<ReaderRightPanelTab>? onTabSelected;

  const ReaderRightAssistantPanel({
    super.key,
    required this.workspaceController,
    this.dictionaryContent = const _EmptyState(
      icon: Icons.text_fields_outlined,
      message: '本章词汇和单词释义会显示在这里',
    ),
    this.aiContent = const _EmptyState(
      icon: Icons.auto_awesome_outlined,
      message: '针对当前章节提问，或使用工具栏触发总结/解释',
    ),
    this.chapterContent = const _EmptyState(
      icon: Icons.insights_outlined,
      message: '当前章节进度、词汇与阅读状态会显示在这里',
    ),
    this.currentContent,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.assistantSurface,
      ),
      child: Column(
        children: [
          _buildHeader(context, theme),
          Divider(
            height: 1,
            color: tokens.panelBorderColor,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final tabs = [
      (ReaderRightPanelTab.dictionary, Icons.text_fields_outlined, '词汇'),
      (ReaderRightPanelTab.ai, Icons.auto_awesome_outlined, 'AI'),
      (ReaderRightPanelTab.chapter, Icons.insights_outlined, '统计'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final (tab, icon, label) in tabs)
                  Expanded(
                    child: _TabChip(
                      buttonKey: ValueKey('reader-right-tab-${tab.name}'),
                      icon: icon,
                      label: label,
                      isSelected: workspaceController.rightTab == tab,
                      onTap: () => _selectTab(tab),
                    ),
                  ),
              ],
            ),
          ),
          _IconAction(
            icon: Icons.close,
            tooltip: '关闭面板',
            onTap: () => workspaceController.closeRightPanel(),
          ),
        ],
      ),
    );
  }

  void _selectTab(ReaderRightPanelTab tab) {
    final callback = onTabSelected;
    if (callback != null) {
      callback(tab);
      return;
    }
    workspaceController.setRightTab(tab);
  }

  Widget _buildBody() {
    final content = currentContent;
    if (content != null) {
      return content;
    }

    return IndexedStack(
      index: ReaderRightPanelTab.values.indexOf(workspaceController.rightTab),
      children: [
        dictionaryContent,
        aiContent,
        chapterContent,
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final Key? buttonKey;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    this.buttonKey,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final foreground = isSelected
        ? primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.82);

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 15, color: foreground),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: foreground,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 34 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
