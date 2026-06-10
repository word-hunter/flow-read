import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlowTextField extends StatelessWidget {
  const FlowTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.autofocus = false,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool autofocus;
  final bool obscureText;
  final bool readOnly;
  final bool? enabled;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final shellId = FlowThemeData.of(context)?.shellId;
    if (shellId == ShellId.ios) {
      return _CupertinoFlowTextField(
        controller: controller,
        focusNode: focusNode,
        decoration: decoration,
        placeholder: placeholder,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        style: style,
        autofocus: autofocus,
        obscureText: obscureText,
        readOnly: readOnly,
        enabled: enabled,
        minLines: minLines,
        maxLines: maxLines,
      );
    }

    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(
          hintText: decoration?.hintText ?? placeholder,
          prefixIcon: decoration?.prefixIcon ?? prefixIcon,
          suffixIcon: decoration?.suffixIcon ?? suffixIcon,
        );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled ?? true,
      minLines: minLines,
      maxLines: maxLines,
    );
  }
}

class _CupertinoFlowTextField extends StatelessWidget {
  const _CupertinoFlowTextField({
    this.controller,
    this.focusNode,
    this.decoration,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.autofocus = false,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled,
    this.minLines,
    this.maxLines,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool autofocus;
  final bool obscureText;
  final bool readOnly;
  final bool? enabled;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flowTheme = FlowThemeData.of(context);
    final tokens = flowTheme?.buttonTokens;
    final effectivePlaceholder =
        placeholder ?? decoration?.hintText ?? decoration?.labelText;

    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: effectivePlaceholder,
      prefix: _padded(prefixIcon ?? decoration?.prefixIcon),
      suffix: _padded(suffixIcon ?? decoration?.suffixIcon),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled ?? true,
      minLines: minLines,
      maxLines: maxLines,
      padding:
          tokens?.paddingMedium ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: enabled == false
            ? theme.disabledColor.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: tokens?.borderRadius ?? BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      style: style ?? theme.textTheme.bodyMedium,
      placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _padded(Widget? child) {
    if (child == null) return null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 10, end: 6),
      child: child,
    );
  }
}
