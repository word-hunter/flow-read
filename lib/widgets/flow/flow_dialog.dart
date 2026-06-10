import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlowDialog extends StatelessWidget {
  const FlowDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.insetPadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final shellId = FlowThemeData.of(context)?.shellId;
    if (shellId == ShellId.ios) {
      return CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions,
      );
    }

    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      insetPadding: insetPadding,
    );
  }
}

Future<T?> showFlowDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final shellId = FlowThemeData.of(context)?.shellId;
  if (shellId == ShellId.ios) {
    return showCupertinoDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
    );
  }

  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
  );
}
