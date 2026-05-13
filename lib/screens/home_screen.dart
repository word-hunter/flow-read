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

    if (provider.isReading && provider.hasBook) {
      return const ReadingDeskScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.wideBreakpoint) {
          return _WideHomeLayout(provider: provider);
        }
        return _buildNarrowLayout(context, provider);
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context, ReadingProvider provider) {
    return Scaffold(
      body: IndexedStack(index: provider.currentTab, children: _narrowPanels),
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.currentTab,
        onDestinationSelected: provider.switchTab,
        destinations: _navDestinations,
      ),
    );
  }
}

class _WideHomeLayout extends StatelessWidget {
  final ReadingProvider provider;

  const _WideHomeLayout({required this.provider});

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
          ),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: IndexedStack(
              index: provider.currentTab,
              children: _widePanels,
            ),
          ),
        ],
      ),
    );
  }
}
