import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/main.dart';

void main() {
  testWidgets('App renders reader screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowReadApp());
    await tester.pumpAndSettle();

    expect(find.text('Reader'), findsWidgets);
  });
}
