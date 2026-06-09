import 'package:flow_read/widgets/home/book_shelf_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wraps books into multiple rows when width is constrained', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: BookShelfRow(
              books: List.generate(
                3,
                (index) => BookShelfData(
                  title: 'Book $index',
                  author: 'Author $index',
                  progressPercent: index * 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final firstTop = tester.getTopLeft(find.text('Book 0').first).dy;
    final secondTop = tester.getTopLeft(find.text('Book 1').first).dy;
    final thirdTop = tester.getTopLeft(find.text('Book 2').first).dy;

    expect(secondTop, firstTop);
    expect(thirdTop, greaterThan(secondTop + 100));
  });
}
