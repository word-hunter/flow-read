import 'package:flow_read/widgets/theme_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ThemeTransitionHost can wrap MaterialApp', (tester) async {
    await tester.pumpWidget(
      const ThemeTransitionHost(
        child: MaterialApp(home: Scaffold(body: Text('Flow Read'))),
      ),
    );

    expect(find.text('Flow Read'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
