import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/learning_item.dart';
import '../../services/review_schedule_service.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class LearningController {
  const LearningController(this._reader);

  final ReadingProvider _reader;

  List<LearningReviewCard> get todayReviewCards => _reader.todayReviewCards;

  Future<void> recordLearningReview(
    String itemId,
    LearningReviewResult result,
  ) {
    return _reader.recordLearningReview(itemId, result);
  }
}

final learningProvider = Provider<LearningController>((ref) {
  return LearningController(ref.watch(readingProvider));
});
