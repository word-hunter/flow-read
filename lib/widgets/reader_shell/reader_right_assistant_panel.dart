import 'package:flutter/material.dart';

import 'reader_workspace_controller.dart';

class ReaderRightAssistantPanel extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final Widget dictionaryContent;
  final Widget selectedTextContent;
  final Widget aiContent;
  final Widget chapterContent;
  final Widget? currentContent;

  const ReaderRightAssistantPanel({
    super.key,
    required this.workspaceController,
    this.dictionaryContent = const _EmptyState(
      icon: Icons.touch_app_outlined,
      message: '点击正文中的单词查看释义',
    ),
    this.selectedTextContent = const _EmptyState(
      icon: Icons.text_fields_outlined,
      message: '选中文本后可进行翻译、解释或语法分析',
    ),
    this.aiContent = const _EmptyState(
      icon: Icons.auto_awesome_outlined,
      message: '针对当前章节提问，或使用工具栏触发总结/解释',
    ),
    this.chapterContent = const _EmptyState(
      icon: Icons.menu_book_outlined,
      message: '当前章节进度、词汇与阅读状态会显示在这里',
    ),
    this.currentContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, theme),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final tabs = [
      (ReaderRightPanelTab.dictionary, Icons.menu_book_outlined, '词典'),
      (ReaderRightPanelTab.selectedText, Icons.text_fields_outlined, '选中'),
      (ReaderRightPanelTab.ai, Icons.auto_awesome_outlined, 'AI'),
      (ReaderRightPanelTab.chapter, Icons.insights_outlined, '章节'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (tab, icon, label) in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: _TabChip(
                        icon: icon,
                        label: label,
                        isSelected: workspaceController.rightTab == tab,
                        onTap: () =>
                            workspaceController.setRightTab(tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _IconAction(
            icon: workspaceController.isRightPanelPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            tooltip: workspaceController.isRightPanelPinned
                ? '取消固定面板'
                : '固定面板',
            onTap: () => workspaceController
                .setRightPanelPinned(!workspaceController.isRightPanelPinned),
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

  Widget _buildBody() {
    final content = currentContent;
    if (content != null) {
      return content;
    }

    return IndexedStack(
      index: ReaderRightPanelTab.values.indexOf(workspaceController.rightTab),
      children: [
        dictionaryContent,
        selectedTextContent,
        aiContent,
        chapterContent,
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final chip = InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? primary : null),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: primary.withValues(alpha: 0.12),
      backgroundColor: Colors.transparent,
      side: BorderSide.none,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected
            ? primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );

    return chip;
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
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
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
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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
