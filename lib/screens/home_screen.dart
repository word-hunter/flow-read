import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_constants.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/bookshelf_content.dart';
import 'bookshelf_screen.dart';
import 'rss_screen.dart';
import 'vocabulary_screen.dart';
import 'profile_screen.dart';
import 'reading_desk_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bookshelfTabIndex = 0;
  static const _rssTabIndex = 1;
  static const _vocabularyTabIndex = 2;
  static const _profileTabIndex = 3;
  static const _allTabIndexes = <int>[
    _bookshelfTabIndex,
    _rssTabIndex,
    _vocabularyTabIndex,
    _profileTabIndex,
  ];
  static const _tabIndexesWithoutRss = <int>[
    _bookshelfTabIndex,
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
    VocabularyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();

    if (provider.isReading && provider.hasBook) {
      return const ReadingDeskScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
          return _WideHomeLayout(
            provider: provider,
            showRss: settings.rssFeatureEnabled,
          );
        }
        return _buildNarrowLayout(
          context,
          provider,
          showRss: settings.rssFeatureEnabled,
        );
      },
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    ReadingProvider provider, {
    required bool showRss,
  }) {
    final visibleTabs = _visibleTabs(showRss);
    _redirectHiddenTab(context, provider, visibleTabs);
    final selectedIndex = _visibleIndexFor(provider.currentTab, visibleTabs);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _visibleWidgets(_narrowPanels, visibleTabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            provider.switchTab(visibleTabs[index]),
        destinations: _visibleWidgets(_navDestinations, visibleTabs),
      ),
    );
  }

  static List<int> _visibleTabs(bool showRss) {
    return showRss ? _allTabIndexes : _tabIndexesWithoutRss;
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
    ReadingProvider provider,
    List<int> visibleTabs,
  ) {
    if (visibleTabs.contains(provider.currentTab)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || visibleTabs.contains(provider.currentTab)) return;
      provider.switchTab(visibleTabs.first);
    });
  }
}

class _WideHomeLayout extends StatelessWidget {
  final ReadingProvider provider;
  final bool showRss;

  const _WideHomeLayout({required this.provider, required this.showRss});

  static const _widePanels = <Widget>[
    BookshelfContent(),
    RssScreen(),
    VocabularyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final visibleTabs = HomeScreen._visibleTabs(showRss);
    HomeScreen._redirectHiddenTab(context, provider, visibleTabs);
    final selectedIndex = HomeScreen._visibleIndexFor(
      provider.currentTab,
      visibleTabs,
    );

    return Scaffold(
      body: Row(
        children: [
          HomeSidebar(
            currentTab: provider.currentTab,
            onTabChanged: provider.switchTab,
            readingTimeSeconds: provider.readingTimeSeconds,
            onSettingsTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onThemeToggle: () => settings.toggleThemeMode(),
            isDarkMode: theme.brightness == Brightness.dark,
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
