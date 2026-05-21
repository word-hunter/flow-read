import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../services/settings_service.dart';

class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  static const _trainingTypes = [
    _TrainingType(
      icon: Icons.translate,
      title: 'Vocabulary',
      description: 'Practice words from current chapter',
      color: Color(0xFF2979FF),
      route: '/practice',
    ),
    _TrainingType(
      icon: Icons.account_tree,
      title: 'Syntax',
      description: 'Analyze sentence structures',
      color: Color(0xFF7B1FA2),
      route: '/syntax',
    ),
    _TrainingType(
      icon: Icons.psychology,
      title: 'Comprehension',
      description: 'Test reading understanding',
      color: Color(0xFFE67E22),
      route: '/review',
    ),
    _TrainingType(
      icon: Icons.replay,
      title: 'Spaced Review',
      description: 'Review learned vocabulary',
      color: Color(0xFF27AE60),
      route: '/spaced_review',
      requiresReviewFeature: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(child: _buildTrainingGrid(context, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Select Training Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingGrid(BuildContext context, ThemeData theme) {
    final settings = context.watch<SettingsService>();
    final visibleTypes = _trainingTypes
        .where(
          (type) =>
              !type.requiresReviewFeature || settings.reviewFeatureEnabled,
        )
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: visibleTypes
            .map((type) => _buildTrainingCard(context, type, theme))
            .toList(),
      ),
    );
  }

  Widget _buildTrainingCard(
    BuildContext context,
    _TrainingType type,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => _navigateToTraining(context, type),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: type.color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const Spacer(),
            Text(
              type.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTraining(BuildContext context, _TrainingType type) {
    final provider = context.read<ReadingProvider>();
    if (type.requiresReviewFeature &&
        !context.read<SettingsService>().reviewFeatureEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先在设置中开启轻量复习测试功能')));
      return;
    }
    if (!provider.hasBook && !provider.hasBeenOpened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please load a book first')));
      return;
    }
    Navigator.pushNamed(context, type.route);
  }
}

class _TrainingType {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;
  final bool requiresReviewFeature;

  const _TrainingType({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
    this.requiresReviewFeature = false,
  });
}
