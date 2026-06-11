import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/material.dart';
import 'flow_button_macos.dart';
import 'flow_button_style.dart';

Widget buildFlowButton({
  required VoidCallback? onPressed,
  required Widget child,
  Widget? icon,
  FlowButtonVariant variant = FlowButtonVariant.primary,
  FlowButtonSize size = FlowButtonSize.medium,
  bool autofocus = false,
  required BuildContext context,
}) {
  final shellId = FlowThemeData.of(context)?.shellId;

  final isMacOs =
      shellId == ShellId.macosStandard || shellId == ShellId.macosLiquidGlass;

  if (isMacOs) {
    return buildMacOsButton(
      onPressed: onPressed,
      child: child,
      icon: icon,
      variant: variant,
      size: size,
      autofocus: autofocus,
    );
  }

  return _buildMaterialButton(
    onPressed: onPressed,
    child: child,
    icon: icon,
    variant: variant,
    size: size,
    autofocus: autofocus,
    context: context,
  );
}

Widget _buildMaterialButton({
  required VoidCallback? onPressed,
  required Widget child,
  Widget? icon,
  required FlowButtonVariant variant,
  required FlowButtonSize size,
  required bool autofocus,
  required BuildContext context,
}) {
  final tokens = FlowThemeData.of(context)?.buttonTokens;
  final style = tokens != null
      ? _styleFor(context, tokens, size)
      : const ButtonStyle();

  final destructiveStyle = variant == FlowButtonVariant.destructive
      ? style.merge(
          FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        )
      : style;

  return switch (variant) {
    FlowButtonVariant.primary => _filled(onPressed, child, icon, style, autofocus),
    FlowButtonVariant.secondary =>
      _outlined(onPressed, child, icon, style, autofocus),
    FlowButtonVariant.tonal => _tonal(onPressed, child, icon, style, autofocus),
    FlowButtonVariant.text => _text(onPressed, child, icon, style, autofocus),
    FlowButtonVariant.destructive =>
      _filled(onPressed, child, icon, destructiveStyle, autofocus),
  };
}

ButtonStyle _styleFor(
  BuildContext context,
  ButtonTokens tokens,
  FlowButtonSize size,
) {
  final padding = switch (size) {
    FlowButtonSize.small => tokens.paddingSmall,
    FlowButtonSize.medium => tokens.paddingMedium,
    FlowButtonSize.large => tokens.paddingLarge,
  };

  return ButtonStyle(
    animationDuration: tokens.animationDuration,
    minimumSize: WidgetStatePropertyAll(Size(0, tokens.minHeight)),
    padding: WidgetStatePropertyAll(padding),
    mouseCursor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return SystemMouseCursors.basic;
      }
      return SystemMouseCursors.click;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.08);
      }
      return Colors.transparent;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: tokens.borderRadius),
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}

Widget _filled(
  VoidCallback? onPressed,
  Widget child,
  Widget? icon,
  ButtonStyle style,
  bool autofocus,
) {
  if (icon != null) {
    return FilledButton.icon(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      icon: icon,
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

Widget _outlined(
  VoidCallback? onPressed,
  Widget child,
  Widget? icon,
  ButtonStyle style,
  bool autofocus,
) {
  if (icon != null) {
    return OutlinedButton.icon(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      icon: icon,
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

Widget _tonal(
  VoidCallback? onPressed,
  Widget child,
  Widget? icon,
  ButtonStyle style,
  bool autofocus,
) {
  if (icon != null) {
    return FilledButton.tonalIcon(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      icon: icon,
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

Widget _text(
  VoidCallback? onPressed,
  Widget child,
  Widget? icon,
  ButtonStyle style,
  bool autofocus,
) {
  if (icon != null) {
    return TextButton.icon(
      autofocus: autofocus,
      onPressed: onPressed,
      style: style,
      icon: icon,
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
