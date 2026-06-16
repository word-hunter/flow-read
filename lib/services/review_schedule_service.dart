import '../models/learning_item.dart';
import 'learning_item_service.dart';
import 'reading_memory/reading_memory_service.dart';
import 'user_vocabulary_service.dart';

enum LearningReviewCardType {
  contextMeaning,
  fillBlank,
  meaningToWord,
  questionMistake,
}

extension LearningReviewCardTypeLabel on LearningReviewCardType {
  String get label {
    return switch (this) {
      LearningReviewCardType.contextMeaning => '语境选义',
      LearningReviewCardType.fillBlank => '原句挖空',
      LearningReviewCardType.meaningToWord => '看中文选英文',
      LearningReviewCardType.questionMistake => '错题',
    };
  }
}

class LearningReviewCard {
  final LearningItem item;
  final LearningReviewCardType type;
  final String studyGoal;
  final String prompt;
  final String answer;
  final String explanation;
  final String sourceText;
  final List<String> options;

  const LearningReviewCard({
    required this.item,
    required this.type,
    required this.studyGoal,
    required this.prompt,
    required this.answer,
    required this.explanation,
    required this.sourceText,
    this.options = const [],
  });
}

class ReviewScheduleService {
  ReviewScheduleService(
    this._learningItems, {
    DateTime Function()? clock,
    this.sessionLimit = 10,
    ReadingMemoryService? readingMemory,
    UserVocabularyService? userVocabulary,
  }) : _clock = clock ?? DateTime.now,
       _readingMemory = readingMemory,
       _userVocabulary = userVocabulary;

  final LearningItemService _learningItems;
  final DateTime Function() _clock;
  final int sessionLimit;
  final ReadingMemoryService? _readingMemory;
  final UserVocabularyService? _userVocabulary;

  int dueCount({DateTime? now}) {
    return _dueItems(now: now, limit: null).length;
  }

  List<LearningItem> dueItems({DateTime? now, int? limit}) {
    return _dueItems(now: now, limit: limit ?? sessionLimit);
  }

  List<LearningReviewCard> buildSessionCards({DateTime? now, int? limit}) {
    final items = dueItems(now: now, limit: limit);
    return items
        .asMap()
        .entries
        .map((entry) => _buildCard(entry.value, entry.key, items))
        .whereType<LearningReviewCard>()
        .take(limit ?? sessionLimit)
        .toList(growable: false);
  }

  Future<LearningItem?> recordReview(
    String id,
    LearningReviewResult result, {
    DateTime? reviewedAt,
  }) async {
    final item = _learningItems.getById(id);
    if (item == null) return null;

    final now = reviewedAt ?? _clock();
    final nextCount = result.isSuccessful
        ? item.reviewCount + 1
        : item.reviewCount;
    final updated = item.copyWith(
      updatedAt: now,
      nextReviewAt: _nextReviewAt(
        now: now,
        result: result,
        reviewCount: nextCount,
      ),
      reviewCount: nextCount,
      lastResult: result,
    );
    await _learningItems.saveItem(updated);
    await _recordVocabularyResult(updated, result);
    await _readingMemory?.recordLearningReview(item: updated, result: result);
    return updated;
  }

  List<LearningItem> _dueItems({DateTime? now, int? limit}) {
    final effectiveNow = now ?? _clock();
    final tomorrow = DateTime(
      effectiveNow.year,
      effectiveNow.month,
      effectiveNow.day + 1,
    );
    final items = _learningItems.allItems
        .where((item) => _isReviewable(item))
        .where((item) => item.nextReviewAt.isBefore(tomorrow))
        .toList();

    items.sort((a, b) {
      final dueCompare = a.nextReviewAt.compareTo(b.nextReviewAt);
      if (dueCompare != 0) return dueCompare;
      final reviewCompare = a.reviewCount.compareTo(b.reviewCount);
      if (reviewCompare != 0) return reviewCompare;
      return a.createdAt.compareTo(b.createdAt);
    });

    if (limit == null || items.length <= limit) return items;
    return items.take(limit).toList(growable: false);
  }

  bool _isReviewable(LearningItem item) {
    if (item.type == LearningItemType.questionMistake) {
      return item.content.trim().isNotEmpty && item.answer.trim().isNotEmpty;
    }
    return item.title.trim().isNotEmpty || item.content.trim().isNotEmpty;
  }

  LearningReviewCard? _buildCard(
    LearningItem item,
    int index,
    List<LearningItem> sessionItems,
  ) {
    if (item.type == LearningItemType.questionMistake) {
      return LearningReviewCard(
        item: item,
        type: LearningReviewCardType.questionMistake,
        studyGoal: '回看章节练习中的错题，确认你能用原文依据修正理解。',
        prompt: item.content,
        answer: item.answer,
        explanation: item.note,
        sourceText: item.sourceText,
      );
    }

    final blank = _blankSource(item);
    final type = _cardTypeFor(item, index, canFillBlank: blank != null);
    if (type == LearningReviewCardType.fillBlank && blank != null) {
      return LearningReviewCard(
        item: item,
        type: LearningReviewCardType.fillBlank,
        studyGoal: _studyGoal(item),
        prompt: blank,
        answer: item.content.trim().isNotEmpty ? item.content : item.title,
        explanation: _explanation(item),
        sourceText: item.sourceText,
      );
    }

    final title = item.title.trim().isNotEmpty ? item.title : item.content;
    if (type == LearningReviewCardType.meaningToWord) {
      return LearningReviewCard(
        item: item,
        type: LearningReviewCardType.meaningToWord,
        studyGoal: _studyGoal(item),
        prompt: _meaningPrompt(item),
        answer: title,
        explanation: _explanation(item),
        sourceText: item.sourceText,
        options: _wordOptions(item, sessionItems),
      );
    }

    return LearningReviewCard(
      item: item,
      type: LearningReviewCardType.contextMeaning,
      studyGoal: _studyGoal(item),
      prompt: _contextMeaningPrompt(item, title),
      answer: item.answer.trim().isNotEmpty ? item.answer : item.note,
      explanation: _explanation(item),
      sourceText: item.sourceText,
      options: _meaningOptions(item, sessionItems),
    );
  }

  String _studyGoal(LearningItem item) {
    if (item.type == LearningItemType.grammar) {
      return '练习已沉淀的语法片段，确认能在原句中主动复现。';
    }
    if (item.type == LearningItemType.expression) {
      return '练习已沉淀的表达片段，确认能从上下文中说出原文。';
    }
    if (item.type == LearningItemType.sentence) {
      return '练习已沉淀的句段，确认能回忆核心表达和意思。';
    }
    if (item.tags.contains('ai')) {
      return '练习 AI 解析中标出的语境词义，确认离开解释后仍能回忆。';
    }
    return '练习查词后加入的语境词义，确认你能在原文中理解和回忆。';
  }

  String _explanation(LearningItem item) {
    final answer = item.answer.trim();
    if (item.type == LearningItemType.word) return '';
    if (answer.isNotEmpty && answer != item.content.trim()) return answer;

    final note = item.note.trim();
    if (_isDifficultyLabel(note)) return '';
    return note;
  }

  bool _isDifficultyLabel(String value) {
    final normalized = value.toLowerCase();
    return normalized == 'easy' ||
        normalized == 'medium' ||
        normalized == 'hard';
  }

  String? _blankSource(LearningItem item) {
    final source = item.sourceText.trim();
    if (source.isEmpty) return null;

    final target = item.content.trim().isNotEmpty
        ? item.content.trim()
        : item.title.trim();
    if (target.isEmpty) return null;

    final pattern = RegExp(RegExp.escape(target), caseSensitive: false);
    if (!pattern.hasMatch(source)) return null;
    return source.replaceFirst(pattern, '______');
  }

  DateTime _nextReviewAt({
    required DateTime now,
    required LearningReviewResult result,
    required int reviewCount,
  }) {
    if (result == LearningReviewResult.forgotten ||
        result == LearningReviewResult.missed) {
      return now.add(const Duration(hours: 6));
    }
    if (result == LearningReviewResult.vague) {
      return now.add(const Duration(days: 1));
    }
    if (result == LearningReviewResult.mastered) {
      return now.add(const Duration(days: 30));
    }

    final days = reviewCount <= 1
        ? 1
        : reviewCount == 2
        ? 3
        : reviewCount == 3
        ? 7
        : 14;
    return now.add(Duration(days: days));
  }

  LearningReviewCardType _cardTypeFor(
    LearningItem item,
    int index, {
    required bool canFillBlank,
  }) {
    if (item.type != LearningItemType.word) {
      return canFillBlank
          ? LearningReviewCardType.fillBlank
          : LearningReviewCardType.contextMeaning;
    }

    final slot = (item.reviewCount + index) % 3;
    return switch (slot) {
      0 when canFillBlank => LearningReviewCardType.fillBlank,
      1 => LearningReviewCardType.contextMeaning,
      _ => LearningReviewCardType.meaningToWord,
    };
  }

  String _contextMeaningPrompt(LearningItem item, String title) {
    final source = item.sourceText.trim();
    if (source.isEmpty) return '选择 "$title" 在当前阅读材料中的含义。';
    return '在这句中，"$title" 最接近哪种含义？\n$source';
  }

  String _meaningPrompt(LearningItem item) {
    final meaning = _firstNonEmpty([item.answer, item.note, item.content]);
    if (meaning.isEmpty) return '根据释义选择对应的英文单词。';
    return '选择与这个释义对应的英文单词：$meaning';
  }

  List<String> _meaningOptions(
    LearningItem item,
    List<LearningItem> sessionItems,
  ) {
    final answer = _firstNonEmpty([item.answer, item.note]);
    if (answer.isEmpty) return const [];
    final distractors = sessionItems
        .where((candidate) => candidate.id != item.id)
        .map((candidate) => _firstNonEmpty([candidate.answer, candidate.note]))
        .where((value) => value.isNotEmpty && value != answer)
        .toList();
    return _options(answer, distractors);
  }

  List<String> _wordOptions(
    LearningItem item,
    List<LearningItem> sessionItems,
  ) {
    final answer = _firstNonEmpty([
      item.title,
      item.content,
      item.canonicalKey,
    ]);
    if (answer.isEmpty) return const [];
    final distractors = sessionItems
        .where((candidate) => candidate.id != item.id)
        .where((candidate) => candidate.type == LearningItemType.word)
        .map(
          (candidate) => _firstNonEmpty([
            candidate.title,
            candidate.content,
            candidate.canonicalKey,
          ]),
        )
        .where((value) => value.isNotEmpty && value != answer)
        .toList();
    return _options(answer, distractors);
  }

  List<String> _options(String answer, List<String> distractors) {
    final unique = <String>[answer];
    for (final value in distractors) {
      if (unique.length >= 4) break;
      if (!unique.contains(value)) unique.add(value);
    }
    unique.sort();
    return unique;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  Future<void> _recordVocabularyResult(
    LearningItem item,
    LearningReviewResult result,
  ) async {
    if (item.type != LearningItemType.word) return;
    final vocabulary = _userVocabulary;
    if (vocabulary == null) return;

    final word = _firstNonEmpty([item.canonicalKey, item.title, item.content]);
    if (word.isEmpty) return;
    if (result == LearningReviewResult.mastered) {
      await vocabulary.setKnown(word);
      return;
    }
    if (result == LearningReviewResult.forgotten ||
        result == LearningReviewResult.vague ||
        result == LearningReviewResult.missed) {
      await vocabulary.setLearning(word);
    }
  }
}
