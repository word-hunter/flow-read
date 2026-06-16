import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/reading_memory.dart';
import '../providers/reading/services_provider.dart';
import 'flow/flow_components.dart';

class ReviewCandidateQueue extends riverpod.ConsumerStatefulWidget {
  const ReviewCandidateQueue({super.key, this.limit = 5});

  final int limit;

  @override
  riverpod.ConsumerState<ReviewCandidateQueue> createState() =>
      _ReviewCandidateQueueState();
}

class _ReviewCandidateQueueState
    extends riverpod.ConsumerState<ReviewCandidateQueue> {
  List<ReviewCandidate> _candidates = const [];
  Set<String> _busyIds = const {};
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final service = ref.read(reviewCandidateServiceProvider);
    final candidates = await service.pendingCandidates(limit: widget.limit);
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _isLoading = false;
    });
  }

  Future<void> _accept(ReviewCandidate candidate) async {
    await _withBusy(candidate.id, () {
      return ref
          .read(reviewCandidateServiceProvider)
          .acceptCandidate(
            candidate.id,
          );
    });
  }

  Future<void> _dismiss(ReviewCandidate candidate) async {
    await _withBusy(candidate.id, () {
      return ref
          .read(reviewCandidateServiceProvider)
          .dismissCandidate(
            candidate.id,
          );
    });
  }

  Future<void> _clearVisible() async {
    if (_candidates.isEmpty || _isClearing) return;
    setState(() => _isClearing = true);
    await ref
        .read(reviewCandidateServiceProvider)
        .dismissCandidates(_candidates.map((candidate) => candidate.id));
    if (!mounted) return;
    setState(() {
      _candidates = const [];
      _isClearing = false;
    });
  }

  Future<void> _withBusy(String id, Future<void> Function() action) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds = {..._busyIds, id});
    await action();
    if (!mounted) return;
    setState(() {
      _busyIds = _busyIds.where((value) => value != id).toSet();
      _candidates = _candidates
          .where((candidate) => candidate.id != id)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_candidates.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_alt_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '记忆候选',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FlowButton.text(
                onPressed: _isClearing ? null : _clearVisible,
                icon: const Icon(Icons.clear_all, size: 16),
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final candidate in _candidates)
            _ReviewCandidateTile(
              candidate: candidate,
              isBusy: _busyIds.contains(candidate.id),
              onAccept: () => _accept(candidate),
              onDismiss: () => _dismiss(candidate),
            ),
        ],
      ),
    );
  }
}

class _ReviewCandidateTile extends StatelessWidget {
  const _ReviewCandidateTile({
    required this.candidate,
    required this.isBusy,
    required this.onAccept,
    required this.onDismiss,
  });

  final ReviewCandidate candidate;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _candidateLabel(candidate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: '接受',
            child: IconButton.filledTonal(
              onPressed: isBusy ? null : onAccept,
              icon: const Icon(Icons.check, size: 18),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: '忽略',
            child: IconButton(
              onPressed: isBusy ? null : onDismiss,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _candidateLabel(ReviewCandidate candidate) {
    final type = switch (candidate.entityType) {
      KnowledgeEntityType.word => '单词',
      KnowledgeEntityType.phrase => '短语',
      KnowledgeEntityType.pattern => '句型',
      KnowledgeEntityType.grammar => '语法',
      KnowledgeEntityType.sentence => '句子',
      KnowledgeEntityType.bookTerm => '作品术语',
      KnowledgeEntityType.concept => '概念',
      KnowledgeEntityType.character => '人物',
    };
    final questionType = candidate.suggestedQuestionType?.trim();
    if (questionType == null || questionType.isEmpty) return type;
    return '$type · $questionType';
  }
}
