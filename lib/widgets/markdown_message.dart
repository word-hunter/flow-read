import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FlowMarkdownMessage extends StatelessWidget {
  const FlowMarkdownMessage({
    super.key,
    required this.text,
    this.style,
    this.headingStyle,
    this.currentWord,
    this.onLookupWord,
    this.blockSpacing = 10,
    this.listItemSpacing = 6,
    this.listMarkerWidth = 18,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? headingStyle;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;
  final double blockSpacing;
  final double listItemSpacing;
  final double listMarkerWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        style ?? theme.textTheme.bodySmall?.copyWith(height: 1.55);
    final blocks = _markdownBlocks(text.trim());
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    if (blocks.length == 1 && blocks.single is _MarkdownParagraphBlock) {
      final paragraph = blocks.single as _MarkdownParagraphBlock;
      if (!_hasMarkdownInline(paragraph.text) && onLookupWord == null) {
        return Text(paragraph.text, style: baseStyle);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i += 1) ...[
          if (i > 0) SizedBox(height: blockSpacing),
          _MarkdownBlockView(
            block: blocks[i],
            baseStyle: baseStyle,
            headingStyle: headingStyle,
            currentWord: currentWord,
            onLookupWord: onLookupWord,
            listItemSpacing: listItemSpacing,
            listMarkerWidth: listMarkerWidth,
          ),
        ],
      ],
    );
  }
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({
    required this.block,
    required this.baseStyle,
    required this.headingStyle,
    required this.currentWord,
    required this.onLookupWord,
    required this.listItemSpacing,
    required this.listMarkerWidth,
  });

  final _MarkdownBlock block;
  final TextStyle? baseStyle;
  final TextStyle? headingStyle;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;
  final double listItemSpacing;
  final double listMarkerWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = block;
    if (current is _MarkdownHeadingBlock) {
      final style =
          headingStyle ??
          theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.35,
          );
      return _MarkdownInlineText(
        text: current.text,
        style: style,
        currentWord: currentWord,
        onLookupWord: onLookupWord,
      );
    }
    if (current is _MarkdownListBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in current.items)
            Padding(
              padding: EdgeInsets.only(bottom: listItemSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: listMarkerWidth,
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
                      currentWord: currentWord,
                      onLookupWord: onLookupWord,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (current is _MarkdownParagraphBlock) {
      return _MarkdownInlineText(
        text: current.text,
        style: baseStyle,
        currentWord: currentWord,
        onLookupWord: onLookupWord,
      );
    }
    return const SizedBox.shrink();
  }
}

class _MarkdownInlineText extends StatefulWidget {
  const _MarkdownInlineText({
    required this.text,
    required this.style,
    required this.currentWord,
    required this.onLookupWord,
  });

  final String text;
  final TextStyle? style;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;

  @override
  State<_MarkdownInlineText> createState() => _MarkdownInlineTextState();
}

class _MarkdownInlineTextState extends State<_MarkdownInlineText> {
  static const _tapSlop = 6.0;

  final GlobalKey _textKey = GlobalKey();
  int? _hoveredTokenStart;
  int? _pendingHoveredTokenStart;
  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _pointerMoved = false;
  bool _hoverUpdateScheduled = false;
  int _hoverUpdateGeneration = 0;

  @override
  void dispose() {
    _hoverUpdateGeneration += 1;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MarkdownInlineText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.currentWord != widget.currentWord) {
      _hoveredTokenStart = null;
      _pendingHoveredTokenStart = null;
      _hoverUpdateGeneration += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasMarkdownInline(widget.text) && widget.onLookupWord == null) {
      return Text(widget.text, style: widget.style);
    }

    final child = Text.rich(
      key: _textKey,
      TextSpan(style: widget.style, children: _buildSpans(context)),
    );
    if (widget.onLookupWord == null) return child;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerCancel: (_) => _clearPointerTracking(),
      onPointerUp: _handlePointerUp,
      child: child,
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final segments = _inlineMarkdownSegments(
      context,
      widget.text,
      widget.style,
    );
    if (widget.onLookupWord == null) {
      return [
        for (final segment in segments)
          TextSpan(text: segment.text, style: segment.style),
      ];
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(r"[A-Za-z][A-Za-z'-]*");
    var plainCursor = 0;
    for (final segment in segments) {
      var segmentCursor = 0;
      for (final match in pattern.allMatches(segment.text)) {
        if (match.start > segmentCursor) {
          spans.add(
            TextSpan(
              text: segment.text.substring(segmentCursor, match.start),
              style: segment.style,
            ),
          );
        }

        final token = segment.text.substring(match.start, match.end);
        final tokenStart = plainCursor + match.start;
        if (_isLookupCandidate(token)) {
          final hovered = _hoveredTokenStart == tokenStart;
          spans.add(
            TextSpan(
              text: token,
              mouseCursor: SystemMouseCursors.click,
              onEnter: (_) => _scheduleHoveredToken(tokenStart),
              onExit: (_) {
                if (_hoveredTokenStart == tokenStart ||
                    _pendingHoveredTokenStart == tokenStart) {
                  _scheduleHoveredToken(null);
                }
              },
              style: _tokenStyle(context, segment.style, hovered),
            ),
          );
        } else {
          spans.add(TextSpan(text: token, style: segment.style));
        }
        segmentCursor = match.end;
      }

      if (segmentCursor < segment.text.length) {
        spans.add(
          TextSpan(
            text: segment.text.substring(segmentCursor),
            style: segment.style,
          ),
        );
      }
      plainCursor += segment.text.length;
    }
    return spans;
  }

  TextStyle? _tokenStyle(
    BuildContext context,
    TextStyle? segmentStyle,
    bool hovered,
  ) {
    if (!hovered) return segmentStyle;
    return (segmentStyle ?? const TextStyle()).copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton || widget.onLookupWord == null) {
      _clearPointerTracking();
      return;
    }

    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
    _pointerMoved = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    final start = _pointerDownPosition;
    if (start == null) return;
    if ((event.position - start).distance > _tapSlop) {
      _pointerMoved = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerDownPosition;
    final isTrackedTap =
        event.pointer == _activePointer &&
        start != null &&
        !_pointerMoved &&
        (event.position - start).distance <= _tapSlop;
    _clearPointerTracking();

    if (!isTrackedTap) return;
    final token = _lookupTokenAt(event.position);
    if (token == null) return;
    widget.onLookupWord?.call(token);
  }

  void _clearPointerTracking() {
    _activePointer = null;
    _pointerDownPosition = null;
    _pointerMoved = false;
  }

  String? _lookupTokenAt(Offset globalPosition) {
    if (widget.onLookupWord == null) return null;

    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final localPosition = renderObject.globalToLocal(globalPosition);
    if (!(Offset.zero & renderObject.size).contains(localPosition)) {
      return null;
    }

    final painter = TextPainter(
      text: TextSpan(style: widget.style, children: _buildSpans(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: renderObject.size.width);

    final plainText = _visibleInlineText(widget.text);
    final pattern = RegExp(r"[A-Za-z][A-Za-z'-]*");
    for (final match in pattern.allMatches(plainText)) {
      final token = plainText.substring(match.start, match.end);
      if (!_isLookupCandidate(token)) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: match.start, extentOffset: match.end),
      );
      for (final box in boxes) {
        if (box.toRect().inflate(2).contains(localPosition)) {
          return _normalizeLookupToken(token);
        }
      }
    }

    return null;
  }

  void _scheduleHoveredToken(int? tokenStart) {
    _pendingHoveredTokenStart = tokenStart;
    if (_hoverUpdateScheduled) return;

    _hoverUpdateScheduled = true;
    final generation = _hoverUpdateGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoverUpdateScheduled = false;
      if (!mounted || generation != _hoverUpdateGeneration) return;
      final nextHoveredTokenStart = _pendingHoveredTokenStart;
      if (_hoveredTokenStart == nextHoveredTokenStart) return;
      setState(() => _hoveredTokenStart = nextHoveredTokenStart);
    });
  }

  bool _isLookupCandidate(String token) {
    final normalized = _normalizeLookupToken(token);
    if (normalized.length < 2) return false;
    final current = widget.currentWord?.trim().toLowerCase();
    return current == null || current != normalized;
  }

  String _normalizeLookupToken(String token) {
    return token
        .replaceAll(RegExp(r"(^[^A-Za-z]+|[^A-Za-z]+$)"), '')
        .toLowerCase();
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

class _InlineMarkdownSegment {
  const _InlineMarkdownSegment({required this.text, required this.style});

  final String text;
  final TextStyle? style;
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

List<_InlineMarkdownSegment> _inlineMarkdownSegments(
  BuildContext context,
  String source,
  TextStyle? baseStyle,
) {
  final theme = Theme.of(context);
  final segments = <_InlineMarkdownSegment>[];
  final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
  var cursor = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      segments.add(
        _InlineMarkdownSegment(
          text: source.substring(cursor, match.start),
          style: null,
        ),
      );
    }
    final token = match.group(0)!;
    if (token.startsWith('**')) {
      segments.add(
        _InlineMarkdownSegment(
          text: token.substring(2, token.length - 2),
          style: baseStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    } else if (token.startsWith('`')) {
      segments.add(
        _InlineMarkdownSegment(
          text: token.substring(1, token.length - 1),
          style: baseStyle?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    } else {
      segments.add(
        _InlineMarkdownSegment(
          text: token.substring(1, token.length - 1),
          style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    cursor = match.end;
  }

  if (cursor < source.length) {
    segments.add(
      _InlineMarkdownSegment(text: source.substring(cursor), style: null),
    );
  }
  return segments;
}

String _visibleInlineText(String source) {
  final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
  final buffer = StringBuffer();
  var cursor = 0;

  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      buffer.write(source.substring(cursor, match.start));
    }
    final token = match.group(0)!;
    if (token.startsWith('**')) {
      buffer.write(token.substring(2, token.length - 2));
    } else {
      buffer.write(token.substring(1, token.length - 1));
    }
    cursor = match.end;
  }

  if (cursor < source.length) {
    buffer.write(source.substring(cursor));
  }
  return buffer.toString();
}
