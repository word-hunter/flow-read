import 'package:flutter/material.dart';

import '../../theme/app_surface_tokens.dart';
import '../../theme/city_theme_tokens.dart';
import 'reader_workspace_controller.dart';

class ReaderRightAssistantPanel extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final Widget dictionaryContent;
  final Widget aiContent;
  final Widget chapterContent;
  final Widget? currentContent;
  final ValueChanged<ReaderRightPanelTab>? onTabSelected;
  final VoidCallback? onClose;

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
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);
    final panelTheme = _resolveAssistantPanelTheme(theme, tokens);

    return Theme(
      data: panelTheme,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.assistantSurface,
        ),
        child: Column(
          children: [
            _buildHeader(context, panelTheme),
            Divider(
              height: 1,
              color: tokens.panelBorderColor,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
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
            onTap: onClose ?? workspaceController.closeRightPanel,
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

ThemeData _resolveAssistantPanelTheme(
  ThemeData theme,
  AppSurfaceTokens tokens,
) {
  final colorScheme = theme.colorScheme;
  final cityTokens = theme.extension<CityThemeTokens>();
  final surface = tokens.assistantSurface;
  final primary = cityTokens?.activeBlue ?? colorScheme.primary;
  final onSurface =
      cityTokens?.textPrimary ??
      _readableColorFor(surface, preferred: colorScheme.onSurface);
  final onSurfaceVariant =
      cityTokens?.textSecondary ??
      _secondaryColorFor(
        surface: surface,
        onSurface: onSurface,
        preferred: colorScheme.onSurfaceVariant,
      );
  final elevatedSurface = _tintedSurface(
    tint: primary,
    surface: surface,
    alpha: surface.computeLuminance() < 0.45 ? 0.10 : 0.05,
  );
  final primaryContainer = _tintedSurface(
    tint: primary,
    surface: surface,
    alpha: surface.computeLuminance() < 0.45 ? 0.18 : 0.11,
  );
  final lowestSurface = _neutralSurfaceFor(
    surface: surface,
    dark: const Color(0xFF111B28),
    light: Colors.white,
  );
  final lowSurface = _neutralSurfaceFor(
    surface: surface,
    dark: const Color(0xFF162233),
    light: const Color(0xFFF7FAFD),
  );
  final highSurface = _neutralSurfaceFor(
    surface: surface,
    dark: const Color(0xFF202D40),
    light: const Color(0xFFEFF4FA),
  );

  return theme.copyWith(
    colorScheme: colorScheme.copyWith(
      surface: surface,
      surfaceContainerLowest: lowestSurface,
      surfaceContainerLow: lowSurface,
      surfaceContainerHigh: highSurface,
      surfaceContainerHighest: elevatedSurface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      primary: primary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: _readableColorFor(
        primaryContainer,
        preferred: onSurface,
      ),
      outline: onSurfaceVariant,
      outlineVariant: tokens.panelBorderColor,
    ),
  );
}

Color _neutralSurfaceFor({
  required Color surface,
  required Color dark,
  required Color light,
}) {
  return surface.computeLuminance() < 0.45 ? dark : light;
}

Color _tintedSurface({
  required Color tint,
  required Color surface,
  required double alpha,
}) {
  return Color.alphaBlend(tint.withValues(alpha: alpha), surface);
}

Color _secondaryColorFor({
  required Color surface,
  required Color onSurface,
  required Color preferred,
}) {
  if (_contrastRatio(surface, preferred) >= 3.0) return preferred;
  final candidate = Color.lerp(
    onSurface,
    surface,
    surface.computeLuminance() < 0.45 ? 0.28 : 0.38,
  )!;
  if (_contrastRatio(surface, candidate) >= 3.0) return candidate;
  return onSurface;
}

Color _readableColorFor(Color background, {required Color preferred}) {
  if (_contrastRatio(background, preferred) >= 4.5) return preferred;

  final whiteContrast = _contrastRatio(background, Colors.white);
  final blackContrast = _contrastRatio(background, Colors.black);
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}

double _contrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final lighter = aLum > bLum ? aLum : bLum;
  final darker = aLum > bLum ? bLum : aLum;
  return (lighter + 0.05) / (darker + 0.05);
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
