import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../providers/reading/bookshelf_notifier.dart';
import '../providers/reading/current_book_notifier.dart';
import '../providers/reading/reading_time_notifier.dart';
import '../providers/settings_provider.dart';
import '../theme/app_constants.dart';
import '../theme/city_theme_tokens.dart';
import '../widgets/home/book_import_flow.dart';
import '../widgets/home/bookshelf_content.dart';
import '../widgets/home/reading_stats_ring.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/theme_mode_cycle_button.dart';
import '../widgets/theme_transition.dart';
import 'bookshelf_screen.dart';
import 'rss_screen.dart';
import 'vocabulary_screen.dart';
import 'profile_screen.dart';
import 'reading_desk_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends riverpod.ConsumerWidget {
  const HomeScreen({super.key});

  static const _bookshelfTabIndex = 0;
  static const _rssTabIndex = 1;
  static const _vocabularyTabIndex = 3;
  static const _profileTabIndex = 4;
  static const _allTabIndexes = <int>[
    _bookshelfTabIndex,
    _rssTabIndex,
    _vocabularyTabIndex,
    _profileTabIndex,
  ];

  static const _navDestinations = [
    FlowSidebarDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: '书架',
    ),
    FlowSidebarDestination(
      icon: Icon(Icons.rss_feed_outlined),
      selectedIcon: Icon(Icons.rss_feed),
      label: 'RSS',
    ),
    FlowSidebarDestination(icon: SizedBox.shrink(), label: ''),
    FlowSidebarDestination(
      icon: Icon(Icons.collections_bookmark_outlined),
      selectedIcon: Icon(Icons.collections_bookmark),
      label: '单词本',
    ),
    FlowSidebarDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  static const _narrowPanels = <Widget>[
    BookshelfScreen(),
    RssScreen(),
    SizedBox.shrink(),
    VocabularyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);

    Widget content;
    if (currentBookState.isReading && currentBookNotifier.hasBook) {
      content = const ReadingDeskScreen();
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
            return _WideHomeLayout(
              currentBook: currentBookNotifier,
              currentBookState: currentBookState,
              showRss: settings.rssFeatureEnabled,
            );
          }
          return _buildNarrowLayout(
            context,
            currentBookNotifier,
            showRss: settings.rssFeatureEnabled,
            currentBookState: currentBookState,
          );
        },
      );
    }

    return _ImportProgressHost(child: content);
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    CurrentBookNotifier currentBook, {
    required bool showRss,
    CurrentBookState currentBookState = const CurrentBookState(),
  }) {
    final visibleTabs = _visibleTabs(showRss: showRss);
    _redirectHiddenTab(context, currentBook, currentBookState, visibleTabs);
    final selectedIndex = _visibleIndexFor(
      currentBookState.currentTab,
      visibleTabs,
    );
    final backgroundColor = _homeBackgroundColor(context);

    final body = IndexedStack(
      index: selectedIndex,
      children: _visibleWidgets(_narrowPanels, visibleTabs),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ColoredBox(color: backgroundColor, child: body),
      bottomNavigationBar: FlowSidebar.bottom(
        backgroundColor: backgroundColor,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            currentBook.switchTab(visibleTabs[index]),
        destinations: _visibleWidgets(_navDestinations, visibleTabs),
      ),
    );
  }

  static Color _homeBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<CityThemeTokens>()?.shellSurface ??
        theme.colorScheme.surface;
  }

  static List<int> _visibleTabs({required bool showRss}) {
    return _allTabIndexes
        .where((tabIndex) => showRss || tabIndex != _rssTabIndex)
        .toList(growable: false);
  }

  static int _visibleIndexFor(int currentTab, List<int> visibleTabs) {
    final index = visibleTabs.indexOf(currentTab);
    return index == -1 ? 0 : index;
  }

  static List<T> _visibleWidgets<T>(List<T> widgets, List<int> visibleTabs) {
    return [for (final tabIndex in visibleTabs) widgets[tabIndex]];
  }

  static void _redirectHiddenTab(
    BuildContext context,
    CurrentBookNotifier currentBook,
    CurrentBookState currentBookState,
    List<int> visibleTabs,
  ) {
    if (visibleTabs.contains(currentBookState.currentTab)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted ||
          visibleTabs.contains(currentBookState.currentTab)) {
        return;
      }
      currentBook.switchTab(visibleTabs.first);
    });
  }
}

class _ImportProgressHost extends riverpod.ConsumerWidget {
  const _ImportProgressHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final importProgressNotifier = ref
        .read(bookshelfNotifierProvider.notifier)
        .importProgressNotifier;

    return _ImportProgressOverlayHost(
      importProgressNotifier: importProgressNotifier,
      onCancel: () =>
          ref.read(bookshelfNotifierProvider.notifier).cancelImport(),
      child: child,
    );
  }
}

class _ImportProgressOverlayHost extends StatefulWidget {
  const _ImportProgressOverlayHost({
    required this.importProgressNotifier,
    required this.onCancel,
    required this.child,
  });

  static const _completionHold = Duration(milliseconds: 650);

  final ValueListenable<ImportProgressState> importProgressNotifier;
  final VoidCallback onCancel;
  final Widget child;

  @override
  State<_ImportProgressOverlayHost> createState() =>
      _ImportProgressOverlayHostState();
}

class _ImportProgressOverlayHostState
    extends State<_ImportProgressOverlayHost> {
  late final ValueNotifier<ImportProgressState> _displayState;
  Timer? _hideTimer;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _displayState = ValueNotifier<ImportProgressState>(
      widget.importProgressNotifier.value,
    );
    _visible = _displayState.value.isImportingBook;
    widget.importProgressNotifier.addListener(_handleImportStateChanged);
  }

  @override
  void didUpdateWidget(_ImportProgressOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.importProgressNotifier == widget.importProgressNotifier) {
      return;
    }
    oldWidget.importProgressNotifier.removeListener(_handleImportStateChanged);
    _hideTimer?.cancel();
    _displayState.value = widget.importProgressNotifier.value;
    _visible = _displayState.value.isImportingBook;
    widget.importProgressNotifier.addListener(_handleImportStateChanged);
  }

  @override
  void dispose() {
    widget.importProgressNotifier.removeListener(_handleImportStateChanged);
    _hideTimer?.cancel();
    _displayState.dispose();
    super.dispose();
  }

  void _handleImportStateChanged() {
    final next = widget.importProgressNotifier.value;
    if (next.isImportingBook) {
      _hideTimer?.cancel();
      _displayState.value = next;
      if (!_visible && mounted) {
        setState(() => _visible = true);
      }
      return;
    }

    final previous = _displayState.value;
    final completed = (previous.progress ?? 0) >= 1.0;
    if (completed) {
      _hideTimer?.cancel();
      _hideTimer = Timer(_ImportProgressOverlayHost._completionHold, () {
        if (!mounted) return;
        _displayState.value = ImportProgressState.idle;
        setState(() => _visible = false);
      });
      return;
    }

    _hideTimer?.cancel();
    _displayState.value = ImportProgressState.idle;
    if (_visible && mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;

    return _ImportProgressOverlay(
      importProgressListenable: _displayState,
      onCancel: widget.onCancel,
      child: widget.child,
    );
  }
}

class _ImportProgressOverlay extends StatelessWidget {
  const _ImportProgressOverlay({
    required this.importProgressListenable,
    required this.onCancel,
    required this.child,
  });

  final ValueListenable<ImportProgressState> importProgressListenable;
  final VoidCallback onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AbsorbPointer(
            child: ColoredBox(
              color: colorScheme.scrim.withValues(alpha: 0.34),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _ImportProgressPanel(
                  importProgressListenable: importProgressListenable,
                  onCancel: onCancel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportProgressPanel extends StatelessWidget {
  const _ImportProgressPanel({
    required this.importProgressListenable,
    required this.onCancel,
  });

  static const _stageTextHeight = 44.0;
  static const _cancelActionHeight = 40.0;

  final ValueListenable<ImportProgressState> importProgressListenable;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<ImportProgressState>(
      valueListenable: importProgressListenable,
      builder: (context, importState, _) {
        final progress = importState.progress;
        final progressLabel = progress == null
            ? null
            : '${(progress * 100).clamp(0, 100).round()}%';
        final stageStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );
        final showCancelAction =
            importState.canCancelImport || importState.isCancellingImport;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '正在导入 EPUB',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (progressLabel != null)
                  Text(
                    progressLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (importState.fileName != null) ...[
              const SizedBox(height: 8),
              Text(
                importState.fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _AnimatedImportProgressBar(progress: progress),
            const SizedBox(height: 12),
            SizedBox(
              height: _stageTextHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  importState.stage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: stageStyle,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: _cancelActionHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: showCancelAction
                    ? FlowButton.secondary(
                        onPressed: importState.isCancellingImport
                            ? null
                            : onCancel,
                        icon: const Icon(Icons.close, size: 18),
                        child: Text(
                          importState.isCancellingImport ? '正在取消...' : '取消导入',
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedImportProgressBar extends StatefulWidget {
  const _AnimatedImportProgressBar({required this.progress});

  final double? progress;

  @override
  State<_AnimatedImportProgressBar> createState() =>
      _AnimatedImportProgressBarState();
}

class _AnimatedImportProgressBarState extends State<_AnimatedImportProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final initialValue = _normalizedProgress(widget.progress) ?? 0.0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _animation = AlwaysStoppedAnimation<double>(initialValue);
  }

  @override
  void didUpdateWidget(_AnimatedImportProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _normalizedProgress(widget.progress);
    if (target == null) return;
    final current = _animation.value;
    if ((current - target).abs() < 0.001) return;
    _controller.stop();
    _controller.reset();
    _animation = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _normalizedProgress(double? progress) {
    return progress?.clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.progress;
    if (value == null) {
      return const LinearProgressIndicator(minHeight: 6);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) =>
          LinearProgressIndicator(value: _animation.value, minHeight: 6),
    );
  }
}

class _WideHomeLayout extends riverpod.ConsumerStatefulWidget {
  final CurrentBookNotifier currentBook;
  final CurrentBookState currentBookState;
  final bool showRss;

  const _WideHomeLayout({
    required this.currentBook,
    required this.currentBookState,
    required this.showRss,
  });

  @override
  riverpod.ConsumerState<_WideHomeLayout> createState() =>
      _WideHomeLayoutState();
}

class _WideHomeLayoutState extends riverpod.ConsumerState<_WideHomeLayout> {
  final TextEditingController _bookshelfSearchController =
      TextEditingController();
  Timer? _bookshelfSearchDebounce;
  String _bookshelfSearchQuery = '';

  @override
  void dispose() {
    _bookshelfSearchDebounce?.cancel();
    _bookshelfSearchController.dispose();
    super.dispose();
  }

  void _onBookshelfSearchChanged(String value) {
    _bookshelfSearchDebounce?.cancel();
    _bookshelfSearchDebounce = Timer(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() => _bookshelfSearchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingTime = ref.watch(readingTimeNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final bookshelfState = ref.watch(bookshelfNotifierProvider);
    final visibleTabs = HomeScreen._visibleTabs(showRss: widget.showRss);
    HomeScreen._redirectHiddenTab(
      context,
      widget.currentBook,
      widget.currentBookState,
      visibleTabs,
    );
    final selectedIndex = HomeScreen._visibleIndexFor(
      widget.currentBookState.currentTab,
      visibleTabs,
    );
    final selectedTab = visibleTabs[selectedIndex];

    final backgroundColor = HomeScreen._homeBackgroundColor(context);
    final panels = <Widget>[
      BookshelfContent(
        showTopControls: false,
        externalSearchQuery: _bookshelfSearchQuery,
        readingGoalCard: _HomeReadingGoalCard(
          readingTimeSeconds: readingTime.weekReadingTimeSeconds,
          monthReadingTimeSeconds: readingTime.monthReadingTimeSeconds,
          weekDailyReadingSeconds: readingTime.weekDailyReadingSeconds,
          monthDailyReadingSeconds: readingTime.monthDailyReadingSeconds,
          goalDate: readingTime.readingGoalDate,
          dailyReadingGoalSeconds: readingTime.dailyReadingGoalSeconds,
        ),
      ),
      const RssScreen(),
      const SizedBox.shrink(),
      const VocabularyScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _HomeTopBar(
            visibleTabs: visibleTabs,
            selectedTab: selectedTab,
            onTabChanged: widget.currentBook.switchTab,
            showBookshelfControls: selectedTab == HomeScreen._bookshelfTabIndex,
            searchController: _bookshelfSearchController,
            onSearchChanged: _onBookshelfSearchChanged,
            isImportingBook: bookshelfState.isLoading,
            onImportEpub: () => importEpubFromPicker(
              context,
              ref.read(bookshelfNotifierProvider.notifier),
            ),
            onSettingsTap: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
            onThemeToggle: () =>
                runThemeTransition(context, settings.toggleThemeMode),
            nextThemeMode: settings.nextThemeMode,
          ),
          Expanded(
            child: ColoredBox(
              color: backgroundColor,
              child: IndexedStack(
                index: selectedIndex,
                children: HomeScreen._visibleWidgets(panels, visibleTabs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final List<int> visibleTabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final bool showBookshelfControls;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isImportingBook;
  final VoidCallback onImportEpub;
  final VoidCallback onSettingsTap;
  final VoidCallback onThemeToggle;
  final ThemeMode nextThemeMode;

  const _HomeTopBar({
    required this.visibleTabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.showBookshelfControls,
    required this.searchController,
    required this.onSearchChanged,
    required this.isImportingBook,
    required this.onImportEpub,
    required this.onSettingsTap,
    required this.onThemeToggle,
    required this.nextThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = theme.extension<CityThemeTokens>();
    final background =
        city?.shellSurface.withValues(alpha: 0.96) ?? theme.colorScheme.surface;
    final borderColor = city?.warmBorder ?? theme.colorScheme.outlineVariant;
    final iconColor = city?.textSecondary ?? theme.colorScheme.onSurfaceVariant;
    final topInset = math.max(0.0, AppConstants.immersiveTitleBarTopInset - 8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SizedBox(
        height: topInset + 70,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showSearch =
                  showBookshelfControls && constraints.maxWidth >= 980;
              final searchWidth = math.min(
                560.0,
                math.max(300.0, constraints.maxWidth * 0.34),
              );

              return Row(
                children: [
                  const SizedBox(width: 28),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final tabIndex in visibleTabs)
                              _HomeTopNavTab(
                                tabIndex: tabIndex,
                                selected: tabIndex == selectedTab,
                                onTap: () => onTabChanged(tabIndex),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showBookshelfControls) ...[
                    const SizedBox(width: 18),
                    if (showSearch) ...[
                      SizedBox(
                        width: searchWidth,
                        child: _HomeTopSearchField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    FlowButton.primary(
                      onPressed: isImportingBook ? null : onImportEpub,
                      icon: const Icon(Icons.add, size: 18),
                      child: Text(isImportingBook ? '导入中' : '添加书籍'),
                    ),
                  ],
                  const SizedBox(width: 20),
                  IconButton(
                    tooltip: '设置',
                    icon: const Icon(Icons.settings_outlined),
                    color: iconColor,
                    onPressed: onSettingsTap,
                  ),
                  ThemeModeCycleButton(
                    nextMode: nextThemeMode,
                    color: iconColor,
                    onPressed: onThemeToggle,
                  ),
                  const SizedBox(width: 28),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeTopNavTab extends StatelessWidget {
  final int tabIndex;
  final bool selected;
  final VoidCallback onTap;

  const _HomeTopNavTab({
    required this.tabIndex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = theme.extension<CityThemeTokens>();
    final destination = HomeScreen._navDestinations[tabIndex];
    final foreground = selected
        ? city?.activeBlue ?? theme.colorScheme.primary
        : city?.textSecondary ?? theme.colorScheme.onSurfaceVariant;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: foreground,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
    );
    final icon = selected && destination.selectedIcon != null
        ? destination.selectedIcon!
        : destination.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: SizedBox(
          height: 70,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme.merge(
                        data: IconThemeData(size: 20, color: foreground),
                        child: icon,
                      ),
                      const SizedBox(width: 8),
                      Text(destination.label, style: textStyle),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 72 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected
                        ? city?.activeBlue ?? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
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

class _HomeTopSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _HomeTopSearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = theme.extension<CityThemeTokens>();
    final borderColor = city?.warmBorder ?? theme.colorScheme.outlineVariant;

    return SizedBox(
      height: 42,
      child: FlowTextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '搜索书籍或作者',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: city?.textSecondary ?? theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: city?.textSecondary),
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: city?.activeBlue ?? theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
          filled: true,
          fillColor: city?.cardSurface ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: city?.textPrimary ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _HomeReadingGoalCard extends StatefulWidget {
  final int readingTimeSeconds;
  final int monthReadingTimeSeconds;
  final List<int> weekDailyReadingSeconds;
  final List<int> monthDailyReadingSeconds;
  final DateTime? goalDate;
  final int dailyReadingGoalSeconds;

  const _HomeReadingGoalCard({
    required this.readingTimeSeconds,
    required this.monthReadingTimeSeconds,
    required this.weekDailyReadingSeconds,
    required this.monthDailyReadingSeconds,
    required this.goalDate,
    required this.dailyReadingGoalSeconds,
  });

  @override
  State<_HomeReadingGoalCard> createState() => _HomeReadingGoalCardState();
}

class _HomeReadingGoalCardState extends State<_HomeReadingGoalCard> {
  final _readingGoalKey = GlobalKey();
  OverlayEntry? _readingGoalOverlay;

  @override
  void dispose() {
    _readingGoalOverlay?.remove();
    _readingGoalOverlay = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeReadingGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readingGoalOverlay?.markNeedsBuild();
  }

  void _toggleReadingGoalPanel() {
    if (_readingGoalOverlay == null) {
      _showReadingGoalPanel();
    } else {
      _hideReadingGoalPanel();
    }
  }

  void _showReadingGoalPanel() {
    final overlay = Overlay.of(context);
    final box =
        _readingGoalKey.currentContext?.findRenderObject() as RenderBox?;
    final cardOffset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final cardWidth = box?.size.width ?? 290;

    _readingGoalOverlay = OverlayEntry(
      builder: (context) {
        final mediaSize = MediaQuery.sizeOf(context);
        final panelWidth = math
            .min(480.0, math.max(360.0, mediaSize.width - 48))
            .toDouble();
        const preferredPanelHeight = 700.0;
        final maxLeft = math.max(16.0, mediaSize.width - panelWidth - 16);
        final left = math
            .min(
              math.max(16.0, cardOffset.dx + cardWidth - panelWidth),
              maxLeft,
            )
            .toDouble();
        final maxTop = math.max(
          16.0,
          mediaSize.height - preferredPanelHeight - 16,
        );
        final top = math.min(math.max(cardOffset.dy, 16.0), maxTop).toDouble();

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideReadingGoalPanel,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: panelWidth,
                child: ReadingGoalDetailsPanel(
                  weekTotalSeconds: widget.readingTimeSeconds,
                  monthTotalSeconds: widget.monthReadingTimeSeconds,
                  weekDailySeconds: widget.weekDailyReadingSeconds,
                  monthDailySeconds: widget.monthDailyReadingSeconds,
                  dailyGoalSeconds: widget.dailyReadingGoalSeconds,
                  goalDate: widget.goalDate ?? DateTime.now(),
                  onClose: _hideReadingGoalPanel,
                  showPointer: false,
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_readingGoalOverlay!);
    setState(() {});
  }

  void _hideReadingGoalPanel() {
    _readingGoalOverlay?.remove();
    _readingGoalOverlay = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ReadingGoalSummaryCard(
      key: _readingGoalKey,
      totalSeconds: widget.readingTimeSeconds,
      dailyGoalSeconds: widget.dailyReadingGoalSeconds,
      isExpanded: _readingGoalOverlay != null,
      onTap: _toggleReadingGoalPanel,
    );
  }
}
