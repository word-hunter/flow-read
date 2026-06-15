import 'dart:io';

import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/models/book_glossary_entry.dart';
import 'package:flow_read/providers/book_insight_provider.dart';
import 'package:flow_read/screens/book_insights_page.dart';
import 'package:flow_read/services/book_glossary_service.dart';
import 'package:flow_read/services/character_registry.dart';
import 'package:flow_read/storage/database/app_database.dart'
    hide BookGlossaryEntry, CharacterRegistryEntry;
import 'package:flow_read/storage/database/dao/book_glossary_dao.dart';
import 'package:flow_read/storage/database/repositories/drift_character_registry_repository.dart';
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
    final characterRegistryWriter = CharacterRegistry(
      repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
    );
    await characterRegistryWriter.init();
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
    await characterRegistryWriter.addEntry(
      'book-1',
      CharacterRegistryEntry(
        canonicalName: 'Eddard Stark',
        aliases: const {'Ned'},
        userOverrides: const {'Lord Stark'},
        firstAppearanceChapter: 0,
        updatedAt: DateTime.utc(2026, 6, 15),
      ),
    );
    await characterRegistryWriter.addEntry(
      'other-book',
      CharacterRegistryEntry(
        canonicalName: 'Other Person',
        updatedAt: DateTime.utc(2026, 6, 15),
      ),
    );
    provider = BookInsightProvider(
      cacheService: AICacheService(
        documentsDirectoryProvider: () async => tempDir,
      ),
      glossaryService: glossaryService,
      characterRegistry: CharacterRegistry(
        repository: DriftCharacterRegistryRepository(db.characterRegistryDao),
      ),
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

  testWidgets('shows registered book characters in insights page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookInsightsPage(
          provider: provider,
          bookTitle: 'Book One',
          onGenerateChapter: (_) {},
        ),
      ),
    );

    expect(find.text('人物'), findsOneWidget);

    await tester.tap(find.text('人物'));
    await tester.pumpAndSettle();

    expect(find.text('Eddard Stark'), findsOneWidget);
    expect(find.text('Ned'), findsOneWidget);
    expect(find.text('Lord Stark'), findsOneWidget);
    expect(find.text('首次出现: 第 1 章'), findsOneWidget);
    expect(find.text('Other Person'), findsNothing);
  });
}
