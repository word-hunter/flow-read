import 'aggregated_vocabulary.dart';
import 'learning_item.dart';
import 'user_vocabulary.dart';

enum WordbookFilter { due, learning, recent, byBook, mastered }

extension WordbookFilterLabel on WordbookFilter {
  String get label {
    return switch (this) {
      WordbookFilter.due => '待复习',
      WordbookFilter.learning => '学习中',
      WordbookFilter.recent => '最近加入',
      WordbookFilter.byBook => '按书籍',
      WordbookFilter.mastered => '已掌握',
    };
  }
}

class WordbookEntry {
  final String id;
  final String word;
  final String meaning;
  final String sourceTitle;
  final String sourceDetail;
  final String sourceContext;
  final String bookId;
  final int chapterIndex;
  final String languageId;
  final UserWordStatus? status;
  final DateTime createdAt;
  final DateTime nextReviewAt;
  final int reviewCount;
  final bool fromLearningItem;

  const WordbookEntry({
    required this.id,
    required this.word,
    required this.meaning,
    required this.sourceTitle,
    required this.sourceDetail,
    required this.sourceContext,
    required this.bookId,
    required this.chapterIndex,
    required this.languageId,
    required this.status,
    required this.createdAt,
    required this.nextReviewAt,
    required this.reviewCount,
    required this.fromLearningItem,
  });

  bool get isMastered => status == UserWordStatus.known;

  bool get isLearning => status == UserWordStatus.learning || !isMastered;

  bool isDue(DateTime now) {
    return fromLearningItem &&
        !isMastered &&
        nextReviewAt.isBefore(_tomorrow(now));
  }

  String get familiarityLabel => 'L${(reviewCount + 1).clamp(1, 5)}';

  static DateTime _tomorrow(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }
}

class WordbookSourceSummary {
  final String title;
  final int wordCount;

  const WordbookSourceSummary({
    required this.title,
    required this.wordCount,
  });
}

class WordbookEntryGroup {
  final String sourceTitle;
  final List<WordbookEntry> entries;

  const WordbookEntryGroup({
    required this.sourceTitle,
    required this.entries,
  });

  int get wordCount => entries.length;
}

class WordbookDashboard {
  final List<WordbookEntry> entries;
  final List<WordbookSourceSummary> sourceSummaries;
  final int dueCount;
  final int learningCount;
  final int masteredCount;
  final int reviewStreakDays;

  const WordbookDashboard({
    required this.entries,
    required this.sourceSummaries,
    required this.dueCount,
    required this.learningCount,
    required this.masteredCount,
    required this.reviewStreakDays,
  });

  List<WordbookEntry> visibleEntries({
    required WordbookFilter filter,
    required String query,
    required DateTime now,
  }) {
    final normalizedQuery = query.toLowerCase().trim();
    final filtered = entries
        .where((entry) => _matchesFilter(entry, filter, now))
        .where((entry) => _matchesQuery(entry, normalizedQuery))
        .toList();

    filtered.sort((a, b) => _compareEntries(a, b, filter));
    return filtered;
  }

  List<WordbookEntryGroup> visibleEntryGroupsByBook({
    required String query,
    required DateTime now,
  }) {
    final groupedEntries = <String, List<WordbookEntry>>{};
    for (final entry in visibleEntries(
      filter: WordbookFilter.byBook,
      query: query,
      now: now,
    )) {
      groupedEntries
          .putIfAbsent(entry.sourceTitle, () => <WordbookEntry>[])
          .add(entry);
    }
    return groupedEntries.entries
        .map(
          (group) => WordbookEntryGroup(
            sourceTitle: group.key,
            entries: List.unmodifiable(group.value),
          ),
        )
        .toList(growable: false);
  }

  bool _matchesFilter(
    WordbookEntry entry,
    WordbookFilter filter,
    DateTime now,
  ) {
    return switch (filter) {
      WordbookFilter.due => entry.isDue(now),
      WordbookFilter.learning => entry.isLearning && !entry.isMastered,
      WordbookFilter.recent => true,
      WordbookFilter.byBook => true,
      WordbookFilter.mastered => entry.isMastered,
    };
  }

  bool _matchesQuery(WordbookEntry entry, String query) {
    if (query.isEmpty) return true;
    return entry.word.toLowerCase().contains(query) ||
        entry.meaning.toLowerCase().contains(query) ||
        entry.sourceTitle.toLowerCase().contains(query) ||
        entry.sourceDetail.toLowerCase().contains(query) ||
        entry.sourceContext.toLowerCase().contains(query);
  }

  int _compareEntries(
    WordbookEntry a,
    WordbookEntry b,
    WordbookFilter filter,
  ) {
    return switch (filter) {
      WordbookFilter.due => _compareDue(a, b),
      WordbookFilter.learning => _compareLearning(a, b),
      WordbookFilter.recent => b.createdAt.compareTo(a.createdAt),
      WordbookFilter.byBook => _compareByBook(a, b),
      WordbookFilter.mastered => a.word.compareTo(b.word),
    };
  }

  int _compareDue(WordbookEntry a, WordbookEntry b) {
    final dueCompare = a.nextReviewAt.compareTo(b.nextReviewAt);
    if (dueCompare != 0) return dueCompare;
    final reviewCompare = a.reviewCount.compareTo(b.reviewCount);
    if (reviewCompare != 0) return reviewCompare;
    return b.createdAt.compareTo(a.createdAt);
  }

  int _compareLearning(WordbookEntry a, WordbookEntry b) {
    final statusCompare = _statusRank(
      a.status,
    ).compareTo(_statusRank(b.status));
    if (statusCompare != 0) return statusCompare;
    return b.createdAt.compareTo(a.createdAt);
  }

  int _compareByBook(WordbookEntry a, WordbookEntry b) {
    final sourceCompare = a.sourceTitle.compareTo(b.sourceTitle);
    if (sourceCompare != 0) return sourceCompare;
    final chapterCompare = a.sourceDetail.compareTo(b.sourceDetail);
    if (chapterCompare != 0) return chapterCompare;
    return a.word.compareTo(b.word);
  }

  int _statusRank(UserWordStatus? status) {
    return switch (status) {
      UserWordStatus.learning => 0,
      null => 1,
      UserWordStatus.known => 2,
    };
  }
}

class WordbookDashboardBuilder {
  const WordbookDashboardBuilder();

  WordbookDashboard build({
    required List<AggregatedVocabulary> vocabulary,
    required List<LearningItem> learningItems,
    required UserWordStatus? Function(String word) statusFor,
    required Map<String, String> bookTitlesById,
    required DateTime now,
  }) {
    final entriesByWord = <String, WordbookEntry>{};

    for (final item in learningItems.where(
      (item) => item.type == LearningItemType.word,
    )) {
      final entry = _entryFromLearningItem(item, statusFor, bookTitlesById);
      if (entry == null) continue;
      entriesByWord[entry.word.toLowerCase()] = entry;
    }

    for (final vocab in vocabulary) {
      final key = vocab.word.toLowerCase().trim();
      if (key.isEmpty || entriesByWord.containsKey(key)) continue;
      entriesByWord[key] = _entryFromVocabulary(vocab, statusFor);
    }

    final entries = entriesByWord.values.toList();
    return WordbookDashboard(
      entries: entries,
      sourceSummaries: _sourceSummaries(entries),
      dueCount: learningItems
          .where((item) => _isReviewable(item))
          .where((item) => item.nextReviewAt.isBefore(_tomorrow(now)))
          .length,
      learningCount: entries.where((entry) => entry.isLearning).length,
      masteredCount: entries.where((entry) => entry.isMastered).length,
      reviewStreakDays: _reviewStreakDays(learningItems, now),
    );
  }

  WordbookEntry? _entryFromLearningItem(
    LearningItem item,
    UserWordStatus? Function(String word) statusFor,
    Map<String, String> bookTitlesById,
  ) {
    final word = _firstNonEmpty([item.title, item.content, item.canonicalKey]);
    if (word.isEmpty) return null;
    final bookTitle = bookTitlesById[item.bookId]?.trim();
    final chapter = item.chapterTitle.trim();
    return WordbookEntry(
      id: item.id,
      word: word,
      meaning: _firstNonEmpty([item.answer, item.note]),
      sourceTitle: _firstNonEmpty([bookTitle ?? '', item.bookId, '阅读材料']),
      sourceDetail: chapter.isNotEmpty
          ? chapter
          : _chapterLabel(item.chapterIndex),
      sourceContext: item.sourceText,
      bookId: item.bookId,
      chapterIndex: item.chapterIndex,
      languageId: 'en',
      status: statusFor(word),
      createdAt: item.createdAt,
      nextReviewAt: item.nextReviewAt,
      reviewCount: item.reviewCount,
      fromLearningItem: true,
    );
  }

  WordbookEntry _entryFromVocabulary(
    AggregatedVocabulary vocab,
    UserWordStatus? Function(String word) statusFor,
  ) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    return WordbookEntry(
      id: 'vocab-${vocab.languageId}-${vocab.word}',
      word: vocab.word,
      meaning: vocab.meaning,
      sourceTitle: '当前阅读材料',
      sourceDetail: _chapterLabel(vocab.firstChapter),
      sourceContext: vocab.context,
      bookId: '',
      chapterIndex: vocab.firstChapter,
      languageId: vocab.languageId,
      status: statusFor(vocab.word),
      createdAt: createdAt,
      nextReviewAt: DateTime(9999),
      reviewCount: 0,
      fromLearningItem: false,
    );
  }

  List<WordbookSourceSummary> _sourceSummaries(List<WordbookEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      counts.update(entry.sourceTitle, (value) => value + 1, ifAbsent: () => 1);
    }
    final summaries = counts.entries
        .map(
          (entry) => WordbookSourceSummary(
            title: entry.key,
            wordCount: entry.value,
          ),
        )
        .toList();
    summaries.sort((a, b) {
      final countCompare = b.wordCount.compareTo(a.wordCount);
      if (countCompare != 0) return countCompare;
      return a.title.compareTo(b.title);
    });
    return summaries;
  }

  int _reviewStreakDays(List<LearningItem> items, DateTime now) {
    final reviewDays = items
        .where((item) => item.lastResult != LearningReviewResult.newItem)
        .map((item) => _dayKey(item.updatedAt))
        .toSet();
    var cursor = DateTime(now.year, now.month, now.day);
    var streak = 0;
    while (reviewDays.contains(_dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static bool _isReviewable(LearningItem item) {
    if (item.type == LearningItemType.questionMistake) {
      return item.content.trim().isNotEmpty && item.answer.trim().isNotEmpty;
    }
    return item.title.trim().isNotEmpty || item.content.trim().isNotEmpty;
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _chapterLabel(int index) {
    return index >= 0 ? 'Ch.${index + 1}' : '';
  }

  static DateTime _tomorrow(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }

  static String _dayKey(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.toIso8601String();
  }
}
