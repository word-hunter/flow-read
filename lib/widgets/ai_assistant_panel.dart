import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flow_ai/flow_ai.dart';
import 'flow/flow_components.dart';

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
    final child = snapshot == null
        ? _EmptyPanel(embedded: embedded, onClose: onClose)
        : _ActivePanel(
            controller: controller,
            snapshot: snapshot,
            embedded: embedded,
            onClose: onClose,
          );
    return Material(
      type: MaterialType.transparency,
      child: child,
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
              Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
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
                FlowButton.text(
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

class _ActivePanel extends HookWidget {
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
    useListenable(actionController);
    final availableActions = controller.availableActions;
    final showActionStrip = _shouldShowActionStrip(availableActions);
    final session = controller.currentSession;

    return SizedBox(
      width: embedded ? 360 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SessionToolbar(
            controller: controller,
            embedded: embedded,
            onClose: onClose,
          ),
          const Divider(height: 1),
          _ContextCard(controller: controller, snapshot: snapshot),
          if (showActionStrip) ...[
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
            child: _ConversationArea(
              session: session,
              actionController: actionController,
              snapshot: snapshot,
              onRetry: () => actionController.retry(),
            ),
          ),
          _QuickQuestionStrip(
            busy: actionController.isBusy,
            onSubmit: (question) => controller.executeAction(
              AIAssistantActionType.chat,
              followUpQuestion: question,
            ),
          ),
          const Divider(height: 1),
          _FollowUpInput(
            busy: actionController.isBusy,
            scope: snapshot.scope,
            onScopeChanged: controller.setScope,
            onSubmit: (question) {
              controller.executeAction(
                AIAssistantActionType.chat,
                followUpQuestion: question,
              );
            },
          ),
          _ScopeIndicator(snapshot: snapshot),
        ],
      ),
    );
  }

  bool _shouldShowActionStrip(List<AIAssistantActionType> actions) {
    if (actions.isEmpty) return false;
    return !(actions.length == 1 &&
        actions.single == AIAssistantActionType.explain);
  }
}

class _SessionToolbar extends StatelessWidget {
  const _SessionToolbar({
    required this.controller,
    required this.embedded,
    this.onClose,
  });

  final AIAssistantController controller;
  final bool embedded;
  final VoidCallback? onClose;

  AIContextSnapshot? get snapshot => controller.currentContext;

  String get _sourceLabel {
    switch (snapshot?.source) {
      case AIContextSource.readerSelectedText:
      case AIContextSource.readerParagraph:
        return '单句分析';
      case AIContextSource.readerWord:
        return '单词分析';
      case AIContextSource.readerChapter:
        return '章节助手';
      case AIContextSource.rssArticle:
        return '文章助手';
      case AIContextSource.internalWeb:
        return '网页助手';
      case null:
        return 'AI 助手';
    }
  }

  IconData get _sourceIcon {
    switch (snapshot?.source) {
      case AIContextSource.readerSelectedText:
      case AIContextSource.readerParagraph:
        return Icons.auto_awesome_outlined;
      case AIContextSource.readerWord:
        return Icons.spellcheck_outlined;
      case AIContextSource.readerChapter:
        return Icons.menu_book_outlined;
      case AIContextSource.rssArticle:
        return Icons.article_outlined;
      case AIContextSource.internalWeb:
        return Icons.language_outlined;
      case null:
        return Icons.auto_awesome_outlined;
    }
  }

  String get _historyTooltip {
    final count = controller.recentSessions.length;
    return count == 0 ? '历史' : '历史 · $count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = controller.recentSessions;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(_sourceIcon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _sourceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<AIAssistantSession>(
            tooltip: _historyTooltip,
            icon: const Icon(Icons.history_rounded, size: 20),
            onSelected: controller.openSession,
            itemBuilder: (context) {
              if (sessions.isEmpty) {
                return [
                  const PopupMenuItem<AIAssistantSession>(
                    enabled: false,
                    child: Text('暂无历史会话'),
                  ),
                ];
              }
              return sessions
                  .map(
                    (session) => PopupMenuItem<AIAssistantSession>(
                      value: session,
                      child: _HistorySessionItem(session: session),
                    ),
                  )
                  .toList(growable: false);
            },
          ),
          FlowButton.text(
            onPressed: controller.currentContext == null
                ? null
                : controller.startNewSession,
            icon: const Icon(Icons.add_comment_outlined, size: 16),
            size: FlowButtonSize.small,
            child: const Text('新会话'),
          ),
          if (!embedded && onClose != null)
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

class _HistorySessionItem extends StatelessWidget {
  const _HistorySessionItem({required this.session});

  final AIAssistantSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_scopeLabel(session.scope)} · ${session.messages.length} 条消息',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.controller, required this.snapshot});

  final AIAssistantController controller;
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '当前上下文',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (snapshot.chapterTitle != null)
                    Flexible(
                      child: Text(
                        snapshot.chapterTitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    snapshot.sourceLanguage.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                maxLines: _maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _ContextScopeControls(
                snapshot: snapshot,
                onScopeChanged: controller.setScope,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextScopeControls extends StatelessWidget {
  const _ContextScopeControls({
    required this.snapshot,
    required this.onScopeChanged,
  });

  final AIContextSnapshot snapshot;
  final ValueChanged<AIContextScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final choices = _scopeChoices(snapshot);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final choice in choices)
          ChoiceChip(
            label: Text(choice.label),
            selected: snapshot.scope == choice.scope,
            onSelected: choice.enabled
                ? (_) => onScopeChanged(choice.scope)
                : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _ScopeChoice {
  const _ScopeChoice({
    required this.scope,
    required this.label,
    this.enabled = true,
  });

  final AIContextScope scope;
  final String label;
  final bool enabled;
}

List<_ScopeChoice> _scopeChoices(AIContextSnapshot snapshot) {
  final passageLabel = switch (snapshot.source) {
    AIContextSource.readerWord => '当前词',
    AIContextSource.readerSelectedText => '当前句子',
    AIContextSource.readerParagraph => '当前段落',
    _ => '当前内容',
  };
  return [
    _ScopeChoice(scope: AIContextScope.currentPassage, label: passageLabel),
    const _ScopeChoice(scope: AIContextScope.currentChapter, label: '本章'),
    const _ScopeChoice(
      scope: AIContextScope.fullBook,
      label: '全书摘要',
      enabled: false,
    ),
  ];
}

String _scopeLabel(AIContextScope? scope) {
  return switch (scope) {
    AIContextScope.currentPassage => '当前内容',
    AIContextScope.currentChapter => '本章',
    AIContextScope.readSoFar => '已读部分',
    AIContextScope.fullBook => '全书摘要',
    null => '当前上下文',
  };
}

String _actionLabel(AIAssistantActionType? action) {
  return switch (action) {
    AIAssistantActionType.explain => '解释',
    AIAssistantActionType.translate => '翻译',
    AIAssistantActionType.phraseExtraction => '短语',
    AIAssistantActionType.pronounReference => '指代',
    AIAssistantActionType.questionGeneration => '出题',
    AIAssistantActionType.summary => '总结',
    AIAssistantActionType.wordAnalysis => '词汇',
    AIAssistantActionType.articleQA => '问答',
    AIAssistantActionType.paragraphInsight => '段落洞察',
    AIAssistantActionType.chat => '继续追问',
    null => 'AI',
  };
}

String _busyLabel(AIAssistantActionType? action) {
  return switch (action) {
    AIAssistantActionType.explain => '正在分析...',
    AIAssistantActionType.translate => '正在翻译...',
    AIAssistantActionType.phraseExtraction => '正在提取短语...',
    AIAssistantActionType.pronounReference => '正在分析指代...',
    AIAssistantActionType.questionGeneration => '正在生成题目...',
    AIAssistantActionType.summary => '正在生成总结...',
    AIAssistantActionType.wordAnalysis => '正在分析词汇...',
    AIAssistantActionType.articleQA || AIAssistantActionType.chat => '正在回答...',
    AIAssistantActionType.paragraphInsight => '正在分析段落...',
    null => '处理中...',
  };
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
      case AIAssistantActionType.paragraphInsight:
        return '段落洞察';
      case AIAssistantActionType.chat:
        return '追问';
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
      case AIAssistantActionType.paragraphInsight:
        return Icons.format_align_left;
      case AIAssistantActionType.chat:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

class _ConversationArea extends HookWidget {
  const _ConversationArea({
    required this.session,
    required this.actionController,
    required this.snapshot,
    this.onRetry,
  });

  final AIAssistantSession? session;
  final AIActionController actionController;
  final AIContextSnapshot snapshot;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    useListenable(actionController);
    final messages = session?.messages ?? const <AIChatMessage>[];
    final error = actionController.lastResult is AIErrorResult
        ? actionController.lastResult as AIErrorResult
        : null;
    final latestResult = actionController.lastResult;
    final theme = Theme.of(context);

    if (messages.isEmpty && !actionController.isBusy && error == null) {
      return _ConversationIdle(snapshot: snapshot);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        for (var i = 0; i < messages.length; i += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == messages.length - 1 ? 0 : 12,
            ),
            child: _ChatMessageBubble(
              message: messages[i],
              result: _isLatestAssistantMessage(messages, i)
                  ? latestResult
                  : null,
            ),
          ),
        if (actionController.isBusy) ...[
          if (messages.isNotEmpty) const SizedBox(height: 12),
          _PendingAssistantBubble(action: actionController.currentAction),
        ],
        if (error != null && !actionController.isBusy) ...[
          if (messages.isNotEmpty) const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '回答失败',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(error.message, style: theme.textTheme.bodySmall),
                  if (error.isRetryable && onRetry != null) ...[
                    const SizedBox(height: 10),
                    FlowButton.secondary(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      child: const Text('重试'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _isLatestAssistantMessage(List<AIChatMessage> messages, int index) {
    if (messages[index].role != AIChatMessageRole.assistant) return false;
    for (var i = index + 1; i < messages.length; i += 1) {
      if (messages[i].role == AIChatMessageRole.assistant) return false;
    }
    return true;
  }
}

class _ConversationIdle extends StatelessWidget {
  const _ConversationIdle({required this.snapshot});

  final AIContextSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              '选择一个入口开始',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '基于${_scopeLabel(snapshot.scope)}回答',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAssistantBubble extends StatelessWidget {
  const _PendingAssistantBubble({required this.action});

  final AIAssistantActionType? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.42,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _busyLabel(action),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends HookWidget {
  const _ChatMessageBubble({required this.message, this.result});

  final AIChatMessage message;
  final AIActionResult? result;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);
    final theme = Theme.of(context);
    final isUser = message.role == AIChatMessageRole.user;
    final colorScheme = theme.colorScheme;
    final bubbleColor = isUser
        ? colorScheme.primaryContainer.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final borderColor = isUser
        ? colorScheme.primary.withValues(alpha: 0.22)
        : colorScheme.outlineVariant;
    final content = _InlineMessageContent(message: message, result: result);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${_actionLabel(message.actionType)} · 基于${_scopeLabel(message.scope)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                content,
                if (message.citations.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < message.citations.length; i += 1)
                        ActionChip(
                          label: Text('引用 ${i + 1}'),
                          avatar: const Icon(Icons.format_quote, size: 15),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onPressed: () => expanded.value = !expanded.value,
                        ),
                    ],
                  ),
                  if (expanded.value) ...[
                    const SizedBox(height: 8),
                    _CitationPanel(citations: message.citations),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessageContent extends StatelessWidget {
  const _InlineMessageContent({required this.message, this.result});

  final AIChatMessage message;
  final AIActionResult? result;

  @override
  Widget build(BuildContext context) {
    final latest = result;
    if (latest is AITextAnalysisResult) {
      return _TextAnalysisContent(analysis: latest.analysis);
    }
    return _MarkdownMessage(text: message.content);
  }
}

class _MarkdownMessage extends StatelessWidget {
  const _MarkdownMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(height: 1.55);
    final blocks = _markdownBlocks(text.trim());
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    if (blocks.length == 1 && blocks.single is _MarkdownParagraphBlock) {
      final paragraph = blocks.single as _MarkdownParagraphBlock;
      if (!_hasMarkdownInline(paragraph.text)) {
        return Text(paragraph.text, style: baseStyle);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i += 1) ...[
          if (i > 0) const SizedBox(height: 10),
          _MarkdownBlockView(block: blocks[i], baseStyle: baseStyle),
        ],
      ],
    );
  }
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({required this.block, required this.baseStyle});

  final _MarkdownBlock block;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = block;
    if (current is _MarkdownHeadingBlock) {
      final style = theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.35,
      );
      return _MarkdownInlineText(text: current.text, style: style);
    }
    if (current is _MarkdownListBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in current.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      item.marker,
                      style: baseStyle?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _MarkdownInlineText(
                      text: item.text,
                      style: baseStyle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (current is _MarkdownParagraphBlock) {
      return _MarkdownInlineText(text: current.text, style: baseStyle);
    }
    return const SizedBox.shrink();
  }
}

class _MarkdownInlineText extends StatelessWidget {
  const _MarkdownInlineText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!_hasMarkdownInline(text)) {
      return Text(text, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: _inlineMarkdownSpans(context, text, style),
      ),
    );
  }
}

sealed class _MarkdownBlock {
  const _MarkdownBlock();
}

class _MarkdownParagraphBlock extends _MarkdownBlock {
  const _MarkdownParagraphBlock(this.text);

  final String text;
}

class _MarkdownHeadingBlock extends _MarkdownBlock {
  const _MarkdownHeadingBlock(this.text);

  final String text;
}

class _MarkdownListBlock extends _MarkdownBlock {
  const _MarkdownListBlock(this.items);

  final List<_MarkdownListItem> items;
}

class _MarkdownListItem {
  const _MarkdownListItem({required this.marker, required this.text});

  final String marker;
  final String text;
}

List<_MarkdownBlock> _markdownBlocks(String source) {
  if (source.isEmpty) return const [];
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_MarkdownBlock>[];
  final paragraph = <String>[];
  final listItems = <_MarkdownListItem>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(_MarkdownParagraphBlock(paragraph.join('\n').trim()));
    paragraph.clear();
  }

  void flushList() {
    if (listItems.isEmpty) return;
    blocks.add(_MarkdownListBlock(List.unmodifiable(listItems)));
    listItems.clear();
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flushParagraph();
      flushList();
      continue;
    }

    final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
    if (heading != null) {
      flushParagraph();
      flushList();
      blocks.add(_MarkdownHeadingBlock(heading.group(2)!.trim()));
      continue;
    }

    final listMatch = RegExp(
      r'^((?:[-*•])|(?:\d+\.))\s+(.+)$',
    ).firstMatch(trimmed);
    if (listMatch != null) {
      flushParagraph();
      listItems.add(
        _MarkdownListItem(
          marker: listMatch.group(1)!.contains('.') ? listMatch.group(1)! : '•',
          text: listMatch.group(2)!.trim(),
        ),
      );
      continue;
    }

    flushList();
    paragraph.add(trimmed);
  }

  flushParagraph();
  flushList();
  return blocks;
}

bool _hasMarkdownInline(String value) {
  return value.contains('**') || value.contains('`') || value.contains('*');
}

List<TextSpan> _inlineMarkdownSpans(
  BuildContext context,
  String source,
  TextStyle? baseStyle,
) {
  final theme = Theme.of(context);
  final spans = <TextSpan>[];
  final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
  var cursor = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: source.substring(cursor, match.start)));
    }
    final token = match.group(0)!;
    if (token.startsWith('**')) {
      spans.add(
        TextSpan(
          text: token.substring(2, token.length - 2),
          style: baseStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    } else if (token.startsWith('`')) {
      spans.add(
        TextSpan(
          text: token.substring(1, token.length - 1),
          style: baseStyle?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: token.substring(1, token.length - 1),
          style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    cursor = match.end;
  }

  if (cursor < source.length) {
    spans.add(TextSpan(text: source.substring(cursor)));
  }
  return spans;
}

class _CitationPanel extends StatelessWidget {
  const _CitationPanel({required this.citations});

  final List<AIAssistantCitation> citations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '引用与定位',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final citation in citations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  citation.quote ?? citation.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextAnalysisContent extends StatelessWidget {
  const _TextAnalysisContent({required this.analysis});

  final AITextAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <Widget>[];

    void addSection(Widget section) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 10));
      }
      sections.add(section);
    }

    final translation = analysis.translation.trim();
    if (translation.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.translate_outlined,
          title: '译文',
          child: Text(
            translation,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      );
    }

    if (analysis.structureNotes.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.schema_outlined,
          title: '结构',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: analysis.structureNotes
                .map((note) => _StructureNoteItem(note: note))
                .toList(growable: false),
          ),
        ),
      );
    }

    if (analysis.grammarPoints.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.account_tree_outlined,
          title: '语法',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: analysis.grammarPoints
                .map((point) => _GrammarPointItem(point: point))
                .toList(growable: false),
          ),
        ),
      );
    }

    if (analysis.vocabularyNotes.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.format_list_bulleted_outlined,
          title: '词汇',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: analysis.vocabularyNotes
                .map((note) => _VocabularyNoteItem(note: note))
                .toList(growable: false),
          ),
        ),
      );
    }

    if (analysis.expressionNotes.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.auto_fix_high_outlined,
          title: '表达',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: analysis.expressionNotes
                .map((note) => _ExpressionNoteItem(note: note))
                .toList(growable: false),
          ),
        ),
      );
    }

    final readingTip = analysis.readingTip.trim();
    if (readingTip.isNotEmpty) {
      addSection(
        _TextAnalysisSection(
          icon: Icons.lightbulb_outline,
          title: '阅读提示',
          child: Text(
            readingTip,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.isEmpty
          ? [
              Text(
                '已完成分析。',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ]
          : sections,
    );
  }
}

class _TextAnalysisSection extends StatelessWidget {
  const _TextAnalysisSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StructureNoteItem extends StatelessWidget {
  const _StructureNoteItem({required this.note});

  final StructureNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = note.role.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.source.trim().isNotEmpty)
            Text(
              note.source,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaPill(label: role),
          ],
          if (note.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note.explanation,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrammarPointItem extends StatelessWidget {
  const _GrammarPointItem({required this.point});

  final GrammarPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (point.source.trim().isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    point.source,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                if (point.difficulty.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MetaPill(label: point.difficulty),
                ],
              ],
            ),
          if (point.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              point.explanation,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _VocabularyNoteItem extends StatelessWidget {
  const _VocabularyNoteItem({required this.note});

  final VocabularyNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.word,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (note.pos.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                _MetaPill(label: note.pos),
              ],
            ],
          ),
          if (note.contextMeaning.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.contextMeaning,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpressionNoteItem extends StatelessWidget {
  const _ExpressionNoteItem({required this.note});

  final ExpressionNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.source.trim().isNotEmpty)
            Text(
              note.source,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (note.meaning.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.meaning,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
          if (note.usage.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.usage,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuickQuestionStrip extends HookWidget {
  const _QuickQuestionStrip({required this.busy, required this.onSubmit});

  final bool busy;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final prompts = const [
      '这句话什么意思？',
      '换成简单英文',
      '列出难词',
      '不要剧透',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              for (var i = 0; i < prompts.length; i += 1) ...[
                if (i > 0) const SizedBox(width: 6),
                ActionChip(
                  label: Text(prompts[i]),
                  onPressed: busy ? null : () => onSubmit(prompts[i]),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUpInput extends HookWidget {
  const _FollowUpInput({
    required this.busy,
    required this.scope,
    required this.onScopeChanged,
    this.onSubmit,
  });

  final bool busy;
  final AIContextScope scope;
  final ValueChanged<AIContextScope> onScopeChanged;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final hasText = useState(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    final canSubmit = !busy && hasText.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canSubmit
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            PopupMenuButton<AIContextScope>(
              tooltip: '选择追问范围',
              enabled: !busy,
              initialValue: scope,
              onSelected: onScopeChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: AIContextScope.currentPassage,
                  child: Text('基于当前内容'),
                ),
                PopupMenuItem(
                  value: AIContextScope.currentChapter,
                  child: Text('基于本章'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '基于${_scopeLabel(scope)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
            Expanded(
              child: FlowTextField(
                controller: controller,
                enabled: !busy,
                decoration: InputDecoration(
                  hintText: '继续追问...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.35,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => submit(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 6),
              child: IconButton.filledTonal(
                tooltip: '发送追问',
                icon: busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
                onPressed: canSubmit ? submit : null,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(36),
                  minimumSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.surfaceContainerHigh,
                  disabledForegroundColor: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
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
    final langLabel =
        '${snapshot.sourceLanguage.toUpperCase()} → '
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
