import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/widgets/reader_shell/reader_left_workspace_panel.dart';
import 'package:flow_read/widgets/reader_shell/reader_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('left workspace shows TOC without unfinished placeholder tabs', (
    tester,
  ) async {
    final controller = ReaderWorkspaceController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          currentBookNotifierProvider.overrideWith(
            () => _PanelCurrentBookNotifier(_book()),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 560,
              child: ReaderLeftWorkspacePanel(
                workspaceController: controller,
                onGoToChapter: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('目录'), findsOneWidget);
    expect(find.text('全部章节 2'), findsOneWidget);
    expect(find.text('书签'), findsNothing);
    expect(find.text('搜索'), findsNothing);
    expect(find.text('目标'), findsNothing);
    expect(find.text('即将推出'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(controller.isLeftPanelOpen, isFalse);
  });
}

Book _book() {
  return const Book(
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    chapters: [
      Chapter(
        title: 'Chapter I',
        plainText: 'In my younger and more vulnerable years.',
        rawHtml: '',
      ),
      Chapter(
        title: 'Chapter II',
        plainText: 'About half way between West Egg and New York.',
        rawHtml: '',
      ),
    ],
  );
}

class _PanelCurrentBookNotifier extends CurrentBookNotifier {
  _PanelCurrentBookNotifier(this._book);

  final Book _book;

  @override
  CurrentBookState build() => const CurrentBookState(
    currentChapter: 0,
    readingProgress: 0.32,
  );

  @override
  Book? get book => _book;

  @override
  int get chapterCount => _book.chapters.length;
}
