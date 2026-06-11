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
    this.bottom,
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget> actions;
  final Color? backgroundColor;
  final double? height;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight((height ?? 40) + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shellId = FlowThemeData.of(context)?.shellId;
    final effectiveHeight = height ?? theme.appBarTheme.toolbarHeight ?? 40;

    if (shellId == ShellId.ios) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: effectiveHeight,
            child: CupertinoNavigationBar(
              automaticallyImplyLeading: automaticallyImplyLeading,
              leading: leading,
              middle: title,
              trailing: actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
              backgroundColor:
                  backgroundColor ?? theme.appBarTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: bottom == null ? 0.5 : 0,
                  ),
                  width: 0.5,
                ),
              ),
            ),
          ),
          ?bottom,
        ],
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
      bottom: bottom,
    );
  }
}
