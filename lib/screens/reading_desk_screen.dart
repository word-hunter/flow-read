import 'package:flutter/material.dart';
import '../pages/reader_page.dart';
import '../pages/vocab_page.dart';
import '../pages/training_page.dart';
import '../pages/stats_page.dart';
import '../theme/app_constants.dart';

class ReadingDeskScreen extends StatefulWidget {
  const ReadingDeskScreen({super.key});

  @override
  State<ReadingDeskScreen> createState() => _ReadingDeskScreenState();
}

class _ReadingDeskScreenState extends State<ReadingDeskScreen> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    ReaderPage(),
    VocabPage(),
    TrainingPage(),
    StatsPage(),
  ];

  static const _navDestinations = [
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: '阅读',
    ),
    NavigationDestination(
      icon: Icon(Icons.translate_outlined),
      selectedIcon: Icon(Icons.translate),
      label: '词汇',
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: '训练',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: '统计',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            8 + AppConstants.immersiveTitleBarTopInset,
            8,
            8,
          ),
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            );
          }),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: theme.scaffoldBackgroundColor,
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            );
          }),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: _navDestinations,
        ),
      ),
    );
  }
}
