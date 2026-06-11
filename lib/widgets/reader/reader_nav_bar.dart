import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../providers/reading/bookmark_notifier.dart';
import '../../providers/reading/current_book_notifier.dart';
import '../../providers/reading/reading_config_notifier.dart';
import '../../theme/app_surface_tokens.dart';
import '../flow/flow_components.dart';
import '../font_settings_sheet.dart';
import '../reader_shell/reader_toc_panel.dart';
import '../toc_bottom_sheet.dart';
import 'reader_location_summary.dart';

class ReaderNavBar extends StatelessWidget {
  static const double _toolbarIconGap = 8;
  static const double _toolbarButtonWidth = 40;
  static const double _toolbarButtonHeight = 32;
  static const double _toolbarInfoWidth = 540;

  final CurrentBookNotifier currentBook;
  final CurrentBookState currentBookState;
  final ReadingConfigState config;
  final BookmarkNotifier bookmarks;
  final String chapterTitle;
  final double layoutWidth;
  final ValueListenable<double> displayProgressListenable;
  final bool showSidebarToggle;
  final bool sidebarOpen;
  final bool useWorkspaceTocPanel;
  final bool tocMenuOpen;
  final MenuController tocMenuController;
  final MenuController fontSettingsMenuController;
  final VoidCallback onSidebarToggle;
  final VoidCallback onShowWorkspaceToc;
  final VoidCallback onShowTocSheet;
  final ValueChanged<MenuController> onTocMenuToggle;
  final ValueChanged<bool> onTocMenuOpenChanged;
  final VoidCallback onShowFontSettingsSheet;
  final ValueChanged<MenuController> onFontSettingsMenuToggle;
  final ValueChanged<bool> onFontSettingsMenuOpenChanged;
  final VoidCallback onExitReader;
  final ValueChanged<int> onGoToChapter;
  final VoidCallback onSearchTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onBookmarkHistoryTap;
  final VoidCallback onOpenVocabularyPanel;
  final VoidCallback onStartChapterTraining;
  final VoidCallback onOpenStatsPanel;
  final VoidCallback onOpenChapterAI;

  const ReaderNavBar({
    super.key,
    required this.currentBook,
    required this.currentBookState,
    required this.config,
    required this.bookmarks,
    required this.chapterTitle,
    required this.layoutWidth,
    required this.displayProgressListenable,
    required this.showSidebarToggle,
    required this.sidebarOpen,
    required this.useWorkspaceTocPanel,
    required this.tocMenuOpen,
    required this.tocMenuController,
    required this.fontSettingsMenuController,
    required this.onSidebarToggle,
    required this.onShowWorkspaceToc,
    required this.onShowTocSheet,
    required this.onTocMenuToggle,
    required this.onTocMenuOpenChanged,
    required this.onShowFontSettingsSheet,
    required this.onFontSettingsMenuToggle,
    required this.onFontSettingsMenuOpenChanged,
    required this.onExitReader,
    required this.onGoToChapter,
    required this.onSearchTap,
    required this.onBookmarkTap,
    required this.onBookmarkHistoryTap,
    required this.onOpenVocabularyPanel,
    required this.onStartChapterTraining,
    required this.onOpenStatsPanel,
    required this.onOpenChapterAI,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final borderColor =
        cityPreset?.outline.withValues(alpha: 0.72) ??
        tokens.readerPageBorderColor;
    final toolbarTextColor =
        cityPreset?.secondaryText ?? theme.colorScheme.onSurfaceVariant;
    final showSearch = layoutWidth >= 520;
    final book = currentBook.book;
    final tocItems = book == null
        ? const <ReaderTocItem>[]
        : buildReaderTocItems(book);
    final usingStructuredToc =
        book != null && book.toc.isNotEmpty && tocItems.isNotEmpty;
    final selectedTocIndex = selectedReaderTocIndexForChapter(
      tocItems,
      currentBookState.currentChapter,
    );
    final visibleNavigationCount = usingStructuredToc
        ? tocItems.length
        : currentBook.chapterCount;
    final showChapterStep = layoutWidth >= 680 && visibleNavigationCount > 1;
    final compactToolbar = layoutWidth < 760;
    final contentTitle = chapterTitle.trim().isNotEmpty
        ? chapterTitle.trim()
        : '当前位置';
    final currentPosition = usingStructuredToc && tocItems.isNotEmpty
        ? selectedTocIndex + 1
        : currentBookState.currentChapter + 1;
    final chapterMetaPrefix = currentBook.hasBook && visibleNavigationCount > 0
        ? '$currentPosition / $visibleNavigationCount · '
        : null;
    final previousChapterTarget = usingStructuredToc
        ? _tocStepTarget(
            tocItems,
            selectedTocIndex,
            currentBookState.currentChapter,
            -1,
          )
        : currentBookState.currentChapter - 1;
    final nextChapterTarget = usingStructuredToc
        ? _tocStepTarget(
            tocItems,
            selectedTocIndex,
            currentBookState.currentChapter,
            1,
          )
        : currentBookState.currentChapter + 1;
    final canGoPreviousChapter =
        currentBook.hasBook &&
        previousChapterTarget != null &&
        previousChapterTarget >= 0;
    final canGoNextChapter =
        currentBook.hasBook &&
        nextChapterTarget != null &&
        nextChapterTarget < currentBook.chapterCount;

    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            cityPreset?.surface.withValues(alpha: 0.78) ??
            tokens.readerControlSurface,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _buildToolbarGroup(
            children: [
              _compactIconButton(
                context,
                key: const ValueKey('reader-toolbar-back'),
                icon: Icons.arrow_back,
                tooltip: '返回',
                onPressed: onExitReader,
              ),
              _buildTocButton(
                context,
                useDropdown: showSidebarToggle,
                useWorkspacePanel: useWorkspaceTocPanel,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compactToolbar ? 320 : _toolbarInfoWidth,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (showChapterStep) ...[
                      _chapterStepButton(
                        context,
                        icon: Icons.chevron_left,
                        tooltip: '上一个目录项',
                        onPressed: canGoPreviousChapter
                            ? () => onGoToChapter(previousChapterTarget)
                            : null,
                      ),
                      const SizedBox(width: _toolbarIconGap),
                    ],
                    Expanded(
                      child: chapterMetaPrefix == null
                          ? ReaderLocationSummary(
                              title: contentTitle,
                              metaLabel: null,
                              difficulty: currentBook.currentBookDifficulty,
                              textColor: toolbarTextColor,
                            )
                          : ValueListenableBuilder<double>(
                              valueListenable: displayProgressListenable,
                              builder: (context, progress, _) {
                                final progressPercent = (progress * 100)
                                    .round();
                                return ReaderLocationSummary(
                                  title: contentTitle,
                                  metaLabel:
                                      '$chapterMetaPrefix$progressPercent%',
                                  difficulty: currentBook.currentBookDifficulty,
                                  textColor: toolbarTextColor,
                                );
                              },
                            ),
                    ),
                    if (showChapterStep) ...[
                      const SizedBox(width: _toolbarIconGap),
                      _chapterStepButton(
                        context,
                        icon: Icons.chevron_right,
                        tooltip: '下一个目录项',
                        onPressed: canGoNextChapter
                            ? () => onGoToChapter(nextChapterTarget)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildToolbarGroup(
            children: [
              if (showSidebarToggle)
                _compactIconButton(
                  context,
                  icon: sidebarOpen
                      ? Icons.vertical_split
                      : Icons.vertical_split_outlined,
                  tooltip: sidebarOpen ? '收起侧栏' : '展开侧栏',
                  onPressed: onSidebarToggle,
                ),
              if (showSearch)
                _compactIconButton(
                  context,
                  icon: Icons.search,
                  tooltip: '搜索',
                  onPressed: onSearchTap,
                ),
              _buildFontSettingsButton(context, useDropdown: showSidebarToggle),
              _compactIconButton(
                context,
                icon: bookmarks.isCurrentPositionBookmarked()
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
                tooltip: '书签',
                onPressed: onBookmarkTap,
              ),
              FlowMenuButton<String>(
                alignmentOffset: const Offset(-140, 8),
                minWidth: 176,
                onSelected: (value) {
                  switch (value) {
                    case 'search':
                      onSearchTap();
                      break;
                    case 'prevChapter':
                      if (canGoPreviousChapter) {
                        onGoToChapter(previousChapterTarget);
                      }
                      break;
                    case 'nextChapter':
                      if (canGoNextChapter) {
                        onGoToChapter(nextChapterTarget);
                      }
                      break;
                    case 'bookmarks':
                      onBookmarkHistoryTap();
                      break;
                    case 'vocabulary':
                      onOpenVocabularyPanel();
                      break;
                    case 'training':
                      onStartChapterTraining();
                      break;
                    case 'stats':
                      onOpenStatsPanel();
                      break;
                    case 'chapterAI':
                      onOpenChapterAI();
                      break;
                  }
                },
                entries: [
                  if (!showSearch)
                    const FlowMenuItem(
                      value: 'search',
                      icon: Icons.search,
                      label: '搜索',
                    ),
                  if (!showSearch) const FlowMenuDivider(),
                  if (currentBook.hasBook && visibleNavigationCount > 1) ...[
                    FlowMenuItem(
                      value: 'prevChapter',
                      enabled: canGoPreviousChapter,
                      icon: Icons.keyboard_arrow_up,
                      label: '上一个目录项',
                    ),
                    FlowMenuItem(
                      value: 'nextChapter',
                      enabled: canGoNextChapter,
                      icon: Icons.keyboard_arrow_down,
                      label: '下一个目录项',
                    ),
                    const FlowMenuDivider(),
                  ],
                  const FlowMenuItem(
                    value: 'bookmarks',
                    icon: Icons.bookmarks_outlined,
                    label: '历史书签',
                  ),
                  const FlowMenuDivider(),
                  const FlowMenuItem(
                    value: 'vocabulary',
                    icon: Icons.text_fields_outlined,
                    label: '本章词汇',
                  ),
                  const FlowMenuItem(
                    value: 'training',
                    icon: Icons.fitness_center_outlined,
                    label: '本章训练',
                  ),
                  const FlowMenuItem(
                    value: 'stats',
                    icon: Icons.insights_outlined,
                    label: '阅读统计',
                  ),
                  const FlowMenuDivider(),
                  const FlowMenuItem(
                    value: 'chapterAI',
                    icon: Icons.auto_awesome_outlined,
                    label: '章节 AI',
                  ),
                ],
                builder: (context, isOpen, toggle) => _compactIconButton(
                  context,
                  icon: Icons.more_vert,
                  tooltip: '更多',
                  selected: isOpen,
                  onPressed: toggle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarGroup({required List<Widget> children}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, child) in children.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: index > 0 ? _toolbarIconGap : 0,
            ),
            child: child,
          ),
      ],
    );
  }

  Widget _buildTocButton(
    BuildContext context, {
    required bool useDropdown,
    required bool useWorkspacePanel,
  }) {
    if (!currentBook.hasBook || currentBook.chapterCount <= 1) {
      return const SizedBox.shrink();
    }

    if (useWorkspacePanel) {
      return _compactIconButton(
        context,
        key: const ValueKey('reader-toolbar-toc'),
        icon: Icons.menu,
        tooltip: '目录',
        selected: sidebarOpen,
        onPressed: onShowWorkspaceToc,
      );
    }

    if (!useDropdown) {
      return _compactIconButton(
        context,
        key: const ValueKey('reader-toolbar-toc'),
        icon: Icons.menu,
        tooltip: '目录',
        onPressed: onShowTocSheet,
      );
    }

    return MenuAnchor(
      controller: tocMenuController,
      onOpen: () => onTocMenuOpenChanged(true),
      onClose: () => onTocMenuOpenChanged(false),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        TocDropdownPanel(
          onClose: tocMenuController.close,
          onGoToChapter: onGoToChapter,
          onChapterSelected: (_) => tocMenuController.close(),
        ),
      ],
      child: _compactIconButton(
        context,
        key: const ValueKey('reader-toolbar-toc'),
        icon: Icons.menu,
        tooltip: '目录',
        selected: tocMenuOpen,
        onPressed: () => onTocMenuToggle(tocMenuController),
      ),
    );
  }

  Widget _buildFontSettingsButton(
    BuildContext context, {
    required bool useDropdown,
  }) {
    if (!useDropdown) {
      return _compactIconButton(
        context,
        icon: Icons.text_fields,
        tooltip: '字体',
        onPressed: onShowFontSettingsSheet,
      );
    }

    final panelWidth = FontSettingsDropdownPanel.preferredWidthFor(
      MediaQuery.sizeOf(context),
    );

    return MenuAnchor(
      controller: fontSettingsMenuController,
      onOpen: () => onFontSettingsMenuOpenChanged(true),
      onClose: () => onFontSettingsMenuOpenChanged(false),
      alignmentOffset: Offset(-(panelWidth - 32), 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        FontSettingsDropdownPanel(
          width: panelWidth,
          onClose: fontSettingsMenuController.close,
        ),
      ],
      builder: (context, controller, _) {
        return _compactIconButton(
          context,
          icon: Icons.text_fields,
          tooltip: '字体',
          selected: controller.isOpen,
          onPressed: () => onFontSettingsMenuToggle(controller),
        );
      },
    );
  }

  Widget _compactIconButton(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = 19,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final isDarkReader =
        _isDarkReadingTheme(config) || cityPreset?.phase == CityTimePhase.night;
    return IconButton(
      key: key,
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _toolbarButtonWidth,
        height: _toolbarButtonHeight,
      ),
      visualDensity: VisualDensity.compact,
      style: _toolbarIconButtonStyle(
        theme,
        selected: selected,
        darkReader: isDarkReader,
      ),
    );
  }

  Widget _chapterStepButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final isDarkReader =
        _isDarkReadingTheme(config) || cityPreset?.phase == CityTimePhase.night;
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _toolbarButtonWidth,
        height: _toolbarButtonHeight,
      ),
      visualDensity: VisualDensity.compact,
      style: _toolbarIconButtonStyle(theme, darkReader: isDarkReader).copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ButtonStyle _toolbarIconButtonStyle(
    ThemeData theme, {
    bool selected = false,
    bool darkReader = false,
  }) {
    final colorScheme = theme.colorScheme;
    final inactiveForeground = colorScheme.onSurfaceVariant;
    return ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.14);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: selected ? 0.16 : 0.08);
        }
        return selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return inactiveForeground.withValues(alpha: 0.38);
        }
        if (selected ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colorScheme.primary;
        }
        return inactiveForeground;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.10);
        }
        return Colors.transparent;
      }),
    );
  }
}

int? _tocStepTarget(
  List<ReaderTocItem> items,
  int selectedIndex,
  int currentChapter,
  int direction,
) {
  var index = selectedIndex + direction;
  while (index >= 0 && index < items.length) {
    final target = items[index].targetChapterIndex;
    if (target != currentChapter) return target;
    index += direction;
  }
  return null;
}

bool _isDarkReadingTheme(ReadingConfigState config) {
  return config.readingTheme == 'dark';
}
