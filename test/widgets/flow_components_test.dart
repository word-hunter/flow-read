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
