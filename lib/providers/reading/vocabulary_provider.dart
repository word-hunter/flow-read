import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/aggregated_vocabulary.dart';
import '../../models/book_difficulty.dart';
import '../../models/learning_analytics.dart';
import '../../models/learning_item.dart';
import '../../models/user_vocabulary.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class VocabularyController {
  const VocabularyController(this._reader);

  final ReadingProvider _reader;

  int get wordMasteredCelebrationTick => _reader.wordMasteredCelebrationTick;
  String? get wordMasteredCelebrationWord =>
      _reader.wordMasteredCelebrationWord;
  Offset? get wordMasteredCelebrationOrigin =>
      _reader.wordMasteredCelebrationOrigin;
  int get totalVocabularyCount => _reader.totalVocabularyCount;
  List<LearningItem> get learningItems => _reader.learningItems;
  int get knownWordCount => _reader.userVocabulary?.knownWords.length ?? 0;
  int get learningWordCount =>
      _reader.userVocabulary?.learningWords.length ?? 0;
  BookDifficultyRating? get currentBookDifficulty =>
      _reader.currentBookDifficulty;
  ChapterLearningReport? get currentChapterLearningReport =>
      _reader.currentChapterLearningReport;
  WeeklyLearningSummary? get weeklyLearningSummary =>
      _reader.weeklyLearningSummary;

  List<AggregatedVocabulary> getAllVocabulary({bool alphabetical = false}) {
    return _reader.getAllVocabulary(alphabetical: alphabetical);
  }

  UserWordStatus? getWordStatus(String word) {
    return _reader.getWordStatus(word);
  }

  Future<void> markWordKnown(String word, {Offset? celebrationOrigin}) {
    return _reader.markWordKnown(word, celebrationOrigin: celebrationOrigin);
  }

  Future<void> markWordLearning(String word) {
    return _reader.markWordLearning(word);
  }

  Future<void> markWordUnknown(String word) {
    return _reader.markWordUnknown(word);
  }

  Future<void> deleteLearningItem(String id) {
    return _reader.deleteLearningItem(id);
  }
}

final vocabularyProvider = Provider<VocabularyController>((ref) {
  return VocabularyController(ref.watch(readingProvider));
});
