import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlowSheet extends StatelessWidget {
  const FlowSheet({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.padding,
    this.maxWidth,
    this.showDragHandle = true,
  });

  final Widget? title;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flowTheme = FlowThemeData.of(context);
    final radius = switch (flowTheme?.shellId) {
      ShellId.windows => 8.0,
      ShellId.macosStandard || ShellId.macosLiquidGlass => 10.0,
      ShellId.ios => 16.0,
      ShellId.android || null => 28.0,
    };
    final content = Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (title != null) ...[
            DefaultTextStyle(
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              child: title!,
            ),
            const SizedBox(height: 12),
          ],
          Flexible(child: child),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 640),
          child: Material(
            color:
                theme.bottomSheetTheme.backgroundColor ??
                theme.colorScheme.surface,
            surfaceTintColor: theme.bottomSheetTheme.surfaceTintColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        ),
      ),
    );
  }
}

Future<T?> showFlowSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  final shellId = FlowThemeData.of(context)?.shellId;
  if (shellId == ShellId.ios) {
    return showCupertinoModalPopup<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) => Material(
        color: Colors.transparent,
        child: builder(context),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}
