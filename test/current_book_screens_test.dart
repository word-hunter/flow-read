import 'package:flow_read/screens/dashboard_screen.dart';
import 'package:flow_read/screens/practice_screen.dart';
import 'package:flow_read/screens/syntax_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('current book screens read missing result through Riverpod', (
    tester,
  ) async {
    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [],
        child: const MaterialApp(
          home: Column(
            children: [
              Expanded(child: DashboardScreen()),
              Expanded(child: PracticeScreen()),
              Expanded(child: SyntaxScreen()),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
  });
}
