import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_practice_questions.dart';
import '../models/review_question.dart';
import '../providers/reading_provider.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final result = provider.result;
    if (result == null) return const Center(child: CircularProgressIndicator());

    final chapterTitle =
        provider.book?.chapters[provider.currentChapter].title ?? result.title;

    final aiPractice = provider.aiPractice;

    if (provider.isGeneratingPractice) {
      return Scaffold(
        appBar: AppBar(title: const Text('正在生成练习题...')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI 正在生成练习题，请稍候...'),
            ],
          ),
        ),
      );
    }

    if (aiPractice != null && aiPractice.questions.isNotEmpty) {
      return _AIReview(
        chapterTitle: chapterTitle,
        questions: aiPractice.questions,
      );
    }

    final questions = ReviewService.generateQuestions(result);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.layoutBreakpoint) {
          return _WideReview(chapterTitle: chapterTitle, questions: questions);
        }
        return _NarrowReview(chapterTitle: chapterTitle, questions: questions);
      },
    );
  }
}

class _NarrowReview extends StatelessWidget {
  final String chapterTitle;
  final List<ReviewQuestion> questions;

  const _NarrowReview({required this.chapterTitle, required this.questions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '章节回顾',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              chapterTitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          return _QuestionCard(
            question: q.question,
            hint: q.hint,
            index: index,
            isCompleted: q.isCompleted,
          );
        },
      ),
    );
  }
}

class _WideReview extends StatelessWidget {
  final String chapterTitle;
  final List<ReviewQuestion> questions;

  const _WideReview({required this.chapterTitle, required this.questions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$chapterTitle — 回顾',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 380,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: q.isCompleted
                          ? AppColors.correct.withValues(alpha: 0.15)
                          : theme.colorScheme.primaryContainer,
                      child: Icon(
                        q.isCompleted
                            ? Icons.check
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: q.isCompleted
                            ? AppColors.correct
                            : theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      q.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: q.isCompleted
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: q.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 560,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '选择左侧问题，在此处作答',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '基于原文内容回答，练习阅读理解与推理能力',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: '在此输入你的回答...',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.mic,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {},
                          ),
                          FilledButton(
                            onPressed: () {},
                            child: const Text('提交'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final String question;
  final String hint;
  final int index;
  final bool isCompleted;

  const _QuestionCard({
    required this.question,
    required this.hint,
    required this.index,
    required this.isCompleted,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _controller = TextEditingController();
  bool _showFeedback = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isCompleted
              ? AppColors.correct.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q${widget.index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (widget.isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.correct.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: AppColors.correct),
                        const SizedBox(width: 4),
                        Text(
                          'Based on the text',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.correct,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.question,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入你的回答...',
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showFeedback = !_showFeedback),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '提示',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (_showFeedback) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AIReview extends StatefulWidget {
  final String chapterTitle;
  final List<PracticeQuestion> questions;

  const _AIReview({required this.chapterTitle, required this.questions});

  @override
  State<_AIReview> createState() => _AIReviewState();
}

class _AIReviewState extends State<_AIReview> {
  final Map<int, int?> _selectedAnswers = {};
  final Map<int, bool> _showAnswers = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 练习题',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              widget.chapterTitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ReadingProvider>().generatePractice();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重新生成'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          return _buildAICard(q, index, theme);
        },
      ),
    );
  }

  Widget _buildAICard(PracticeQuestion q, int index, ThemeData theme) {
    final selected = _selectedAnswers[index];
    final showAnswer = _showAnswers[index] ?? false;
    final isCorrect =
        selected != null && q.distractors[selected].text == q.answer;

    final typeIcons = {
      'detail': Icons.info_outline,
      'vocabulary': Icons.menu_book,
      'inference': Icons.psychology,
      'grammar': Icons.code,
    };
    final typeLabels = {
      'detail': '细节',
      'vocabulary': '词汇',
      'inference': '推理',
      'grammar': '语法',
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: showAnswer
              ? (isCorrect ? AppColors.correct : AppColors.familiarityLow)
                    .withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        typeIcons[q.type] ?? Icons.quiz,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        typeLabels[q.type] ?? q.type,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: q.difficulty == 'easy'
                        ? Colors.green.withValues(alpha: 0.1)
                        : q.difficulty == 'hard'
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.difficulty,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: q.difficulty == 'easy'
                          ? Colors.green
                          : q.difficulty == 'hard'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q.question,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              final isDistractor = i < q.distractors.length;
              final text = isDistractor ? q.distractors[i].text : '';
              if (!isDistractor) return const SizedBox.shrink();

              final isSelected = selected == i;
              final showResult = showAnswer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: showAnswer
                      ? null
                      : () => setState(() => _selectedAnswers[index] = i),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: showResult
                          ? (text == q.answer
                                ? AppColors.correct.withValues(alpha: 0.1)
                                : isSelected
                                ? AppColors.familiarityLow.withValues(
                                    alpha: 0.1,
                                  )
                                : null)
                          : (isSelected
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: showResult
                            ? (text == q.answer
                                  ? AppColors.correct
                                  : isSelected
                                  ? AppColors.familiarityLow
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ))
                            : (isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.1,
                                    )),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: showResult && text == q.answer
                                  ? AppColors.correct
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 2,
                            ),
                            color: showResult && text == q.answer
                                ? AppColors.correct
                                : null,
                          ),
                          child: showResult && text == q.answer
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: isSelected && !showResult
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (!showAnswer) ...[
              const SizedBox(height: 8),
              Center(
                child: FilledButton.icon(
                  onPressed: selected != null
                      ? () => setState(() => _showAnswers[index] = true)
                      : null,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('提交'),
                ),
              ),
            ],
            if (showAnswer) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.correct.withValues(alpha: 0.08)
                      : AppColors.familiarityLow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? '回答正确' : '回答错误',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? AppColors.correct
                            : AppColors.familiarityLow,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text(
                        '正确答案: ${q.answer}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.correct,
                        ),
                      ),
                    ],
                    if (q.answerExplanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        q.answerExplanation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (selected != null && !isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        q.distractors[selected].whyWrong,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.familiarityLow.withValues(
                            alpha: 0.8,
                          ),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
