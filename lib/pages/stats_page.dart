import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../widgets/reading_desk/donut_chart_painter.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _selectedPeriod = 'This Week';

  static const _periods = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final theme = Theme.of(context);
    final userVocab = provider.userVocabulary;
    final allVocab = provider.getAllVocabulary();

    final knownCount = userVocab?.knownWords.length ?? 0;
    final learningCount = userVocab?.learningWords.length ?? 0;
    final newCount = allVocab.where((v) => provider.getWordStatus(v.word) == null).length;
    final total = knownCount + learningCount + newCount;

    final donutSegments = <DonutSegment>[];
    if (knownCount > 0) donutSegments.add(DonutSegment(label: 'Mastered', value: knownCount.toDouble(), color: const Color(0xFF2979FF)));
    if (learningCount > 0) donutSegments.add(DonutSegment(label: 'Learning', value: learningCount.toDouble(), color: const Color(0xFF66BB6A)));
    if (newCount > 0) donutSegments.add(DonutSegment(label: 'New', value: newCount.toDouble(), color: const Color(0xFFFFCA28)));

    if (donutSegments.isEmpty) {
      donutSegments.addAll([
        const DonutSegment(label: 'Mastered', value: 0.0, color: Color(0xFF2979FF)),
        const DonutSegment(label: 'Learning', value: 0.0, color: Color(0xFF66BB6A)),
        const DonutSegment(label: 'New', value: 1.0, color: Color(0xFFFFCA28)),
      ]);
    }

    final centerPercent = total > 0 ? (knownCount * 100 / total).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(child: _buildContent(knownCount, learningCount, newCount, total, donutSegments, centerPercent, provider, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
      child: Row(children: [
        Icon(Icons.bar_chart, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('Learning Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.onSurfaceVariant),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
              items: _periods.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedPeriod = value);
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent(int knownCount, int learningCount, int newCount, int total,
      List<DonutSegment> segments, int centerPercent, ReadingProvider provider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _buildDonutChart(knownCount, learningCount, newCount, total, segments, centerPercent, theme),
        const SizedBox(height: 16),
        _buildStatGrid(knownCount, provider, theme),
      ]),
    );
  }

  Widget _buildDonutChart(int knownCount, int learningCount, int newCount, int total,
      List<DonutSegment> segments, int centerPercent, ThemeData theme) {
    final legendItems = [
      _LegendItem(label: 'Mastered', color: const Color(0xFF2979FF), value: total > 0 ? '${(knownCount * 100 / total).round()}%' : '0%'),
      _LegendItem(label: 'Learning', color: const Color(0xFF66BB6A), value: total > 0 ? '${(learningCount * 100 / total).round()}%' : '0%'),
      _LegendItem(label: 'New', color: const Color(0xFFFFCA28), value: total > 0 ? '${(newCount * 100 / total).round()}%' : '0%'),
    ];

    return SizedBox(
      height: 160,
      child: Row(children: [
        Expanded(
          flex: 3,
          child: CustomPaint(
            painter: DonutChartPainter(
              segments: segments,
              strokeWidth: 18,
              centerValue: '$centerPercent%',
              centerLabel: 'Mastered',
              centerValueColor: theme.colorScheme.onSurface,
              centerLabelColor: theme.colorScheme.onSurfaceVariant,
            ),
            size: const Size(160, 160),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item.label,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))),
                    Text(item.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  ]),
                )).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatGrid(int knownCount, ReadingProvider provider, ThemeData theme) {
    final bookmarkCount = provider.bookmarkedWords.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _StatItem(
          icon: Icons.menu_book,
          label: 'Words Mastered',
          value: '$knownCount',
          color: const Color(0xFF2979FF),
        ).build(context, theme),
        _StatItem(
          icon: Icons.school,
          label: 'Total Vocabulary',
          value: '${provider.totalVocabularyCount}',
          color: const Color(0xFF7B1FA2),
        ).build(context, theme),
        _StatItem(
          icon: Icons.bookmark,
          label: 'Bookmarks',
          value: '$bookmarkCount',
          color: const Color(0xFF27AE60),
        ).build(context, theme),
        _StatItem(
          icon: Icons.menu_book_outlined,
          label: 'Chapters',
          value: '${provider.chapterCount}',
          color: const Color(0xFFE67E22),
        ).build(context, theme),
      ],
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final String value;
  const _LegendItem({required this.label, required this.color, required this.value});
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  Widget build(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
