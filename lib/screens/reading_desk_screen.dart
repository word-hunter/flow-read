import 'package:flow_read_atmosphere/flow_read_atmosphere.dart';
import 'package:flutter/material.dart';

import '../pages/reader_page.dart';
import '../pages/stats_page.dart';
import '../pages/training_page.dart';
import '../pages/vocab_page.dart';
import '../widgets/flow/flow_components.dart';

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
  static const double _contentTopGap = 24;

  static const _navDestinations = [
    FlowSidebarDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: '阅读',
    ),
    FlowSidebarDestination(
      icon: Icon(Icons.translate_outlined),
      selectedIcon: Icon(Icons.translate),
      label: '词汇',
    ),
    FlowSidebarDestination(
      icon: Icon(Icons.fitness_center_outlined),
      selectedIcon: Icon(Icons.fitness_center),
      label: '训练',
    ),
    FlowSidebarDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: '统计',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityPreset = CityThemeScope.maybeOf(context)?.preset;
    final navigationBackground =
        cityPreset?.surface.withValues(alpha: 0.94) ??
        theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: cityPreset == null
          ? theme.scaffoldBackgroundColor
          : Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, _contentTopGap, 8, 8),
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: FlowSidebar.bottom(
        backgroundColor: navigationBackground,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _navDestinations,
      ),
    );
  }
}
