import 'package:flow_read/widgets/selected_text_action_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selection action toolbar uses icon actions with tooltips', (
    tester,
  ) async {
    var copied = false;
    var analyzed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectedTextActionToolbar(
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(220, 220),
              secondaryAnchor: Offset(220, 260),
            ),
            actions: [
              SelectedTextAction(
                icon: Icons.copy_rounded,
                tooltip: '复制',
                onPressed: () => copied = true,
              ),
              SelectedTextAction(
                icon: Icons.auto_awesome_rounded,
                tooltip: 'AI 解析',
                onPressed: () => analyzed = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byTooltip('复制'), findsOneWidget);
    expect(find.byTooltip('AI 解析'), findsOneWidget);

    await tester.tap(find.byTooltip('复制'));
    await tester.pump();
    expect(copied, isTrue);

    await tester.tap(find.byTooltip('AI 解析'));
    await tester.pump();
    expect(analyzed, isTrue);
  });

  testWidgets('disabled selection action is still explained by tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectedTextActionToolbar(
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(220, 220),
            ),
            actions: [
              SelectedTextAction(
                icon: Icons.auto_awesome_rounded,
                tooltip: 'AI 解析',
                enabled: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byTooltip('AI 解析'), findsOneWidget);
    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.onPressed, isNull);
  });

  testWidgets('copy action preserves the selected text exactly', (
    tester,
  ) async {
    var closed = false;
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCall = call;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SelectedTextActionToolbar(
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset(220, 220),
              ),
              actions: [
                SelectedTextAction.copy(
                  context: context,
                  selectedText: '  Exact\nselection  ',
                  closeToolbar: () => closed = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('复制'));
    await tester.pump();

    expect(closed, isTrue);
    expect(clipboardCall?.arguments, {'text': '  Exact\nselection  '});
  });
}
