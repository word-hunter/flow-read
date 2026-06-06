import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/reading_search_result.dart';
import '../../providers/reading/reading_search_provider.dart';
import '../reader_text_view.dart'
    show searchHighlightBackgroundFor, searchHighlightForegroundFor;

class ReaderSearchSheet extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onMore;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const ReaderSearchSheet({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onMore,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.44,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _ReaderSearchPanel(
              controller: controller,
              focusNode: focusNode,
              expanded: false,
              resultsScrollController: scrollController,
              onChanged: onChanged,
              onClose: () => Navigator.of(context).pop(),
              onMore: onMore,
              onResultTap: onResultTap,
            ),
          ),
        );
      },
    );
  }
}

class _ReaderSearchPanel extends riverpod.ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final ScrollController? resultsScrollController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final VoidCallback onMore;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const _ReaderSearchPanel({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onChanged,
    required this.onClose,
    required this.onMore,
    required this.onResultTap,
    this.resultsScrollController,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final search = ref.watch(readingSearchProvider);
    final results = search.results;
    final query = search.query;
    return Padding(
      padding: expanded
          ? const EdgeInsets.fromLTRB(18, 12, 18, 14)
          : const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _SearchField(
            controller: controller,
            focusNode: focusNode,
            expanded: expanded,
            onChanged: onChanged,
            onClose: onClose,
          ),
          const SizedBox(height: 8),
          _SearchStatus(search: search, expanded: expanded),
          const SizedBox(height: 6),
          Expanded(
            child: _SearchResultsList(
              query: query,
              results: results,
              isSearching: search.isSearching,
              activeResult: search.activeResult,
              scrollController: resultsScrollController,
              onResultTap: onResultTap,
            ),
          ),
          if (!expanded && search.stoppedAtLimit) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onMore,
                icon: const Icon(Icons.open_in_full, size: 18),
                label: const Text('显示更多'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索书中内容',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '清除',
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.close),
          tooltip: expanded ? '收起' : '关闭',
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SearchStatus extends StatelessWidget {
  final ReadingSearchFacade search;
  final bool expanded;

  const _SearchStatus({required this.search, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultCount = search.results.length;
    final query = search.query;
    final text = query.isEmpty
        ? '输入关键词'
        : search.isSearching
        ? '正在搜索... $resultCount'
        : search.stoppedAtLimit && !expanded
        ? '已显示前 $resultCount 条'
        : '共 $resultCount 条结果';

    return Row(
      children: [
        if (search.isSearching) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final String query;
  final List<ReadingSearchResult> results;
  final bool isSearching;
  final ReadingSearchResult? activeResult;
  final ScrollController? scrollController;
  final ValueChanged<ReadingSearchResult> onResultTap;

  const _SearchResultsList({
    required this.query,
    required this.results,
    required this.isSearching,
    required this.activeResult,
    required this.onResultTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (query.isEmpty) {
      return _SearchEmptyState(text: '输入关键词进行全文搜索');
    }
    if (results.isEmpty) {
      if (isSearching) {
        return _SearchEmptyState(text: '正在搜索...');
      }
      return _SearchEmptyState(text: '未找到匹配内容');
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        return _SearchResultTile(
          result: result,
          selected: activeResult == result,
          onTap: () => onResultTap(result),
        );
      },
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String text;

  const _SearchEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ReadingSearchResult result;
  final bool selected;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = result.chapterTitle.trim().isEmpty
        ? result.locationLabel
        : '${result.locationLabel} · ${result.chapterTitle.trim()}';

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: _buildResultSnippetSpan(result, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextSpan _buildResultSnippetSpan(ReadingSearchResult result, ThemeData theme) {
  final baseStyle = theme.textTheme.bodySmall?.copyWith(
    height: 1.35,
    color: theme.colorScheme.onSurfaceVariant,
  );
  final highlightStyle = baseStyle?.copyWith(
    color: searchHighlightForegroundFor(theme),
    backgroundColor: searchHighlightBackgroundFor(theme),
    fontWeight: FontWeight.w700,
  );
  final text = result.snippet;
  final start = result.snippetMatchStart.clamp(0, text.length).toInt();
  final end = result.snippetMatchEnd.clamp(start, text.length).toInt();

  return TextSpan(
    style: baseStyle,
    children: [
      if (start > 0) TextSpan(text: text.substring(0, start)),
      TextSpan(text: text.substring(start, end), style: highlightStyle),
      if (end < text.length) TextSpan(text: text.substring(end)),
    ],
  );
}
