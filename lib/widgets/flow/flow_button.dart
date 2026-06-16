import 'package:flutter/material.dart';
import 'flow_button_style.dart';
import 'flow_shell_dispatcher.dart';

export 'flow_button_style.dart';

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
    return SelectionContainer.disabled(
      child: buildFlowButton(
        onPressed: onPressed,
        child: child,
        icon: icon,
        variant: variant,
        size: size,
        autofocus: autofocus,
        context: context,
      ),
    );
  }
}
