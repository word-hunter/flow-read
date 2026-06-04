import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_text_analysis.dart';
import '../../models/learning_item.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class TextSelectionController {
  const TextSelectionController(this._reader);

  final ReadingProvider _reader;

  AITextAnalysis? get aiTextAnalysis => _reader.aiTextAnalysis;
  bool get isAnalyzingText => _reader.isAnalyzingText;
  String? get errorMessage => _reader.errorMessage;
  bool get canCreateLearningItems => _reader.canCreateLearningItems;

  Future<LearningItemSaveResult?> addSelectedTextLearningItem() {
    return _reader.addSelectedTextLearningItem();
  }

  Future<LearningItemSaveResult?> addAIVocabularyLearningItem(
    VocabularyNote note,
  ) {
    return _reader.addAIVocabularyLearningItem(note);
  }

  Future<LearningItemSaveResult?> addAIGrammarLearningItem(
    GrammarPoint point,
  ) {
    return _reader.addAIGrammarLearningItem(point);
  }

  Future<LearningItemSaveResult?> addAIExpressionLearningItem(
    ExpressionNote note,
  ) {
    return _reader.addAIExpressionLearningItem(note);
  }
}

final textSelectionProvider = Provider<TextSelectionController>((ref) {
  return TextSelectionController(ref.watch(readingProvider));
});
