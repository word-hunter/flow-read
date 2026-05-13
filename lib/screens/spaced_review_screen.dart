import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

class SpacedReviewScreen extends StatefulWidget {
  const SpacedReviewScreen({super.key});

  @override
  State<SpacedReviewScreen> createState() => _SpacedReviewScreenState();
}

class _SpacedReviewScreenState extends State<SpacedReviewScreen> {
  List<_FillBlank> _items = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _generateItems();
  }

  void _generateItems() {
    final provider = context.read<ReadingProvider>();
    final result = provider.result;
    if (result == null) return;

    final vocab = result.vocabulary;
    final text = result.passageText;

    _items = [];
    final rng = Random(AppConstants.quizSeed);
    final shuffled = List.of(vocab)..shuffle(rng);
    final count = min(shuffled.length, AppConstants.quizItemCount);

    for (int i = 0; i < count; i++) {
      final word = shuffled[i];
      final wordLower = word.word.toLowerCase();

      final regex = RegExp(
        r'\b' + RegExp.escape(word.word) + r'\b',
        caseSensitive: false,
      );
      final match = regex.firstMatch(text);
      if (match == null) continue;

      final start = max(0, match.start - 60);
      final end = min(text.length, match.end + 60);
      var contextText = text.substring(start, end).trim();
      if (start > 0) contextText = '...$contextText';
      if (end < text.length) contextText = '$contextText...';

      final blankContext = contextText.replaceFirst(
        RegExp(r'\b' + RegExp.escape(word.word) + r'\b', caseSensitive: false),
        '______',
      );

      final wrongOptions = shuffled
          .where((v) => v.word.toLowerCase() != wordLower)
          .take(3)
          .map((v) => v.word)
          .toList();

      _items.add(
        _FillBlank(
          word: word.word,
          context: contextText,
          blankSentence: blankContext,
          options: [word.word, ...wrongOptions]..shuffle(rng),
        ),
      );
    }

    for (final item in _items) {
      item.correctIndex = item.options.indexOf(item.word);
    }

    if (_items.isEmpty) return;
    setState(() {});
  }

  void _selectAnswer(int optionIndex) {
    if (_showResult) return;
    setState(() {
      _selectedAnswer = optionIndex;
      _showResult = true;
      if (optionIndex == _items[_currentIndex].correctIndex) _correctCount++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      setState(() => _allDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return _buildEmptyState();
    if (_allDone) return _buildDoneState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppConstants.layoutBreakpoint;
        final item = _items[_currentIndex];
        final accuracy = _currentIndex > 0
            ? (_correctCount * 100.0 / _currentIndex).round()
            : 100;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isWide
                  ? '间隔复习 · ${_currentIndex + 1} / ${_items.length}'
                  : '${_currentIndex + 1} of ${_items.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: isWide
              ? _buildWideBody(item, accuracy)
              : _buildNarrowBody(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: const Text('间隔复习')),
      body: Center(
        child: Text(
          '暂无复习内容',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneState() {
    final theme = Theme.of(context);
    final accuracy = _items.isNotEmpty
        ? (_correctCount * 100 / _items.length).round()
        : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('复习完成')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              Text(
                '复习完成!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '正确率: $accuracy% ($_correctCount / ${_items.length})',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回阅读'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowBody(_FillBlank item) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _currentIndex / _items.length,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildContextCard(theme, item.context),
          const SizedBox(height: 24),
          Text(
            item.blankSentence,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.8,
              fontFamily: 'Serif',
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          ..._buildOptionCards(theme, item),
          if (_showResult) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _nextQuestion,
                child: Text(_currentIndex < _items.length - 1 ? '下一题' : '完成'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWideBody(_FillBlank item, int accuracy) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 300, child: _buildSidebar(accuracy)),
        VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildContextCard(theme, item.context),
                    const SizedBox(height: 28),
                    Text(
                      item.blankSentence,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        height: 1.8,
                        fontFamily: 'Serif',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 36),
                    ..._buildOptionCards(
                      theme,
                      item,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Serif',
                        color: theme.colorScheme.onSurface,
                      ),
                      centered: true,
                    ),
                    if (_showResult) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 200,
                        child: FilledButton(
                          onPressed: _nextQuestion,
                          child: Text(
                            _currentIndex < _items.length - 1 ? '下一题' : '完成复习',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextCard(ThemeData theme, String context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        context,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  List<Widget> _buildOptionCards(
    ThemeData theme,
    _FillBlank item, {
    TextStyle? style,
    bool centered = false,
  }) {
    return List.generate(item.options.length, (index) {
      final isCorrect = index == item.correctIndex;
      final isSelectedWrong =
          _showResult && _selectedAnswer == index && !isCorrect;

      Color? bgColor;
      Color? borderColor;
      Widget? trailing;

      if (_showResult) {
        if (isCorrect) {
          bgColor = AppColors.correct.withValues(alpha: 0.1);
          borderColor = AppColors.correct.withValues(alpha: 0.4);
          trailing = Icon(Icons.check_circle, color: AppColors.correct);
        } else if (isSelectedWrong) {
          bgColor = AppColors.incorrect.withValues(alpha: 0.1);
          borderColor = AppColors.incorrect.withValues(alpha: 0.4);
          trailing = Icon(Icons.cancel, color: AppColors.incorrect);
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ReviewOption(
          text: item.options[index],
          theme: theme,
          bgColor: bgColor,
          borderColor:
              borderColor ??
              theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          trailing: trailing,
          onTap: _showResult ? null : () => _selectAnswer(index),
          style: style,
          centered: centered,
        ),
      );
    });
  }

  Widget _buildSidebar(int accuracy) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '复习队列',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_items.length, (index) {
            final isActive = index == _currentIndex;
            final isDone = index < _currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isDone
                          ? AppColors.correct
                          : isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _items[index].word,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'SRS 统计',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('当前正确率', '$accuracy%'),
          const SizedBox(height: 6),
          _buildStatRow('已复习', '$_currentIndex'),
          const SizedBox(height: 6),
          _buildStatRow('剩余', '${_items.length - _currentIndex}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _FillBlank {
  final String word;
  final String context;
  final String blankSentence;
  final List<String> options;
  late int correctIndex;

  _FillBlank({
    required this.word,
    required this.context,
    required this.blankSentence,
    required this.options,
  });
}

class _ReviewOption extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final Color? bgColor;
  final Color borderColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? style;
  final bool centered;

  const _ReviewOption({
    required this.text,
    required this.theme,
    this.bgColor,
    required this.borderColor,
    this.trailing,
    this.onTap,
    this.style,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bgColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: centered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                Text(
                  text,
                  style:
                      style ??
                      theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Serif',
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
