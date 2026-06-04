import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import '../providers/reading/current_book_provider.dart';
import '../providers/reading/reading_time_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/bookshelf_content.dart';
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
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: '书架',
    ),
    NavigationDestination(
      icon: Icon(Icons.rss_feed_outlined),
      selectedIcon: Icon(Icons.rss_feed),
      label: 'RSS',
    ),
    NavigationDestination(icon: SizedBox.shrink(), label: ''),
    NavigationDestination(
      icon: Icon(Icons.text_fields_outlined),
      selectedIcon: Icon(Icons.text_fields),
      label: '词汇',
    ),
    NavigationDestination(
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
    final currentBook = ref.watch(currentBookProvider);
    final settings = context.watch<SettingsService>();

    if (currentBook.isReading && currentBook.hasBook) {
      return const ReadingDeskScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
          return _WideHomeLayout(
            currentBook: currentBook,
            showRss: settings.rssFeatureEnabled,
          );
        }
        return _buildNarrowLayout(
          context,
          currentBook,
          showRss: settings.rssFeatureEnabled,
        );
      },
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    CurrentBookController currentBook, {
    required bool showRss,
  }) {
    final visibleTabs = _visibleTabs(showRss: showRss);
    _redirectHiddenTab(context, currentBook, visibleTabs);
    final selectedIndex = _visibleIndexFor(currentBook.currentTab, visibleTabs);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _visibleWidgets(_narrowPanels, visibleTabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            currentBook.switchTab(visibleTabs[index]),
        destinations: _visibleWidgets(_navDestinations, visibleTabs),
      ),
    );
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
    CurrentBookController currentBook,
    List<int> visibleTabs,
  ) {
    if (visibleTabs.contains(currentBook.currentTab)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || visibleTabs.contains(currentBook.currentTab)) {
        return;
      }
      currentBook.switchTab(visibleTabs.first);
    });
  }
}

class _WideHomeLayout extends riverpod.ConsumerWidget {
  final CurrentBookController currentBook;
  final bool showRss;

  const _WideHomeLayout({required this.currentBook, required this.showRss});

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
    final readingTime = ref.watch(readingTimeProvider);
    final settings = context.watch<SettingsService>();
    final visibleTabs = HomeScreen._visibleTabs(showRss: showRss);
    HomeScreen._redirectHiddenTab(context, currentBook, visibleTabs);
    final selectedIndex = HomeScreen._visibleIndexFor(
      currentBook.currentTab,
      visibleTabs,
    );

    return Scaffold(
      body: Row(
        children: [
          HomeSidebar(
            currentTab: currentBook.currentTab,
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
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: HomeScreen._visibleWidgets(_widePanels, visibleTabs),
            ),
          ),
        ],
      ),
    );
  }
}
