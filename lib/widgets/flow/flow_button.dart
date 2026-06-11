import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/material.dart';

enum FlowButtonVariant { primary, secondary, tonal, text, destructive }

enum FlowButtonSize { small, medium, large }

class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.variant = FlowButtonVariant.primary,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  });

  const FlowButton.primary({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  }) : variant = FlowButtonVariant.primary;

  const FlowButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  }) : variant = FlowButtonVariant.secondary;

  const FlowButton.tonal({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  }) : variant = FlowButtonVariant.tonal;

  const FlowButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  }) : variant = FlowButtonVariant.text;

  const FlowButton.destructive({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.size = FlowButtonSize.medium,
    this.autofocus = false,
  }) : variant = FlowButtonVariant.destructive;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final FlowButtonVariant variant;
  final FlowButtonSize size;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context);
    final destructiveStyle = variant == FlowButtonVariant.destructive
        ? style.merge(
            FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          )
        : style;

    return switch (variant) {
      FlowButtonVariant.primary => _filled(style),
      FlowButtonVariant.secondary => _outlined(style),
      FlowButtonVariant.tonal => _tonal(style),
      FlowButtonVariant.text => _text(style),
      FlowButtonVariant.destructive => _filled(destructiveStyle),
    };
  }

  ButtonStyle _styleFor(BuildContext context) {
    final tokens = FlowThemeData.of(context)?.buttonTokens;
    if (tokens == null) {
      return const ButtonStyle();
    }

    final padding = switch (size) {
      FlowButtonSize.small => tokens.paddingSmall,
      FlowButtonSize.medium => tokens.paddingMedium,
      FlowButtonSize.large => tokens.paddingLarge,
    };

    final flowTheme = FlowThemeData.of(context);
    final isMac =
        flowTheme?.shellId == ShellId.macosStandard ||
        flowTheme?.shellId == ShellId.macosLiquidGlass;
    final minWidth = isMac
        ? switch (size) {
            FlowButtonSize.small => 60.0,
            FlowButtonSize.medium => 84.0,
            FlowButtonSize.large => 108.0,
          }
        : 0.0;

    return ButtonStyle(
      animationDuration: tokens.animationDuration,
      minimumSize: WidgetStatePropertyAll(Size(minWidth, tokens.minHeight)),
      padding: WidgetStatePropertyAll(padding),
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: tokens.borderRadius),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: isMac ? VisualDensity.standard : VisualDensity.compact,
    );
  }

  Widget _filled(ButtonStyle style) {
    if (icon != null) {
      return FilledButton.icon(
        autofocus: autofocus,
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  Widget _outlined(ButtonStyle style) {
    if (icon != null) {
      return OutlinedButton.icon(
        autofocus: autofocus,
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return OutlinedButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  Widget _tonal(ButtonStyle style) {
    if (icon != null) {
      return FilledButton.tonalIcon(
        autofocus: autofocus,
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return FilledButton.tonal(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  Widget _text(ButtonStyle style) {
    if (icon != null) {
      return TextButton.icon(
        autofocus: autofocus,
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return TextButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }
}
