import '../models/analysis_result.dart';
import '../models/review_question.dart';

class ReviewService {
  static final List<String> _questionPool = [
    'What clue did the protagonist discover?',
    'What was the protagonist\'s emotional state at the beginning of this chapter?',
    'What decision or action does the protagonist take?',
    'What is the relationship between the main characters revealed here?',
    'What detail suggests something is wrong or suspicious?',
    'How does the setting contribute to the mood of this chapter?',
    'What does the dialogue reveal about the character\'s intentions?',
    'What is the turning point in this chapter?',
    'How does the author build tension in this passage?',
    'What internal conflict does the protagonist face?',
  ];

  static final List<String> _hintPool = [
    'Look for objects, letters, or statements that reveal new information.',
    'Pay attention to words describing feelings like fear, anger, confusion.',
    'Identify the key action the character takes in response to events.',
    'Notice how characters interact with each other — are they allies or opponents?',
    'Look for details that seem out of place or create unease.',
    'Consider the weather, location, and time — how do they affect the scene?',
    'Dialogue often hides or reveals true intentions — read between the lines.',
    'Find the moment when the story shifts direction or tension peaks.',
    'Notice how the author uses pacing, word choice, and sentence length.',
    'What is the character struggling with internally?',
  ];

  static List<ReviewQuestion> generateQuestions(AnalysisResult result) {
    final sentences = result.passageText
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final questions = <ReviewQuestion>[];
    final usedIndices = <int>{};

    for (int i = 0; i < 3 && i < _questionPool.length; i++) {
      int idx = i;
      if (i < sentences.length && !usedIndices.contains(i)) {
        idx = i;
      } else {
        idx = i % _questionPool.length;
      }
      usedIndices.add(idx);

      questions.add(ReviewQuestion(
        id: 'q_$i',
        question: _questionPool[idx % _questionPool.length],
        hint: _hintPool[idx % _hintPool.length],
        isCompleted: false,
      ));
    }

    return questions;
  }
}
