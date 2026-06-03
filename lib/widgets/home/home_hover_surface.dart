import 'package:flutter/material.dart';

class HomeHoverSurface extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool isHovering)? builder;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final Color? borderColor;
  final Color? hoverBorderColor;
  final List<BoxShadow>? boxShadow;
  final List<BoxShadow>? hoverBoxShadow;
  final MouseCursor cursor;

  const HomeHoverSurface({
    super.key,
    this.child,
    this.builder,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    required this.borderRadius,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.boxShadow,
    this.hoverBoxShadow,
    this.cursor = SystemMouseCursors.click,
  }) : assert(child != null || builder != null);

  @override
  State<HomeHoverSurface> createState() => _HomeHoverSurfaceState();
}

class _HomeHoverSurfaceState extends State<HomeHoverSurface> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isHovering
        ? widget.hoverBackgroundColor ?? widget.backgroundColor
        : widget.backgroundColor;
    final borderColor = _isHovering
        ? widget.hoverBorderColor ?? widget.borderColor
        : widget.borderColor;

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: widget.borderRadius,
          border: borderColor == null ? null : Border.all(color: borderColor),
          boxShadow: _isHovering
              ? widget.hoverBoxShadow ?? widget.boxShadow
              : widget.boxShadow,
        ),
        child: widget.builder?.call(context, _isHovering) ?? widget.child,
      ),
    );
  }
}
