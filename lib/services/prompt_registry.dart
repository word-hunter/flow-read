import '../models/ai_summary.dart';

class PromptRegistry {
  // ============================================================
  // 1. Text Analysis
  // ============================================================

  static const textAnalysisSystem =
      'You are an English reading tutor helping Chinese speakers understand English novels. '
      'Analyze ONLY the provided text. Do NOT reference any external knowledge about the book or author. '
      'Every analysis point MUST cite the exact source text. '
      'Explain grammar and vocabulary in Chinese (Simplified). '
      'If you are unsure about any point, skip it entirely.';

  static String textAnalysisUser(
    String selectedText,
    String contextBefore,
    String contextAfter,
  ) {
    return '''## Selected Text
"$selectedText"

## Context Before (for reference only)
"$contextBefore"

## Context After (for reference only)
"$contextAfter"

## Output Format (strict JSON)
{
  "translation": "Contextual Chinese translation that preserves literary feel",
  "grammar_points": [
    {
      "source": "exact phrase from the selected text",
      "explanation": "Grammar explanation in Chinese — what structure it is, why it's used here, how to parse it",
      "difficulty": "easy|medium|hard"
    }
  ],
  "vocabulary_notes": [
    {
      "word": "word from text",
      "context_meaning": "What this word means IN THIS context (Chinese), not the dictionary definition",
      "pos": "part of speech (noun/verb/adj/adv/prep/conj)"
    }
  ],
  "reading_tip": "One key insight to understand this passage (1-2 sentences in Chinese)"
}

## Rules
- Each grammar_point.source must be a substring of the selected text
- Each vocabulary_note.word must appear in the selected text
- Limit grammar_points to at most 3
- Limit vocabulary_notes to at most 5
- Only include words that a Chinese English learner might not know
- Do NOT add information that does not exist in the text''';
  }

  // ============================================================
  // 1b. Translation Only
  // ============================================================

  static const translationSystem =
      'You are a literary translator. Translate the given English text into natural, flowing Chinese. '
      'Preserve the literary style, tone, and voice of the original. '
      'Do NOT add explanations or notes — output ONLY the translation.';

  static String translationUser(String selectedText) {
    return '''Translate the following English text into Chinese. 
Preserve literary style and tone. Output only the translation, no explanations.

Text:
$selectedText''';
  }

  // ============================================================
  // 2. Chapter Summary
  // ============================================================

  static String summarySystem(String language) {
    final lang = language == 'zh' ? 'Chinese (Simplified)' : 'English';
    return 'You are an English reading tutor. Summarize the given chapter text. '
        'You MUST ONLY use information from the provided text. '
        'Every event or analysis point MUST cite the exact original English sentence it comes from. '
        'If something is not explicitly stated in the text, mark it with confidence: "low" or do not include it. '
        'Output in $lang. '
        'Do NOT reference any prior knowledge about this book, author, or cultural context.';
  }

  static String summaryUser(
    String chapterText,
    List<String> vocabulary,
    String language,
  ) {
    final vocabList = vocabulary.take(30).join(', ');
    final langName = language == 'zh' ? 'Chinese (Simplified)' : 'English';

    return '''## Chapter Text
$chapterText

## Key Vocabulary to Focus On
$vocabList

## Output Format (strict JSON)
{
  "events": [
    {
      "description": "What happened ($langName)",
      "source": "Original English sentence from the text",
      "significance": "Why this event matters ($langName)",
      "confidence": "high|medium|low"
    }
  ],
  "character_developments": [
    {
      "character": "Character name (English)",
      "change": "How this character changed/developed in this chapter ($langName)",
      "source": "Original English sentence from the text",
      "confidence": "high|medium|low"
    }
  ],
  "key_vocabulary": [
    {
      "word": "Word from the text",
      "sentence": "The original English sentence containing this word",
      "meaning_in_context": "What this word means in this context ($langName)",
      "why_important": "Why understanding this word helps understand the chapter ($langName)"
    }
  ],
  "reading_guidance": "1-2 sentences of reading advice ($langName)"
}

## Rules
- At most 8 events, in chronological order as they appear in the text
- Each event description must be directly inferable from its source
- Mark uncertain points as confidence: "low"
- Do NOT add events, characters, or details not present in the text
- vocabularies: focus on key_vocabulary that are important for understanding the chapter, limit to at most 8 words
- If there are fewer than 8 important events, output fewer — do not fabricate''';
  }

  // ============================================================
  // 3. Practice Questions
  // ============================================================

  static const practiceSystem =
      'You are an English reading tutor. Generate multiple-choice comprehension questions based on the chapter text. '
      'Every question MUST have a unique, verifiable answer in the provided text. '
      'Distractors (wrong options) must look plausible but be clearly wrong based on the text. '
      'Explain in Chinese why each distractor is wrong. '
      'Generate questions in English. '
      'Do NOT create questions that cannot be answered from the text.';

  static String practiceUser(
    String chapterText,
    List<String> vocabulary,
    List<SummaryEvent> events,
  ) {
    final vocabList = vocabulary.take(30).join(', ');
    final eventsJson = events.map((e) => e.description).join('; ');

    return '''## Chapter Text
$chapterText

## Key Events (for reference)
$eventsJson

## Vocabulary List (for reference)
$vocabList

## Output Format (strict JSON)
{
  "questions": [
    {
      "type": "detail|vocabulary|inference|grammar",
      "question": "Question in English",
      "source": "The original English sentence that contains the answer",
      "answer": "The correct answer in English",
      "answer_explanation": "Explanation of why this is correct (Chinese)",
      "distractors": [
        {"text": "Wrong option A (English)", "why_wrong": "Why A is wrong (Chinese)"},
        {"text": "Wrong option B (English)", "why_wrong": "Why B is wrong (Chinese)"},
        {"text": "Wrong option C (English)", "why_wrong": "Why C is wrong (Chinese)"}
      ],
      "difficulty": "easy|medium|hard"
    }
  ]
}

## Question Type Requirements
- "detail": Tests knowledge of explicit facts from the text. Answer IS directly stated.
- "vocabulary": Tests understanding of a vocabulary word in context. Target word must be from the vocabulary list.
- "inference": Tests ability to infer meaning. Answer must be reasonably deducible from the text.
- "grammar": Tests understanding of a grammar structure used in the text.

## Rules
- Each type (detail, vocabulary, inference, grammar) must have at least 1 question
- Total questions: at least 4, at most 8
- Every distractor must have a why_wrong explanation
- source must be a real sentence from the chapter text
- Do NOT create questions about things not in the text''';
  }

  // ============================================================
  // 4. Word Deep Analysis
  // ============================================================

  static const wordAnalysisSystem =
      'You are an English vocabulary tutor helping Chinese speakers. '
      'Analyze the given word as it is used in the provided sentence and chapter context. '
      'Focus on practical understanding and memory aids. '
      'Use Chinese for explanations. '
      'Do NOT use knowledge unrelated to the provided context.';

  static String wordAnalysisUser(
    String word,
    String sentence,
    String chapterContext,
  ) {
    return '''## Word
$word

## Sentence (how it appears)
"$sentence"

## Chapter Context (surrounding text)
"$chapterContext"

## Output Format (strict JSON)
{
  "pronunciation": "Phonetic notation (IPA)",
  "meanings": [
    {
      "meaning": "Meaning of this word IN THIS SENTENCE (Chinese, with English equivalent)",
      "explanation": "Deeper explanation — why the author used this word instead of a simpler alternative, what nuance it carries (Chinese)"
    }
  ],
  "usage_tips": [
    "Tip 1 about usage (Chinese)",
    "Tip 2 about usage (Chinese)"
  ],
  "memory_tip": "A memorable way to remember this word — could be etymology, association, or mnemonic (Chinese)"
}

## Rules
- Focus on the word as used in THIS context, not generic dictionary definitions
- Memory tip should be practical and creative
- Usage tips should help the learner use this word correctly in writing''';
  }
}
