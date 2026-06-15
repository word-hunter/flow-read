import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import '../providers/reading/bookshelf_notifier.dart';
import '../providers/reading/current_book_notifier.dart';
import '../providers/reading/reading_time_notifier.dart';
import '../providers/settings_provider.dart';
import '../theme/app_constants.dart';
import '../theme/city_theme_tokens.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/bookshelf_content.dart';
import '../widgets/flow/flow_components.dart';
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
      icon: Icon(Icons.text_fields_outlined),
      selectedIcon: Icon(Icons.text_fields),
      label: '词汇',
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

class _WideHomeLayout extends riverpod.ConsumerWidget {
  final CurrentBookNotifier currentBook;
  final CurrentBookState currentBookState;
  final bool showRss;

  const _WideHomeLayout({
    required this.currentBook,
    required this.currentBookState,
    required this.showRss,
  });

  static const _widePanels = <Widget>[
    BookshelfContent(),
    RssScreen(),
    SizedBox.shrink(),
    VocabularyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final theme = Theme.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final cityTokens = Theme.of(context).extension<CityThemeTokens>();
    final readingTime = ref.watch(readingTimeNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final visibleTabs = HomeScreen._visibleTabs(showRss: showRss);
    HomeScreen._redirectHiddenTab(
      context,
      currentBook,
      currentBookState,
      visibleTabs,
    );
    final selectedIndex = HomeScreen._visibleIndexFor(
      currentBookState.currentTab,
      visibleTabs,
    );

    final backgroundColor = HomeScreen._homeBackgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: ColoredBox(
        color: backgroundColor,
        child: Row(
          children: [
            HomeSidebar(
              currentTab: currentBookState.currentTab,
              onTabChanged: currentBook.switchTab,
              readingTimeSeconds: readingTime.weekReadingTimeSeconds,
              monthReadingTimeSeconds: readingTime.monthReadingTimeSeconds,
              weekDailyReadingSeconds: readingTime.weekDailyReadingSeconds,
              monthDailyReadingSeconds: readingTime.monthDailyReadingSeconds,
              goalDate: readingTime.readingGoalDate,
              dailyReadingGoalSeconds: readingTime.dailyReadingGoalSeconds,
              onSettingsTap: () =>
                  Navigator.pushNamed(context, SettingsScreen.routeName),
              onThemeToggle: () =>
                  runThemeTransition(context, settings.toggleThemeMode),
              nextThemeMode: settings.nextThemeMode,
              showRss: showRss,
            ),
            VerticalDivider(
              width: 1,
              color:
                  cityTokens?.warmBorder ??
                  cityPreset?.outline.withValues(alpha: 0.70) ??
                  theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: ColoredBox(
                color: backgroundColor,
                child: IndexedStack(
                  index: selectedIndex,
                  children: HomeScreen._visibleWidgets(
                    _widePanels,
                    visibleTabs,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
