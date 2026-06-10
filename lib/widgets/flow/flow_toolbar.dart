import 'package:flow_design_system/flow_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlowToolbar extends StatelessWidget implements PreferredSizeWidget {
  const FlowToolbar({
    super.key,
    this.leading,
    this.title,
    this.actions = const [],
    this.backgroundColor,
    this.height,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final Color? backgroundColor;
  final double? height;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(height ?? 40);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shellId = FlowThemeData.of(context)?.shellId;
    final effectiveHeight =
        height ?? theme.appBarTheme.toolbarHeight ?? preferredSize.height;

    if (shellId == ShellId.ios) {
      return SizedBox(
        height: effectiveHeight,
        child: CupertinoNavigationBar(
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: leading,
          middle: title,
          trailing: actions.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions),
          backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title,
      actions: actions,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      toolbarHeight: effectiveHeight,
      scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation,
      surfaceTintColor: theme.appBarTheme.surfaceTintColor,
    );
  }
}
