import 'package:flow_design_system/flow_design_system.dart';
import 'package:flow_read/widgets/flow/flow_components.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flow platform components', () {
    testWidgets('FlowButton uses Windows Fluent button tokens', (tester) async {
      await tester.pumpWidget(
        _ShellHost(
          shellId: ShellId.windows,
          child: FlowButton.primary(
            onPressed: () {},
            child: const Text('保存'),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      final minimumSize = style.minimumSize!.resolve(<WidgetState>{});
      final shape =
          style.shape!.resolve(<WidgetState>{})! as RoundedRectangleBorder;

      expect(minimumSize, const Size(0, 32));
      expect(shape.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('FlowButton uses macOS HIG self-drawn button', (tester) async {
      await tester.pumpWidget(
        _ShellHost(
          shellId: ShellId.macosStandard,
          child: FlowButton.primary(
            onPressed: () {},
            child: const Text('继续阅读'),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final constraints = container.constraints!;
      final decoration = container.decoration! as BoxDecoration;

      expect(constraints.minWidth, 84);
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.boxShadow, isNull);
      expect(find.text('继续阅读'), findsOneWidget);
    });

    testWidgets('FlowMenuButton renders macOS popover on macOS shell', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _ShellHost(
          shellId: ShellId.macosStandard,
          child: FlowMenuButton<String>(
            tooltip: '更多',
            entries: const [
              FlowMenuItem(
                value: 'rename',
                icon: Icons.drive_file_rename_outline,
                label: '重命名',
              ),
              FlowMenuDivider(),
              FlowMenuItem(
                value: 'remove',
                icon: Icons.remove_circle_outline,
                label: '移出书架',
                destructive: true,
              ),
            ],
            onSelected: (value) => selected = value,
            child: const Text('更多'),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byType(MenuAnchor), findsNothing);

      await tester.tap(find.text('更多'));
      await tester.pumpAndSettle();

      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('移出书架'), findsOneWidget);

      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();

      expect(selected, 'rename');
    });

    testWidgets('FlowTextField renders Cupertino input on iOS shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ShellHost(
          shellId: ShellId.ios,
          child: FlowTextField(placeholder: '搜索'),
        ),
      );

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('FlowDialog renders Cupertino dialog on iOS shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ShellHost(
          shellId: ShellId.ios,
          child: FlowDialog(
            title: Text('更新'),
            content: Text('已完成'),
          ),
        ),
      );

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('FlowSidebar bottom variant delegates selection', (
      tester,
    ) async {
      var selectedIndex = 0;
      await tester.pumpWidget(
        _ShellHost(
          shellId: ShellId.android,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: FlowSidebar.bottom(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  destinations: const [
                    FlowSidebarDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: '阅读',
                    ),
                    FlowSidebarDestination(
                      icon: Icon(Icons.text_fields_outlined),
                      selectedIcon: Icon(Icons.text_fields),
                      label: '词汇',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('词汇'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });

    testWidgets('FlowSidebar bottom uses macOS tab bar on macOS shell', (
      tester,
    ) async {
      var selectedIndex = 0;
      await tester.pumpWidget(
        _ShellHost(
          shellId: ShellId.macosStandard,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: FlowSidebar.bottom(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  destinations: const [
                    FlowSidebarDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: '阅读',
                    ),
                    FlowSidebarDestination(
                      icon: Icon(Icons.text_fields_outlined),
                      selectedIcon: Icon(Icons.text_fields),
                      label: '词汇',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('词汇'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });

    testWidgets('FlowToolbar follows macOS compact toolbar height', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _ShellHost(
          shellId: ShellId.macosStandard,
          child: Scaffold(
            appBar: FlowToolbar(title: Text('书架')),
            body: SizedBox.shrink(),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, 38);
    });
  });
}

class _ShellHost extends StatelessWidget {
  const _ShellHost({required this.shellId, required this.child});

  final ShellId shellId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: FlowTheme.build(
        shellId: shellId,
        paletteId: PaletteId.classic,
        brightness: Brightness.light,
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
