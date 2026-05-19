import 'package:flow_read/controllers/reading_search_controller.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search stores results and reset clears state', () async {
    final controller = ReadingSearchController();
    final book = Book(
      title: 'Fixture',
      author: 'Tester',
      chapters: const [
        Chapter(title: 'One', plainText: 'Alpha needle beta', rawHtml: ''),
        Chapter(title: 'Two', plainText: 'Another needle appears', rawHtml: ''),
      ],
    );

    await controller.search(book, 'needle');

    expect(controller.query, 'needle');
    expect(controller.results, hasLength(2));
    expect(controller.isSearching, isFalse);
    expect(controller.stoppedAtLimit, isFalse);

    controller.activateResult(controller.results.first);
    expect(controller.activeResult, controller.results.first);

    controller.reset();
    expect(controller.query, isEmpty);
    expect(controller.results, isEmpty);
    expect(controller.activeResult, isNull);
  });
}
