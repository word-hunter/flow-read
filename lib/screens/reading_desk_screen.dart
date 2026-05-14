import 'package:flutter/material.dart';
import '../pages/reader_page.dart';
import '../pages/vocab_page.dart';
import '../pages/training_page.dart';
import '../pages/stats_page.dart';

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
      label: 'Reader',
    ),
    NavigationDestination(
      icon: Icon(Icons.translate_outlined),
      selectedIcon: Icon(Icons.translate),
      label: 'Vocab',
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: 'Training',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Stats',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _navDestinations,
      ),
    );
  }
}
