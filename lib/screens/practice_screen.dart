import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../providers/reading/current_book_notifier.dart';
import '../theme/app_constants.dart';
import '../theme/app_surface_tokens.dart';
import '../widgets/practice_card.dart';

class PracticeScreen extends riverpod.ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final result = currentBookState.result;
    final tokens = AppSurfaceTokens.of(context);

    if (result == null) {
      return Scaffold(
        backgroundColor: tokens.readerWorkspaceBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chapterTitle = result.title;

    return Scaffold(
      backgroundColor: tokens.readerWorkspaceBackground,
      body: ColoredBox(
        color: tokens.readerWorkspaceBackground,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= AppConstants.wideBreakpoint
                  ? 980.0
                  : 760.0;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12 + AppConstants.immersiveTitleBarTopInset,
                      16,
                      32 + bottomPadding,
                    ),
                    children: [
                      _PracticeTopBar(
                        chapterTitle: chapterTitle,
                        questionCount: result.practice.length,
                      ),
                      const SizedBox(height: 20),
                      if (result.practice.isEmpty)
                        const _EmptyPracticeState()
                      else ...[
                        _PracticeOverview(
                          chapterTitle: chapterTitle,
                          questionCount: result.practice.length,
                          vocabularyCount: result.vocabulary.length,
                          syntaxCount: result.syntaxPatterns.length,
                        ),
                        const SizedBox(height: 18),
                        for (
                          var index = 0;
                          index < result.practice.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == result.practice.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: PracticeCard(
                              practice: result.practice[index],
                              index: index,
                              total: result.practice.length,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PracticeTopBar extends StatelessWidget {
  const _PracticeTopBar({
    required this.chapterTitle,
    required this.questionCount,
  });

  final String chapterTitle;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: '返回',
          child: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本章词汇练习',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                chapterTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            '$questionCount 道练习',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PracticeOverview extends StatelessWidget {
  const _PracticeOverview({
    required this.chapterTitle,
    required this.questionCount,
    required this.vocabularyCount,
    required this.syntaxCount,
  });

  final String chapterTitle;
  final int questionCount;
  final int vocabularyCount;
  final int syntaxCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '围绕当前章节的关键词、句法和理解线索完成练习。',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '先根据原文摘录作答，再展开参考思路。这样能保留练习感，也不会把关键信息藏在答案区里。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OverviewPill(
                  icon: Icons.fitness_center_outlined,
                  text: '$questionCount 道题',
                ),
                _OverviewPill(
                  icon: Icons.translate_outlined,
                  text: '$vocabularyCount 个重点词',
                ),
                _OverviewPill(
                  icon: Icons.account_tree_outlined,
                  text: '$syntaxCount 个句法点',
                ),
                _OverviewPill(
                  icon: Icons.menu_book_outlined,
                  text: chapterTitle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPracticeState extends StatelessWidget {
  const _EmptyPracticeState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            '本章暂时没有可用练习',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可以先继续阅读或重新分析本章，等关键词和句法点生成后再回来练习。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
