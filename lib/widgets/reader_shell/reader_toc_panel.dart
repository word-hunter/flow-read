import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/content_block.dart';
import '../../providers/reading/current_book_notifier.dart';
import '../../theme/app_surface_tokens.dart';

class ReaderTocPanel extends riverpod.ConsumerStatefulWidget {
  final ValueChanged<int>? onGoToChapter;
  final ValueChanged<int>? onChapterSelected;

  const ReaderTocPanel({
    super.key,
    this.onGoToChapter,
    this.onChapterSelected,
  });

  @override
  riverpod.ConsumerState<ReaderTocPanel> createState() =>
      _ReaderTocPanelState();
}

class _ReaderTocPanelState extends riverpod.ConsumerState<ReaderTocPanel> {
  static const _estimatedItemExtent = 50.0;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int? _lastQueuedSelectedIndex;
  int? _lastQueuedItemCount;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _itemKeyFor(int index) =>
      _itemKeys.putIfAbsent(index, GlobalKey.new);

  void _trimItemKeys(int itemCount) {
    _itemKeys.removeWhere((index, _) => index >= itemCount);
  }

  void _queueSelectedItemPosition({
    required int selectedIndex,
    required int itemCount,
  }) {
    if (itemCount <= 0) return;
    if (_lastQueuedSelectedIndex == selectedIndex &&
        _lastQueuedItemCount == itemCount) {
      return;
    }

    _lastQueuedSelectedIndex = selectedIndex;
    _lastQueuedItemCount = itemCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollSelectedItemIntoView(
        selectedIndex: selectedIndex,
        retryAfterEstimatedJump: true,
      );
    });
  }

  void _scrollSelectedItemIntoView({
    required int selectedIndex,
    required bool retryAfterEstimatedJump,
  }) {
    if (!_scrollController.hasClients) return;

    final selectedContext = _itemKeys[selectedIndex]?.currentContext;
    if (selectedContext != null) {
      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        alignment: 0.14,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
      return;
    }

    final position = _scrollController.position;
    final estimatedTarget = (selectedIndex * _estimatedItemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((_scrollController.offset - estimatedTarget).abs() > 0.5) {
      _scrollController.jumpTo(estimatedTarget.toDouble());
    }

    if (!retryAfterEstimatedJump) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollSelectedItemIntoView(
        selectedIndex: selectedIndex,
        retryAfterEstimatedJump: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBookState = ref.watch(currentBookNotifierProvider);
    final currentBookNotifier = ref.read(currentBookNotifierProvider.notifier);
    final theme = Theme.of(context);
    final tokens = AppSurfaceTokens.of(context);
    final book = currentBookNotifier.book;
    if (book == null) return _buildEmptyState(theme);

    final items = buildReaderTocItems(book);
    if (items.isEmpty) return _buildEmptyState(theme);

    _trimItemKeys(items.length);
    final selectedIndex = selectedReaderTocIndexForChapter(
      items,
      currentBookState.currentChapter,
    );
    _queueSelectedItemPosition(
      selectedIndex: selectedIndex,
      itemCount: items.length,
    );

    return Column(
      children: [
        _TocWorkspaceHeader(
          itemCount: items.length,
          chapterCount: book.chapters.length,
          currentChapter: currentBookState.currentChapter,
          usingStructuredToc: book.toc.isNotEmpty,
        ),
        Divider(
          height: 1,
          color: tokens.panelBorderColor,
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            primary: false,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 28),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              return _TocChapterTile(
                key: _itemKeyFor(index),
                item: item,
                isSelected: isSelected,
                onTap: () {
                  final onGoToChapter = widget.onGoToChapter;
                  if (onGoToChapter == null) {
                    currentBookNotifier.goToChapter(item.targetChapterIndex);
                  } else {
                    onGoToChapter(item.targetChapterIndex);
                  }
                  widget.onChapterSelected?.call(item.targetChapterIndex);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '暂无目录',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TocWorkspaceHeader extends StatelessWidget {
  final int itemCount;
  final int chapterCount;
  final int currentChapter;
  final bool usingStructuredToc;

  const _TocWorkspaceHeader({
    required this.itemCount,
    required this.chapterCount,
    required this.currentChapter,
    required this.usingStructuredToc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final currentChapterLabel = chapterCount == 0
        ? 0
        : (currentChapter + 1).clamp(1, chapterCount);
    final countLabel = usingStructuredToc
        ? '目录条目 $itemCount'
        : '全部章节 $itemCount';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (chapterCount > 0) ...[
            const SizedBox(width: 10),
            Text(
              '当前 $currentChapterLabel / $chapterCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReaderTocItem {
  final String title;
  final String? subtitle;
  final int targetChapterIndex;
  final int level;
  final int ordinal;

  const ReaderTocItem({
    required this.title,
    this.subtitle,
    required this.targetChapterIndex,
    this.level = 0,
    required this.ordinal,
  });
}

List<ReaderTocItem> buildReaderTocItems(Book book) {
  if (book.chapters.isEmpty) return const [];

  if (book.toc.isNotEmpty) {
    return [
      for (var i = 0; i < book.toc.length; i += 1)
        _tocEntryItemForBook(book, i),
    ];
  }

  return [
    for (var i = 0; i < book.chapters.length; i += 1)
      _fallbackChapterItem(book.chapters[i], i),
  ];
}

int selectedReaderTocIndexForChapter(
  List<ReaderTocItem> items,
  int currentChapter,
) {
  if (items.isEmpty) return 0;
  final exactIndex = items.indexWhere(
    (item) => item.targetChapterIndex == currentChapter,
  );
  if (exactIndex != -1) return exactIndex;
  return currentChapter.clamp(0, items.length - 1).toInt();
}

ReaderTocItem _tocEntryItemForBook(Book book, int index) {
  final entry = book.toc[index];
  final targetChapterIndex =
      _chapterIndexForHref(book.chapters, entry.href) ??
      index.clamp(0, book.chapters.length - 1).toInt();
  final fallbackLabel = _chapterLabelForWorkspace(
    book.chapters[targetChapterIndex],
    targetChapterIndex,
  );
  final title = _normalizeTocTitle(entry.label);
  return ReaderTocItem(
    title: title.isEmpty ? fallbackLabel.title : title,
    targetChapterIndex: targetChapterIndex,
    level: entry.level.clamp(0, 4).toInt(),
    ordinal: index + 1,
  );
}

ReaderTocItem _fallbackChapterItem(Chapter chapter, int index) {
  final label = _chapterLabelForWorkspace(chapter, index);
  return ReaderTocItem(
    title: label.title,
    subtitle: label.subtitle,
    targetChapterIndex: index,
    ordinal: index + 1,
  );
}

int? _chapterIndexForHref(List<Chapter> chapters, String href) {
  final target = _normalizedHrefPath(href);
  if (target.isEmpty) return null;

  for (var i = 0; i < chapters.length; i += 1) {
    final chapterHref = chapters[i].href;
    if (chapterHref == null || chapterHref.trim().isEmpty) continue;
    final chapterPath = _normalizedHrefPath(chapterHref);
    if (chapterPath.isEmpty) continue;
    if (target == chapterPath) return i;
    if (target.endsWith('/$chapterPath')) return i;
    if (chapterPath.endsWith('/$target')) return i;
  }
  return null;
}

String _normalizedHrefPath(String href) {
  var text = href.trim().replaceAll('\\', '/');
  final hashIndex = text.indexOf('#');
  if (hashIndex != -1) {
    text = text.substring(0, hashIndex);
  }
  final queryIndex = text.indexOf('?');
  if (queryIndex != -1) {
    text = text.substring(0, queryIndex);
  }
  try {
    text = Uri.decodeFull(text);
  } on FormatException {
    // Keep the raw href when an EPUB contains malformed percent escapes.
  }

  final segments = <String>[];
  for (final segment in text.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(segment);
  }
  return segments.join('/');
}

String _normalizeTocTitle(String title) {
  return title.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _ChapterTocLabel {
  final String title;
  final String? subtitle;

  const _ChapterTocLabel({required this.title, this.subtitle});
}

_ChapterTocLabel _chapterLabelForWorkspace(Chapter chapter, int index) {
  final title = chapter.title.replaceAll(RegExp(r'\s+'), ' ').trim();
  final fallbackTitle = '第 ${index + 1} 节';
  final isGenericTitle =
      title.isEmpty ||
      RegExp(
        r'^(section|chapter|part)\s*\d+$',
        caseSensitive: false,
      ).hasMatch(title) ||
      RegExp(r'^第\s*\d+\s*[章节回]$').hasMatch(title);

  if (!isGenericTitle) {
    return _ChapterTocLabel(title: title);
  }

  final opening = _chapterOpeningSnippet(chapter);
  if (opening.isEmpty) {
    return _ChapterTocLabel(title: title.isEmpty ? fallbackTitle : title);
  }

  return _ChapterTocLabel(
    title: opening,
    subtitle: title.isEmpty ? fallbackTitle : title,
  );
}

String _chapterOpeningSnippet(Chapter chapter) {
  var text = '';
  for (final block in chapter.blocks) {
    if (block is TextBlock) {
      text = block.plainText;
      break;
    }
  }
  if (text.isEmpty) {
    text = chapter.plainText;
  }
  var normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  while (normalized.isNotEmpty) {
    final withoutImagePrefix = normalized.replaceFirst(
      RegExp(r'^(?:image|img|figure)\b[\s:：\-—–]*', caseSensitive: false),
      '',
    );
    if (withoutImagePrefix == normalized) break;
    normalized = withoutImagePrefix.trimLeft();
  }
  if (normalized.isEmpty) return '';

  final words = normalized.split(' ');
  if (words.length > 8) {
    final snippet = words.take(8).join(' ');
    if (snippet.length <= 72) return '$snippet...';
  }
  if (normalized.length <= 72) return normalized;
  return '${normalized.substring(0, 72).trimRight()}...';
}

class _TocChapterTile extends StatefulWidget {
  final ReaderTocItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TocChapterTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TocChapterTile> createState() => _TocChapterTileState();
}

class _TocChapterTileState extends State<_TocChapterTile> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final tokens = AppSurfaceTokens.of(context);
    final backgroundColor = widget.isSelected
        ? primary.withValues(alpha: 0.13)
        : (_isHovered
              ? theme.colorScheme.surface.withValues(alpha: 0.58)
              : Colors.transparent);
    final borderColor = widget.isSelected
        ? primary.withValues(alpha: 0.18)
        : (_isHovered ? tokens.panelBorderColor : Colors.transparent);
    final titleColor = widget.isSelected
        ? primary
        : theme.colorScheme.onSurface;
    final levelIndent = widget.item.level * 14.0;
    final tooltipMessage = widget.item.subtitle == null
        ? widget.item.title
        : '${widget.item.title}\n${widget.item.subtitle}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 700),
        child: Semantics(
          button: true,
          selected: widget.isSelected,
          label: widget.item.title,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHover: _setHovered,
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 46),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        7,
                        10,
                        widget.item.subtitle == null ? 7 : 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 6,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                width: widget.isSelected ? 3 : 0,
                                height: widget.item.subtitle == null ? 26 : 34,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 + levelIndent),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: widget.isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    height: 1.18,
                                  ),
                                ),
                                if (widget.item.subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.item.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
