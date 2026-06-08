import 'dart:convert';
import 'dart:typed_data';

import 'package:flow_read/app/flow_read_feature_flags.dart';
import 'package:flow_read/widgets/home/book_cover_view.dart';
import 'package:flow_read/widgets/home/default_book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlowReadFeatureFlags.setV2Enabled(false);
  });

  tearDown(() {
    FlowReadFeatureFlags.setV2Enabled(false);
  });

  testWidgets('uses legacy placeholder when V2 flag is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BookCoverView(
            coverBytes: null,
            progressPercent: 12,
            title: 'A Long Book Title',
            author: 'A Writer',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.menu_book), findsOneWidget);
    expect(find.byKey(DefaultBookCover.titleTextKey), findsNothing);
    expect(find.text('12%'), findsNothing);
  });

  testWidgets('renders V2 default cover and clamps title to three lines', (
    tester,
  ) async {
    FlowReadFeatureFlags.setV2Enabled(true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: BookCoverView.shelfWidth,
            height: BookCoverView.shelfHeight,
            child: BookCoverView(
              coverBytes: null,
              progressPercent: 37,
              title:
                  'Harry Potter and the Order of the Phoenix and the Very Long Subtitle',
              author: 'J. K. Rowling',
            ),
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(
      find.byKey(DefaultBookCover.titleTextKey),
    );

    expect(titleText.maxLines, 3);
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(find.text('37%'), findsOneWidget);
    expect(find.text('J. K. ROWLING'), findsOneWidget);
  });

  testWidgets(
    'keeps existing book cover in V2 when cover bytes exist',
    (
      tester,
    ) async {
      FlowReadFeatureFlags.setV2Enabled(true);

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
    'can force V2 default cover even when cover bytes exist',
    (
      tester,
    ) async {
      FlowReadFeatureFlags.setV2Enabled(true);

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

  testWidgets(
    'ignores forced default cover when V2 flag is disabled',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCoverView(
              coverBytes: _onePixelPng(),
              progressPercent: 71,
              title: 'Legacy Real Cover',
              author: 'Flow Read',
              forceDefaultCover: true,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(DefaultBookCover.titleTextKey), findsNothing);
      expect(find.text('Legacy Real Cover'), findsNothing);
      expect(find.text('71%'), findsOneWidget);
    },
  );
}

Uint8List _onePixelPng() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAF'
    'gwJ/lokS2AAAAABJRU5ErkJggg==',
  );
}
