import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/services/changelog_service.dart';
import 'package:flow_read/widgets/release_notes_dialog.dart';

void main() {
  testWidgets('ReleaseNotesDialog binds its scrollbar to the scroll view', (
    tester,
  ) async {
    final notes = ReleaseNotes(
      version: '0.0.2-alpha',
      raw: 'release notes',
      sections: [
        ReleaseNotesSection(
          title: '更新内容',
          items: List.generate(24, (index) => '更新项 ${index + 1}'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => ReleaseNotesDialog(notes: notes),
                );
              },
              child: const Text('打开发布说明'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开发布说明'));
    await tester.pumpAndSettle();

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );

    expect(scrollbar.controller, isNotNull);
    expect(scrollbar.controller, same(scrollView.controller));
    expect(tester.takeException(), isNull);
  });
}
