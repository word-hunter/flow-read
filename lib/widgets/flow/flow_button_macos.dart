import 'package:flutter/material.dart';
import 'flow_button_style.dart';

Widget buildMacOsButton({
  required VoidCallback? onPressed,
  required Widget child,
  Widget? icon,
  required FlowButtonVariant variant,
  required FlowButtonSize size,
  bool autofocus = false,
}) {
  return _MacOsButton(
    onPressed: onPressed,
    icon: icon,
    variant: variant,
    size: size,
    autofocus: autofocus,
    child: child,
  );
}

class _MacOsButton extends StatefulWidget {
  const _MacOsButton({
    required this.onPressed,
    this.icon,
    required this.variant,
    required this.size,
    this.autofocus = false,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget? icon;
  final FlowButtonVariant variant;
  final FlowButtonSize size;
  final bool autofocus;
  final Widget child;

  @override
  State<_MacOsButton> createState() => _MacOsButtonState();
}

class _MacOsButtonState extends State<_MacOsButton> {
  bool _hovered = false;
  bool _pressed = false;

  static const _borderRadius = Radius.circular(6);
  static const _duration = Duration(milliseconds: 100);

  bool get _enabled => widget.onPressed != null;

  double get _height => switch (widget.size) {
        FlowButtonSize.small => 28,
        FlowButtonSize.medium => 32,
        FlowButtonSize.large => 36,
      };

  double get _minWidth => switch (widget.size) {
        FlowButtonSize.small => 60,
        FlowButtonSize.medium => 84,
        FlowButtonSize.large => 108,
      };

  EdgeInsets get _padding => switch (widget.size) {
        FlowButtonSize.small => const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
        FlowButtonSize.medium => const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
        FlowButtonSize.large => const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
      };

  double get _iconSize => switch (widget.size) {
        FlowButtonSize.small => 14,
        FlowButtonSize.medium => 16,
        FlowButtonSize.large => 18,
      };

  double get _iconGap => switch (widget.size) {
        FlowButtonSize.small => 5,
        FlowButtonSize.medium => 6,
        FlowButtonSize.large => 8,
      };

  Color _backgroundColor(ThemeData theme) {
    final cs = theme.colorScheme;
    final p = cs.primary;
    final e = cs.error;

    if (!_enabled) {
      return switch (widget.variant) {
        FlowButtonVariant.primary => p,
        FlowButtonVariant.destructive => e,
        FlowButtonVariant.tonal => p.withValues(alpha: 0.15),
        _ => Colors.transparent,
      };
    }

    if (_pressed) {
      return switch (widget.variant) {
        FlowButtonVariant.primary =>
          Color.alphaBlend(Colors.black.withValues(alpha: 0.15), p),
        FlowButtonVariant.destructive =>
          Color.alphaBlend(Colors.black.withValues(alpha: 0.15), e),
        FlowButtonVariant.tonal => p.withValues(alpha: 0.25),
        _ => p.withValues(alpha: 0.12),
      };
    }

    if (_hovered) {
      return switch (widget.variant) {
        FlowButtonVariant.primary =>
          Color.alphaBlend(Colors.white.withValues(alpha: 0.08), p),
        FlowButtonVariant.destructive =>
          Color.alphaBlend(Colors.white.withValues(alpha: 0.08), e),
        FlowButtonVariant.tonal => p.withValues(alpha: 0.20),
        _ => p.withValues(alpha: 0.06),
      };
    }

    return switch (widget.variant) {
      FlowButtonVariant.primary => p,
      FlowButtonVariant.destructive => e,
      FlowButtonVariant.tonal => p.withValues(alpha: 0.15),
      _ => Colors.transparent,
    };
  }

  Color _foregroundColor(ThemeData theme) {
    return switch (widget.variant) {
      FlowButtonVariant.primary => theme.colorScheme.onPrimary,
      FlowButtonVariant.destructive => theme.colorScheme.onError,
      _ => theme.colorScheme.primary,
    };
  }

  BoxBorder? _border(ThemeData theme) {
    if (widget.variant != FlowButtonVariant.secondary) return null;
    final alpha = _enabled ? 0.6 : 0.3;
    return Border.all(
      color: theme.colorScheme.outline.withValues(alpha: alpha),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = _foregroundColor(theme);

    Widget button = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: _duration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _enabled ? 1.0 : 0.4,
            duration: _duration,
            child: AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _backgroundColor(theme),
                borderRadius: const BorderRadius.all(_borderRadius),
                border: _border(theme),
              ),
              constraints: BoxConstraints(
                minWidth: _minWidth,
                minHeight: _height,
              ),
              padding: _padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: fg, size: _iconSize),
                      child: widget.icon!,
                    ),
                    SizedBox(width: _iconGap),
                  ],
                  Flexible(
                    child: DefaultTextStyle(
                      style: (theme.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            color: fg,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.autofocus) {
      button = Focus(autofocus: true, child: button);
    }

    return button;
  }

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() {
      _hovered = value;
      if (!value) _pressed = false;
    });
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }
}
