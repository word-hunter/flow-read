import 'dart:convert';
import 'dart:typed_data';

import 'package:flow_read/widgets/home/book_cover_view.dart';
import 'package:flow_read/widgets/home/default_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders V2 default cover and clamps title to three lines', (
    tester,
  ) async {
    const fullTitle =
        'Harry Potter and the Order of the Phoenix and the Very Long Subtitle';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: BookCoverView.shelfWidth,
            height: BookCoverView.shelfHeight,
            child: BookCoverView(
              coverBytes: null,
              progressPercent: 37,
              title: fullTitle,
              author: 'J. K. Rowling',
            ),
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(
      find.byKey(DefaultBookCover.titleTextKey),
    );
    final authorText = tester.widget<Text>(
      find.byKey(DefaultBookCover.authorTextKey),
    );

    expect(titleText.maxLines, 3);
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(authorText.data, 'J. K. ROWLING');
    expect(find.text('FLOW READ'), findsNothing);
    expect(find.text('37%'), findsOneWidget);
    expect(find.text('J. K. ROWLING'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsNothing);
    expect(find.byIcon(Icons.diamond_outlined), findsNothing);
    _expectCoverTooltip(
      tester,
      message: fullTitle,
      maxWidth: BookCoverView.tooltipMaxWidth,
    );
  });

  testWidgets('exposes full book title in cover tooltip', (tester) async {
    const fullTitle = 'A Complete Book Title Hidden Behind the Cover Artwork';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCoverView(
            coverBytes: _onePixelPng(),
            progressPercent: 48,
            title: fullTitle,
            author: 'Flow Read',
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(fullTitle), findsNothing);
    _expectCoverTooltip(
      tester,
      message: fullTitle,
      maxWidth: BookCoverView.tooltipMaxWidth,
    );
  });

  testWidgets(
    'keeps existing book cover when cover bytes exist',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCoverView(
              coverBytes: _onePixelPng(),
              progressPercent: 48,
              title: 'Generated Cover',
              author: 'Flow Read',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(DefaultBookCover.titleTextKey), findsNothing);
      expect(find.text('Generated Cover'), findsNothing);
      expect(find.text('48%'), findsOneWidget);
    },
  );

  testWidgets(
    'can force default cover even when cover bytes exist',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCoverView(
              coverBytes: _onePixelPng(),
              progressPercent: 64,
              title: 'Forced Generated Cover',
              author: 'Flow Read',
              forceDefaultCover: true,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byKey(DefaultBookCover.titleTextKey), findsOneWidget);
      expect(find.text('Forced Generated Cover'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
    },
  );
}

void _expectCoverTooltip(
  WidgetTester tester, {
  required String message,
  required double maxWidth,
}) {
  final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
  expect(tooltip.message, isNull);
  final richMessage = tooltip.richMessage;
  expect(richMessage, isA<WidgetSpan>());
  final constrainedBox = (richMessage! as WidgetSpan).child as ConstrainedBox;
  expect(constrainedBox.constraints.maxWidth, maxWidth);
  final text = constrainedBox.child as Text;
  expect(text.data, message);
}

Uint8List _onePixelPng() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAF'
    'gwJ/lokS2AAAAABJRU5ErkJggg==',
  );
}
