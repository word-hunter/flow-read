import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_practice_questions.dart';
import '../../models/learning_item.dart';
import '../../services/review_schedule_service.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class LearningController {
  const LearningController(this._reader);

  final ReadingProvider _reader;

  List<LearningItem> get learningItems => _reader.learningItems;
  List<LearningReviewCard> get todayReviewCards => _reader.todayReviewCards;

  Future<void> recordPracticeAnswer({required bool isCorrect}) {
    return _reader.recordPracticeAnswer(isCorrect: isCorrect);
  }

  Future<LearningItemSaveResult?> addPracticeMistakeLearningItem(
    PracticeQuestion question,
    String selectedAnswer,
  ) {
    return _reader.addPracticeMistakeLearningItem(question, selectedAnswer);
  }

  Future<void> recordLearningReview(
    String itemId,
    LearningReviewResult result,
  ) {
    return _reader.recordLearningReview(itemId, result);
  }

  Future<void> deleteLearningItem(String id) {
    return _reader.deleteLearningItem(id);
  }
}

final learningProvider = Provider<LearningController>((ref) {
  return LearningController(ref.watch(readingProvider));
});
