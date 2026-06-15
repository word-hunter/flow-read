import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/providers/book_insight_provider.dart';
import 'package:flow_read/screens/book_insights_page.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide BookGlossaryEntry;
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late BookInsightProvider provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_book_insights_test_',
    );
    db = await AppDatabase.createInMemory();
    final glossaryService = BookGlossaryService(BookGlossaryDao(db));
    await glossaryService.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'book-1',
        word: 'godswood',
        canonicalForm: 'old godswood',
        explanation: 'A sacred grove tied to the book world.',
        sourceContext: 'The godswood was silent.',
        createdAt: DateTime.utc(2026, 6, 15),
      ),
    );
    await glossaryService.saveEntry(
      BookGlossaryEntry.create(
        bookId: 'other-book',
        word: 'elsewhere',
        explanation: 'Different book.',
        createdAt: DateTime.utc(2026, 6, 15),
      ),
    );
    provider = BookInsightProvider(
      cacheService: AICacheService(
        documentsDirectoryProvider: () async => tempDir,
      ),
      glossaryService: glossaryService,
    );
    await provider.loadForBook(
      'book-1',
      totalChapters: 8,
      currentChapter: 2,
    );
  });

  tearDown(() async {
    provider.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows book glossary entries in insights page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) {},
        ),
      ),
    );

    expect(find.text('暂无章节总结'), findsNothing);
    expect(find.text('术语'), findsOneWidget);

    await tester.tap(find.text('术语'));
    await tester.pumpAndSettle();

    expect(find.text('godswood'), findsOneWidget);
    expect(find.text('old godswood'), findsOneWidget);
    expect(find.text('A sacred grove tied to the book world.'), findsOneWidget);
    expect(find.textContaining('The godswood was silent.'), findsOneWidget);
    expect(find.text('elsewhere'), findsNothing);
  });
}
