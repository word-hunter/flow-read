import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/learning_item.dart';
import '../providers/reading/services_provider.dart';
import '../services/review_schedule_service.dart';
import 'package:flow_design_system/flow_design_system.dart';
import '../theme/app_constants.dart';
import '../widgets/flow/flow_components.dart';

class SpacedReviewScreen extends riverpod.ConsumerStatefulWidget {
  const SpacedReviewScreen({super.key});

  @override
  riverpod.ConsumerState<SpacedReviewScreen> createState() =>
      _SpacedReviewScreenState();
}

class _SpacedReviewScreenState
    extends riverpod.ConsumerState<SpacedReviewScreen> {
  late final List<LearningReviewCard> _cards;
  final TextEditingController _answerController = TextEditingController();
  int _currentIndex = 0;
  int _rememberedCount = 0;
  int _masteredCount = 0;
  int _needsReviewCount = 0;
  String? _selectedOption;
  bool _showAnswer = false;
  bool _allDone = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cards = ref.read(reviewScheduleServiceProvider).buildSessionCards();
    _answerController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _answerController
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!_showAnswer && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return _buildEmptyState();
    if (_allDone) return _buildDoneState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppConstants.layoutBreakpoint;
        final card = _cards[_currentIndex];
        return Scaffold(
          appBar: _ReviewAppBar(
            title: Text(
              '今日测验 · ${_currentIndex + 1} / ${_cards.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onClose: () => Navigator.pop(context),
          ),
          body: isWide ? _buildWideBody(card) : _buildNarrowBody(card),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _ReviewAppBar(
        title: const Text('今日测验'),
        onClose: () => Navigator.pop(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无今日复习',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查词、AI 解析和章节错题会按复习间隔出现在这里。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FlowButton.primary(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneState() {
    final theme = Theme.of(context);
    final accuracy = _cards.isEmpty
        ? 0
        : (_rememberedCount * 100 / _cards.length).round();
    return Scaffold(
      appBar: _ReviewAppBar(
        title: const Text('测验完成'),
        onClose: () => Navigator.pop(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 18),
              Text(
                '测验完成',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '记住 $accuracy% ($_rememberedCount / ${_cards.length})',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  _DonePill(label: '掌握', value: _masteredCount),
                  _DonePill(label: '需复习', value: _needsReviewCount),
                ],
              ),
              const SizedBox(height: 26),
              FlowButton.primary(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回单词本'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideBody(LearningReviewCard card) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 280, child: _buildQueue(theme)),
        VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: SizedBox(width: 620, child: _buildReviewCard(card)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowBody(LearningReviewCard card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildReviewCard(card),
    );
  }

  Widget _buildQueue(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        final isActive = index == _currentIndex;
        final isDone = index < _currentIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.32)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle : _typeIcon(card.type),
                  size: 17,
                  color: isDone
                      ? FunctionalColors.correct
                      : isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
      },
    );
  }

  Widget _buildReviewCard(LearningReviewCard card) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeChip(theme, card.type),
            const SizedBox(height: 18),
            _buildStudyGoal(theme, card),
            const SizedBox(height: 18),
            _buildPrompt(theme, card),
            if (!_showAnswer) ...[
              const SizedBox(height: 16),
              _buildInput(theme, card),
            ],
            if (_showAnswer) ...[
              const SizedBox(height: 20),
              _buildAnswer(theme, card),
              if (card.sourceText.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSource(theme, card.sourceText),
              ],
            ],
            const SizedBox(height: 24),
            _buildActions(card),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, LearningReviewCardType type) {
    final color = type == LearningReviewCardType.questionMistake
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            type.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGoal(ThemeData theme, LearningReviewCard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.school_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '学习点',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.studyGoal,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(ThemeData theme, LearningReviewCard card) {
    final title = switch (card.type) {
      LearningReviewCardType.contextMeaning => '语境选义',
      LearningReviewCardType.fillBlank => '补全原句',
      LearningReviewCardType.meaningToWord => '看中文选英文',
      LearningReviewCardType.questionMistake => '回顾错题',
    };
    final isFillBlank = card.type == LearningReviewCardType.fillBlank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          card.prompt,
          style:
              (isFillBlank
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    fontFamily: isFillBlank ? 'Serif' : null,
                    height: isFillBlank ? 1.65 : 1.35,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
        ),
      ],
    );
  }

  Widget _buildInput(ThemeData theme, LearningReviewCard card) {
    if (card.options.isNotEmpty) {
      return _buildOptions(theme, card);
    }

    final maxLines = card.type == LearningReviewCardType.questionMistake
        ? 3
        : 1;
    final hintText = switch (card.type) {
      LearningReviewCardType.contextMeaning => '输入你回忆出的含义',
      LearningReviewCardType.fillBlank => '输入空缺处的原文',
      LearningReviewCardType.meaningToWord => '输入对应的英文单词',
      LearningReviewCardType.questionMistake => '输入你现在的答案',
    };

    return FlowTextField(
      controller: _answerController,
      maxLines: maxLines,
      minLines: 1,
      textInputAction: maxLines == 1
          ? TextInputAction.done
          : TextInputAction.newline,
      onSubmitted: maxLines == 1 && _answerController.text.trim().isNotEmpty
          ? (_) => _revealAnswer()
          : null,
      decoration: InputDecoration(
        labelText: '你的答案',
        hintText: hintText,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.24,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildOptions(ThemeData theme, LearningReviewCard card) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in card.options)
          ChoiceChip(
            label: Text(option),
            selected: _selectedOption == option,
            onSelected: _isSaving
                ? null
                : (selected) {
                    setState(() {
                      _selectedOption = selected ? option : null;
                    });
                  },
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _selectedOption == option
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
            selectedColor: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _selectedOption == option
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSource(ThemeData theme, String source) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '原文依据',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            source,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer(ThemeData theme, LearningReviewCard card) {
    final explanation = card.explanation.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '答案',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.answer,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (card.options.isNotEmpty && _selectedOption != null) ...[
            const SizedBox(height: 10),
            Text(
              '你的选择：$_selectedOption',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.78,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '说明',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.86,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.78,
                ),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(LearningReviewCard card) {
    if (!_showAnswer) {
      final canSubmit = card.options.isNotEmpty
          ? _selectedOption != null
          : _answerController.text.trim().isNotEmpty;
      return Row(
        children: [
          Expanded(
            child: FlowButton.secondary(
              onPressed: _isSaving ? null : _revealAnswer,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              child: const Text('看答案'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FlowButton.primary(
              onPressed: _isSaving || !canSubmit ? null : _revealAnswer,
              icon: const Icon(Icons.check, size: 18),
              child: const Text('提交'),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 560
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _FeedbackButton(
              width: itemWidth,
              label: '忘记',
              icon: Icons.replay,
              onPressed: _isSaving
                  ? null
                  : () => _finishCard(LearningReviewResult.forgotten),
            ),
            _FeedbackButton(
              width: itemWidth,
              label: '模糊',
              icon: Icons.blur_on_outlined,
              onPressed: _isSaving
                  ? null
                  : () => _finishCard(LearningReviewResult.vague),
            ),
            _FeedbackButton(
              width: itemWidth,
              label: '记得',
              icon: Icons.check,
              primary: true,
              onPressed: _isSaving
                  ? null
                  : () => _finishCard(LearningReviewResult.remembered),
            ),
            _FeedbackButton(
              width: itemWidth,
              label: '掌握',
              icon: Icons.verified_outlined,
              primary: true,
              onPressed: _isSaving
                  ? null
                  : () => _finishCard(LearningReviewResult.mastered),
            ),
          ],
        );
      },
    );
  }

  void _revealAnswer() {
    if (_showAnswer) return;
    setState(() => _showAnswer = true);
  }

  IconData _typeIcon(LearningReviewCardType type) {
    return switch (type) {
      LearningReviewCardType.contextMeaning => Icons.travel_explore_outlined,
      LearningReviewCardType.fillBlank => Icons.short_text,
      LearningReviewCardType.meaningToWord => Icons.translate_outlined,
      LearningReviewCardType.questionMistake => Icons.quiz_outlined,
    };
  }

  Future<void> _finishCard(LearningReviewResult result) async {
    if (_isSaving) return;
    final card = _cards[_currentIndex];
    setState(() => _isSaving = true);
    await ref
        .read(reviewScheduleServiceProvider)
        .recordReview(
          card.item.id,
          result,
        );
    if (!mounted) return;
    _answerController.clear();
    setState(() {
      if (result.isSuccessful) _rememberedCount++;
      if (result == LearningReviewResult.mastered) _masteredCount++;
      if (!result.isSuccessful) _needsReviewCount++;
      _isSaving = false;
      _showAnswer = false;
      _selectedOption = null;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      } else {
        _allDone = true;
      }
    });
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.width,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final double width;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final button = primary
        ? FlowButton.primary(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            child: Text(label),
          )
        : FlowButton.secondary(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            child: Text(label),
          );
    return SizedBox(width: width, child: button);
  }
}

class _DonePill extends StatelessWidget {
  const _DonePill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback onClose;

  const _ReviewAppBar({required this.title, required this.onClose});

  static double get _topInset => AppConstants.immersiveTitleBarTopInset;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + _topInset);

  @override
  Widget build(BuildContext context) {
    return FlowToolbar(
      height: preferredSize.height,
      leading: Padding(
        padding: EdgeInsets.only(top: _topInset),
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          tooltip: '关闭',
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(top: _topInset),
        child: title,
      ),
    );
  }
}
