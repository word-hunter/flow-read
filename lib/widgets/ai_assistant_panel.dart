import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flow_ai/flow_ai.dart';
class AIAssistantPanel extends HookWidget {
  const AIAssistantPanel({
    super.key,
    required this.controller,
    this.embedded = false,
    this.onClose,
  });

  final AIAssistantController controller;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    useListenable(controller);
    final snapshot = controller.currentContext;
    if (snapshot == null) {
      return _EmptyPanel(embedded: embedded, onClose: onClose);
    }
    return _ActivePanel(
      controller: controller,
      snapshot: snapshot,
      embedded: embedded,
      onClose: onClose,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.embedded, this.onClose});

  final bool embedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: embedded ? 360 : null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                '选中文字或点击单词开始分析',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              if (onClose != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onClose,
                  child: const Text('关闭'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.controller,
    required this.snapshot,
    required this.embedded,
    this.onClose,
  });

  final AIAssistantController controller;
  final AIContextSnapshot snapshot;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final actionController = controller.actionController;
    final availableActions = controller.availableActions;

    return SizedBox(
      width: embedded ? 360 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(snapshot: snapshot, embedded: embedded, onClose: onClose),
          const Divider(height: 1),
          _ContextCard(snapshot: snapshot),
          if (availableActions.isNotEmpty) ...[
            const Divider(height: 1),
            _ActionStrip(
              availableActions: availableActions,
              busyAction: actionController.isBusy
                  ? actionController.currentAction
                  : null,
              onAction: (action) => controller.executeAction(action),
            ),
          ],
          const Divider(height: 1),
          Expanded(
            child: _ResultArea(
              actionController: actionController,
              onRetry: () => actionController.retry(),
            ),
          ),
          const Divider(height: 1),
          _FollowUpInput(
            busy: actionController.isBusy,
            onSubmit: (question) {
              if (actionController.currentAction != null) {
                controller.executeAction(
                  actionController.currentAction!,
                  followUpQuestion: question,
                );
              }
            },
          ),
          _ScopeIndicator(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.snapshot,
    required this.embedded,
    this.onClose,
  });

  final AIContextSnapshot snapshot;
  final bool embedded;
  final VoidCallback? onClose;

  String get _sourceLabel {
    switch (snapshot.source) {
      case AIContextSource.readerSelectedText:
        return '选中文本';
      case AIContextSource.readerParagraph:
        return '当前段落';
      case AIContextSource.readerWord:
        return '单词分析';
      case AIContextSource.readerChapter:
        return '章节分析';
      case AIContextSource.rssArticle:
        return '文章分析';
      case AIContextSource.internalWeb:
        return '页面分析';
    }
  }

  IconData get _sourceIcon {
    switch (snapshot.source) {
      case AIContextSource.readerSelectedText:
        return Icons.text_fields;
      case AIContextSource.readerParagraph:
        return Icons.format_align_left;
      case AIContextSource.readerWord:
        return Icons.spellcheck;
      case AIContextSource.readerChapter:
        return Icons.menu_book;
      case AIContextSource.rssArticle:
        return Icons.article;
      case AIContextSource.internalWeb:
        return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(_sourceIcon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            _sourceLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.snapshot});

  final AIContextSnapshot snapshot;

  String get _preview {
    final parts = <String>[];
    if (snapshot.word != null) {
      parts.add(snapshot.word!);
      if (snapshot.wordSentence != null) {
        parts.add(snapshot.wordSentence!);
      }
    } else if (snapshot.selectedText != null) {
      parts.add(snapshot.selectedText!);
    } else if (snapshot.chapterTitle != null) {
      parts.add(snapshot.chapterTitle!);
    } else if (snapshot.articleTitle != null) {
      parts.add(snapshot.articleTitle!);
    }
    return parts.join('\n');
  }

  int get _maxLines => snapshot.word != null ? 3 : 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    if (preview.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (snapshot.bookId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (snapshot.chapterTitle != null)
                    Flexible(
                      child: Text(
                        snapshot.chapterTitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    snapshot.sourceLanguage.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            preview,
            style: theme.textTheme.bodySmall,
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.availableActions,
    required this.onAction,
    this.busyAction,
  });

  final List<AIAssistantActionType> availableActions;
  final AIAssistantActionType? busyAction;
  final ValueChanged<AIAssistantActionType> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: availableActions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final action = availableActions[index];
          final isActive = busyAction == action;
          return ActionChip(
            label: Text(_actionLabel(action)),
            avatar: isActive
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : Icon(_actionIcon(action), size: 16),
            onPressed: busyAction != null ? null : () => onAction(action),
          );
        },
      ),
    );
  }

  static String _actionLabel(AIAssistantActionType action) {
    switch (action) {
      case AIAssistantActionType.explain:
        return '解释';
      case AIAssistantActionType.translate:
        return '翻译';
      case AIAssistantActionType.phraseExtraction:
        return '短语';
      case AIAssistantActionType.pronounReference:
        return '指代';
      case AIAssistantActionType.questionGeneration:
        return '出题';
      case AIAssistantActionType.summary:
        return '总结';
      case AIAssistantActionType.wordAnalysis:
        return '词汇';
      case AIAssistantActionType.articleQA:
        return '问答';
    }
  }

  static IconData _actionIcon(AIAssistantActionType action) {
    switch (action) {
      case AIAssistantActionType.explain:
        return Icons.lightbulb_outline;
      case AIAssistantActionType.translate:
        return Icons.translate;
      case AIAssistantActionType.phraseExtraction:
        return Icons.short_text;
      case AIAssistantActionType.pronounReference:
        return Icons.link;
      case AIAssistantActionType.questionGeneration:
        return Icons.quiz_outlined;
      case AIAssistantActionType.summary:
        return Icons.summarize_outlined;
      case AIAssistantActionType.wordAnalysis:
        return Icons.spellcheck_outlined;
      case AIAssistantActionType.articleQA:
        return Icons.chat_outlined;
    }
  }
}

class _ResultArea extends HookWidget {
  const _ResultArea({
    required this.actionController,
    this.onRetry,
  });

  final AIActionController actionController;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    useListenable(actionController);

    if (actionController.isBusy) {
      final stream = actionController.stream;
      if (stream != null) {
        return _buildStreaming(context, stream);
      }
      return _buildLoading(context);
    }
    final result = actionController.lastResult;
    if (result == null) {
      return _buildIdle(context);
    }
    if (result is AIErrorResult) {
      return _buildError(context, result);
    }
    return _buildResult(context, result);
  }

  Widget _buildStreaming(BuildContext context, Stream<String> stream) {
    final chunks = useState(<String>[]);

    useEffect(() {
      final subscription = stream.listen((chunk) {
        chunks.value = [...chunks.value, chunk];
      });
      return subscription.cancel;
    }, [stream]);

    final theme = Theme.of(context);
    final text = chunks.value.join();
    if (text.isEmpty) {
      return _buildLoading(context);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _actionLabel(actionController.currentAction),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _actionLabel(actionController.currentAction),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdle(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '选择一个操作开始',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, AIErrorResult error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isRetryable && onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AIActionResult result) {
    if (result is AIStreamingProgress) {
      return _BuildStreamingResult(chunk: result.chunk, progress: result.progress);
    }
    if (result is AISummaryResult) {
      return _SummaryView(summary: result.summary);
    }
    if (result is AIWordAnalysisResult) {
      return _WordAnalysisView(analysis: result.analysis);
    }
    if (result is AITranslateResult) {
      return _TranslateView(translation: result.translation);
    }
    if (result is AIExplainResult) {
      return _ExplainView(explanation: result.explanation);
    }
    if (result is AIPhraseExtractionResult) {
      return _PhraseView(phrases: result.phrases);
    }
    if (result is AIQuestionGenerationResult) {
      return _QuestionView(questions: result.questions);
    }
    if (result is AIArticleQAResult) {
      return _ArticleQAView(answer: result.answer);
    }
    return const SizedBox.shrink();
  }

  static String _actionLabel(AIAssistantActionType? action) {
    switch (action) {
      case AIAssistantActionType.explain:
        return '正在分析...';
      case AIAssistantActionType.translate:
        return '正在翻译...';
      case AIAssistantActionType.phraseExtraction:
        return '正在提取短语...';
      case AIAssistantActionType.pronounReference:
        return '正在分析指代...';
      case AIAssistantActionType.questionGeneration:
        return '正在生成题目...';
      case AIAssistantActionType.summary:
        return '正在生成总结...';
      case AIAssistantActionType.wordAnalysis:
        return '正在分析词汇...';
      case AIAssistantActionType.articleQA:
        return '正在生成回答...';
      case null:
        return '处理中...';
    }
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final AISummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.events.isNotEmpty) ...[
            Text('事件', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...summary.events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (e.significance.isNotEmpty)
                      Text(e.significance, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (summary.characterDevelopments.isNotEmpty) ...[
            Text('角色发展', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...summary.characterDevelopments.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.character,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (c.change.isNotEmpty)
                      Text(c.change, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (summary.keyVocabulary.isNotEmpty) ...[
            Text('关键词汇', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...summary.keyVocabulary.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v.word} ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    Expanded(
                      child: Text(v.meaningInContext,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (summary.readingGuidance.isNotEmpty) ...[
            Text('阅读指导', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(summary.readingGuidance, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _WordAnalysisView extends StatelessWidget {
  const _WordAnalysisView({required this.analysis});

  final WordAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysis.pronunciation.isNotEmpty) ...[
            Text('发音', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(analysis.pronunciation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
          if (analysis.meanings.isNotEmpty) ...[
            Text('释义', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ...analysis.meanings.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.meaning,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (m.explanation.isNotEmpty)
                      Text(m.explanation, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (analysis.usageTips.isNotEmpty) ...[
            Text('用法提示', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ...analysis.usageTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(tip, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (analysis.memoryTip.isNotEmpty) ...[
            Text('记忆技巧', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(analysis.memoryTip, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _TranslateView extends StatelessWidget {
  const _TranslateView({required this.translation});

  final String translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(translation, style: theme.textTheme.bodyMedium),
    );
  }
}

class _ExplainView extends StatelessWidget {
  const _ExplainView({required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(explanation, style: theme.textTheme.bodyMedium),
    );
  }
}

class _PhraseView extends StatelessWidget {
  const _PhraseView({required this.phrases});

  final List<AIExtractedPhrase> phrases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: phrases.length,
      separatorBuilder: (_, _) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phrase.phrase,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(phrase.explanation, style: theme.textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.questions});

  final List<AIGeneratedQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final question = questions[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ${question.question}',
                style: theme.textTheme.bodyMedium),
            if (question.answer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('答案: ${question.answer}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _ArticleQAView extends StatelessWidget {
  const _ArticleQAView({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(answer, style: theme.textTheme.bodyMedium),
    );
  }
}

class _FollowUpInput extends HookWidget {
  const _FollowUpInput({required this.busy, this.onSubmit});

  final bool busy;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final hasText = useState(false);

    useEffect(() {
      void listener() {
        final next = controller.text.trim().isNotEmpty;
        if (next != hasText.value) {
          hasText.value = next;
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void submit() {
      final text = controller.text.trim();
      if (text.isEmpty || busy) return;
      onSubmit?.call(text);
      controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !busy,
              decoration: const InputDecoration(
                hintText: '追问...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => submit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            onPressed: busy || !hasText.value ? null : submit,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ScopeIndicator extends StatelessWidget {
  const _ScopeIndicator({required this.snapshot});

  final AIContextSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langLabel = '${snapshot.sourceLanguage.toUpperCase()} → '
        '${snapshot.outputLanguage.toUpperCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            langLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildStreamingResult extends StatelessWidget {
  const _BuildStreamingResult({required this.chunk, required this.progress});

  final String chunk;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Text(chunk, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
