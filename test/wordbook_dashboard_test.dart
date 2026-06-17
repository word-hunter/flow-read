import 'package:flow_read/models/aggregated_vocabulary.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/wordbook_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = WordbookDashboardBuilder();
  final now = DateTime.utc(2026, 6, 16, 12);

  test('builds due queue from saved learning items only', () {
    final dashboard = builder.build(
      vocabulary: const [
        AggregatedVocabulary(
          word: 'conceal',
          meaning: '隐藏',
          firstChapter: 26,
          context: 'He tried to conceal the truth.',
        ),
      ],
      learningItems: [
        _word(
          id: 'gleam',
          word: 'gleam',
          meaning: '微光',
          bookId: 'book-1',
          chapterTitle: 'Ch.13',
          sourceText: 'A faint gleam reflected off the window.',
          createdAt: DateTime.utc(2026, 6, 15),
          nextReviewAt: DateTime.utc(2026, 6, 16, 8),
        ),
        _word(
          id: 'hesitate',
          word: 'hesitate',
          meaning: '犹豫',
          bookId: 'book-1',
          chapterTitle: 'Ch.14',
          sourceText: 'She did not hesitate.',
          createdAt: DateTime.utc(2026, 6, 14),
          nextReviewAt: DateTime.utc(2026, 6, 15),
          reviewCount: 1,
        ),
        _word(
          id: 'bargain',
          word: 'bargain',
          meaning: '交易',
          bookId: 'book-2',
          chapterTitle: 'Ch.6',
          sourceText: 'They struck a bargain.',
          createdAt: DateTime.utc(2026, 6, 16),
          nextReviewAt: DateTime.utc(2026, 6, 19),
        ),
        _grammarDue(),
      ],
      statusFor: (word) => switch (word) {
        'bargain' => UserWordStatus.learning,
        _ => null,
      },
      bookTitlesById: const {
        'book-1': 'A Gift of Magic',
        'book-2': 'A Game of Thrones',
      },
      now: now,
    );

    expect(dashboard.dueCount, 3);
    expect(
      dashboard
          .visibleEntries(
            filter: WordbookFilter.due,
            query: '',
            now: now,
          )
          .map((entry) => entry.word),
      ['hesitate', 'gleam'],
    );
    expect(
      dashboard
          .visibleEntries(
            filter: WordbookFilter.recent,
            query: '',
            now: now,
          )
          .map((entry) => entry.word),
      ['bargain', 'gleam', 'hesitate', 'conceal'],
    );
  });

  test('filters mastered, learning, source summaries, and text search', () {
    final dashboard = builder.build(
      vocabulary: const [],
      learningItems: [
        _word(
          id: 'peculiar',
          word: 'peculiar',
          meaning: '奇特的',
          bookId: 'book-1',
          chapterTitle: 'Ch.10',
          sourceText: 'It was a peculiar kind of silence.',
          createdAt: DateTime.utc(2026, 6, 10),
          nextReviewAt: DateTime.utc(2026, 7, 1),
        ),
        _word(
          id: 'conceal',
          word: 'conceal',
          meaning: '隐藏',
          bookId: 'book-2',
          chapterTitle: '第 27 回',
          sourceText: '他强自隐忍，不肯显露。',
          createdAt: DateTime.utc(2026, 6, 12),
          nextReviewAt: DateTime.utc(2026, 6, 17),
        ),
      ],
      statusFor: (word) => switch (word) {
        'peculiar' => UserWordStatus.known,
        'conceal' => UserWordStatus.learning,
        _ => null,
      },
      bookTitlesById: const {
        'book-1': 'A Gift of Magic',
        'book-2': '三国演义（易中天推荐版）',
      },
      now: now,
    );

    expect(dashboard.masteredCount, 1);
    expect(dashboard.learningCount, 1);
    expect(
      dashboard
          .visibleEntries(
            filter: WordbookFilter.mastered,
            query: '',
            now: now,
          )
          .map((entry) => entry.word),
      ['peculiar'],
    );
    expect(
      dashboard
          .visibleEntries(
            filter: WordbookFilter.learning,
            query: '三国',
            now: now,
          )
          .map((entry) => entry.word),
      ['conceal'],
    );
    expect(
      dashboard.sourceSummaries.map((summary) => summary.title),
      ['A Gift of Magic', '三国演义（易中天推荐版）'],
    );
  });

  test('groups visible entries by source book', () {
    final dashboard = builder.build(
      vocabulary: const [],
      learningItems: [
        _word(
          id: 'gleam',
          word: 'gleam',
          meaning: '微光',
          bookId: 'book-1',
          chapterTitle: 'Ch.13',
          createdAt: DateTime.utc(2026, 6, 10),
        ),
        _word(
          id: 'oath',
          word: 'oath',
          meaning: '誓言',
          bookId: 'book-2',
          chapterTitle: 'Ch.1',
          createdAt: DateTime.utc(2026, 6, 11),
        ),
        _word(
          id: 'bargain',
          word: 'bargain',
          meaning: '交易',
          bookId: 'book-2',
          chapterTitle: 'Ch.6',
          createdAt: DateTime.utc(2026, 6, 12),
        ),
      ],
      statusFor: (_) => null,
      bookTitlesById: const {
        'book-1': 'A Gift of Magic',
        'book-2': 'A Game of Thrones',
      },
      now: now,
    );

    final groups = dashboard.visibleEntryGroupsByBook(query: '', now: now);

    expect(groups.map((group) => group.sourceTitle), [
      'A Game of Thrones',
      'A Gift of Magic',
    ]);
    expect(groups.first.wordCount, 2);
    expect(groups.first.entries.map((entry) => entry.word), [
      'oath',
      'bargain',
    ]);
    expect(groups.last.entries.single.word, 'gleam');

    final searched = dashboard.visibleEntryGroupsByBook(
      query: 'gift',
      now: now,
    );
    expect(searched, hasLength(1));
    expect(searched.single.sourceTitle, 'A Gift of Magic');
    expect(searched.single.entries.single.word, 'gleam');
  });

  test('counts consecutive review days from reviewed learning items', () {
    final dashboard = builder.build(
      vocabulary: const [],
      learningItems: [
        _word(
          id: 'today',
          word: 'today',
          updatedAt: DateTime.utc(2026, 6, 16, 8),
          lastResult: LearningReviewResult.remembered,
        ),
        _word(
          id: 'yesterday',
          word: 'yesterday',
          updatedAt: DateTime.utc(2026, 6, 15, 8),
          lastResult: LearningReviewResult.missed,
        ),
        _word(
          id: 'old',
          word: 'old',
          updatedAt: DateTime.utc(2026, 6, 13, 8),
          lastResult: LearningReviewResult.remembered,
        ),
      ],
      statusFor: (_) => null,
      bookTitlesById: const {},
      now: now,
    );

    expect(dashboard.reviewStreakDays, 2);
  });
}

LearningItem _word({
  required String id,
  required String word,
  String meaning = '',
  String bookId = '',
  String chapterTitle = '',
  String sourceText = '',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? nextReviewAt,
  int reviewCount = 0,
  LearningReviewResult lastResult = LearningReviewResult.newItem,
}) {
  final created = createdAt ?? DateTime.utc(2026, 6, 1);
  return LearningItem(
    id: id,
    type: LearningItemType.word,
    canonicalKey: word,
    title: word,
    content: word,
    answer: meaning,
    note: '',
    sourceText: sourceText,
    bookId: bookId,
    chapterIndex: 0,
    chapterTitle: chapterTitle,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    nextReviewAt: nextReviewAt ?? created,
    reviewCount: reviewCount,
    lastResult: lastResult,
  );
}

LearningItem _grammarDue() {
  return LearningItem(
    id: 'grammar',
    type: LearningItemType.grammar,
    canonicalKey: 'on the back of',
    title: 'on the back of',
    content: 'on the back of',
    answer: '介词短语',
    note: '',
    sourceText: 'On the back of her eyelids...',
    bookId: 'book-1',
    chapterIndex: 0,
    chapterTitle: 'Ch.1',
    createdAt: DateTime.utc(2026, 6, 13),
    updatedAt: DateTime.utc(2026, 6, 13),
    nextReviewAt: DateTime.utc(2026, 6, 16),
  );
}
