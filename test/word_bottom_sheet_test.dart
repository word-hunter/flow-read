import 'dart:io';

import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_context_example.dart';
import 'package:flow_read/models/wordbook_dashboard.dart';
import 'package:flow_read/providers/reading/bookmark_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/providers/reading/word_lookup_notifier.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/widgets/flow/flow_components.dart';
import 'package:flow_read/widgets/word_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_word_level_service.dart';
import 'support/test_storage.dart';

void main() {
  late Directory tempDir;
  late SettingsService settings;

  setUp(() async {
    tempDir = await initTestStorage('word_bottom_sheet_test');
    settings = await createTestSettingsService();
  });

  tearDown(() async {
    await disposeTestStorage(tempDir);
  });

  testWidgets('wordbook detail shows source context and status actions', (
    tester,
  ) async {
    final vocabulary = _WordbookSheetVocabularyNotifier();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
          wordLevelServiceProvider.overrideWithValue(fakeWordLevelService()),
          wordLookupNotifierProvider.overrideWith(
            _WordbookSheetLookupNotifier.new,
          ),
          vocabularyNotifierProvider.overrideWith(() => vocabulary),
          bookmarkNotifierProvider.overrideWith(_WordbookSheetBookmark.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WordBottomSheet(
              word: 'gleam',
              wordbookEntry: _wordbookEntry(),
              onShowSourceBook: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('A Gift of Magic'), findsOneWidget);
    expect(find.text('Ch.13'), findsOneWidget);
    expect(
      find.text('A faint gleam reflected off the window.'),
      findsOneWidget,
    );
    expect(find.text('原文上下文'), findsOneWidget);

    final sourceButton = tester.widget<FlowButton>(
      find.ancestor(
        of: find.text('查看来源书籍'),
        matching: find.byType(FlowButton),
      ),
    );
    expect(sourceButton.onPressed, isNotNull);

    expect(find.text('标为学习中'), findsOneWidget);
    expect(find.text('标为已掌握'), findsOneWidget);
    expect(find.text('AI 详解此词'), findsNothing);
    expect(find.text('加入生词本'), findsNothing);

    await tester.tap(find.text('标为学习中'));
    await tester.pump();

    expect(vocabulary.actions, ['learning:gleam']);
    expect(find.text('已标为学习中'), findsOneWidget);
  });
}

WordbookEntry _wordbookEntry() {
  return WordbookEntry(
    id: 'item-gleam',
    word: 'gleam',
    meaning: '微光',
    sourceTitle: 'A Gift of Magic',
    sourceDetail: 'Ch.13',
    sourceContext: 'A faint gleam reflected off the window.',
    bookId: 'book-1',
    chapterIndex: 12,
    languageId: 'en',
    status: null,
    createdAt: DateTime.utc(2026, 6, 15),
    nextReviewAt: DateTime.utc(2026, 6, 16),
    reviewCount: 0,
    fromLearningItem: true,
  );
}

class _WordbookSheetLookupNotifier extends WordLookupNotifier {
  @override
  WordLookupState build() {
    return const WordLookupState(
      selectedWord: 'gleam',
      selectedWordTranslation: '微光',
    );
  }

  @override
  List<WordContextExample> importedExamplesFor(String word) => const [];

  @override
  Future<void> speakWord(String word) async {}

  @override
  Future<void> lookupRelatedWord(String word) async {}

  @override
  void goBackWordLookup() {}

  @override
  Future<void> retryWordLookup() async {}

  @override
  bool get canGenerateBookGlossaryExplanation => false;

  @override
  Future<void> generateBookGlossaryExplanation() async {}

  @override
  Future<bool> saveBookGlossaryExplanation({String? explanation}) async {
    return false;
  }
}

class _WordbookSheetVocabularyNotifier extends VocabularyNotifier {
  final actions = <String>[];
  UserWordStatus? _status;

  @override
  VocabularyState build() => const VocabularyState();

  @override
  UserWordStatus? getWordStatus(String word) => _status;

  @override
  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) async {
    actions.add('known:$word');
    _status = UserWordStatus.known;
  }

  @override
  Future<void> markWordLearning(String word) async {
    actions.add('learning:$word');
    _status = UserWordStatus.learning;
  }

  @override
  Future<void> markWordUnknown(String word) async {
    actions.add('unknown:$word');
    _status = null;
  }
}

class _WordbookSheetBookmark extends BookmarkNotifier {
  @override
  BookmarkState build() => const BookmarkState();

  @override
  bool isBookmarked(String word) => false;
}
