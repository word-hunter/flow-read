import 'package:flutter/material.dart';

class ReaderPanelResizer extends StatefulWidget {
  final bool vertical;
  final double width;
  final ValueChanged<double> onResize;
  final double minWidth;
  final double maxWidth;

  const ReaderPanelResizer({
    super.key,
    this.vertical = true,
    this.width = 6,
    required this.onResize,
    required this.minWidth,
    required this.maxWidth,
  });

  @override
  State<ReaderPanelResizer> createState() => _ReaderPanelResizerState();
}

class _ReaderPanelResizerState extends State<ReaderPanelResizer> {
  bool _isDragging = false;
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = _isDragging || _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
        },
        onHorizontalDragUpdate: (details) {
          widget.onResize(details.globalPosition.dx);
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
        },
        child: Container(
          width: widget.width,
          color: activeColor,
        ),
      ),
    );
  }
}
