import '../models/analysis_result.dart';
import '../models/book.dart';
import '../models/book_difficulty.dart';
import '../models/word_level.dart';
import '../theme/app_constants.dart';
import 'language/english_language_module.dart';
import 'language/language_module.dart';
import 'language/language_registry.dart';
import 'user_vocabulary_service.dart';
import 'word_level_service.dart';

class AnalysisService {
  static AnalysisResult analyzeChapter(
    String title,
    String text, [
    UserVocabularyService? userVocab,
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final sentences = _splitSentences(text, lm);
    final words = _extractWords(text, lm);

    final vocabulary = _analyzeVocabulary(
      words,
      userVocab,
      wordLevelService,
      lm,
    );
    final knownWords = _extractKnownWords(
      words,
      userVocab,
      wordLevelService,
      lm,
    );
    final learningWords = _extractLearningWords(
      words,
      userVocab,
      wordLevelService,
      lm,
    );
    final syntaxPatterns = _analyzeSyntax(sentences, lm);
    final comprehension = _buildComprehension(
      sentences,
      vocabulary,
      syntaxPatterns,
    );
    final practice = _buildPractice(sentences, vocabulary, syntaxPatterns);
    final difficulty = _calculateDifficulty(
      vocabulary,
      syntaxPatterns,
      sentences,
    );

    return AnalysisResult(
      passageText: text,
      title: title,
      vocabulary: vocabulary,
      knownWords: knownWords,
      learningWords: learningWords,
      syntaxPatterns: syntaxPatterns,
      comprehension: comprehension,
      practice: practice,
      difficulty: difficulty,
    );
  }

  static LanguageModule _resolveLanguageModule(LanguageModule? module) {
    return module ??
        LanguageRegistry.instance.defaultModule ??
        const EnglishLanguageModule();
  }

  static List<String> _splitSentences(String text, LanguageModule lm) {
    return lm.splitSentences(text).where((s) => s.trim().isNotEmpty).toList();
  }

  static List<String> _extractWords(String text, LanguageModule lm) {
    return lm.tokenize(text);
  }

  static Set<String> collectStudyWords(
    String text, [
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final result = <String>{};
    for (final word in _extractWords(text, lm)) {
      final lower = _canonicalWord(word, wordLevelService, lm);
      if (!_isStudyWord(lower, lm)) continue;
      result.add(lower);
    }
    return result;
  }

  static BookDifficultyRating analyzeBookDifficulty(
    Book book, [
    UserVocabularyService? userVocab,
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    return rateBookDifficulty(
      collectBookStudyWords(book, wordLevelService, languageModule),
      userVocab,
    );
  }

  static Set<String> collectBookStudyWords(
    Book book, [
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final studyWords = <String>{};
    for (final chapter in book.chapters) {
      studyWords.addAll(
        collectStudyWords(chapter.plainText, wordLevelService, lm),
      );
    }
    return studyWords;
  }

  static BookDifficultyRating rateBookDifficulty(
    Set<String> studyWords, [
    UserVocabularyService? userVocab,
  ]) {
    var masteredWordCount = 0;
    var learningWordCount = 0;
    var newWordCount = 0;
    for (final word in studyWords) {
      if (userVocab?.isKnown(word) ?? false) {
        masteredWordCount += 1;
      } else if (userVocab?.isLearning(word) ?? false) {
        learningWordCount += 1;
      } else {
        newWordCount += 1;
      }
    }

    final userKnownWordCount = userVocab?.knownWords.length ?? 0;
    final weightedNewWordCount = newWordCount + learningWordCount * 0.5;
    final newWordToKnownRatio = userKnownWordCount <= 0
        ? (weightedNewWordCount > 0 ? 1.0 : 0.0)
        : weightedNewWordCount / userKnownWordCount;
    final level = BookDifficultyLevel.resolve(
      weightedNewWordCount: weightedNewWordCount,
      newWordToKnownRatio: newWordToKnownRatio,
    );
    final score = (newWordToKnownRatio / 0.25 * 100)
        .round()
        .clamp(0, 100)
        .toInt();

    return BookDifficultyRating(
      studyWordCount: studyWords.length,
      masteredWordCount: masteredWordCount,
      userKnownWordCount: userKnownWordCount,
      learningWordCount: learningWordCount,
      newWordCount: newWordCount,
      weightedNewWordCount: weightedNewWordCount,
      newWordToKnownRatio: newWordToKnownRatio,
      score: score,
      level: level,
    );
  }

  static List<Vocabulary> _analyzeVocabulary(
    List<String> words, [
    UserVocabularyService? userVocab,
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final result = <Vocabulary>[];
    final seen = <String>{};

    for (final word in words) {
      final lower = _canonicalWord(word, wordLevelService, lm);
      if (!_isStudyWord(lower, lm) || seen.contains(lower)) continue;

      if (userVocab != null && userVocab.isKnown(lower)) continue;

      seen.add(lower);

      final context = _extractContext(words, word, wordLevelService, lm);
      final meaning = _generateSimpleMeaning(lower, lm);
      double familiarity = userVocab != null && userVocab.isLearning(lower)
          ? 0.45
          : 0.2;

      String? levelLabel;
      if (wordLevelService != null && wordLevelService.hasWord(lower)) {
        final level = wordLevelService.getLevel(lower);
        levelLabel = level.label;
        familiarity = _adjustFamiliarityByLevel(familiarity, level);
      }

      result.add(
        Vocabulary(
          word: lower,
          meaning: meaning,
          context: context,
          familiarity: familiarity,
          level: levelLabel,
        ),
      );
    }

    result.sort((a, b) => a.familiarity.compareTo(b.familiarity));

    return result;
  }

  static double _adjustFamiliarityByLevel(double base, LevelKey level) {
    final score = level.difficultyScore;
    // Lower familiarity = more difficult, so higher difficulty score = lower familiarity
    return (base * (0.5 + score * 0.07)).clamp(0.05, 0.95);
  }

  static Set<String> _extractKnownWords(
    List<String> words, [
    UserVocabularyService? userVocab,
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    if (userVocab == null) return {};
    final seen = <String>{};
    for (final w in words) {
      final lower = _canonicalWord(w, wordLevelService, lm);
      if (lower.length < AppConstants.minWordLength) continue;
      if (seen.contains(lower)) continue;
      if (userVocab.isKnown(lower)) {
        seen.add(lower);
      }
    }
    return seen;
  }

  static Set<String> _extractLearningWords(
    List<String> words, [
    UserVocabularyService? userVocab,
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    if (userVocab == null) return {};
    final seen = <String>{};
    for (final w in words) {
      final lower = _canonicalWord(w, wordLevelService, lm);
      if (lower.length < AppConstants.minWordLength) continue;
      if (seen.contains(lower)) continue;
      if (userVocab.isLearning(lower)) {
        seen.add(lower);
      }
    }
    return seen;
  }

  static String _extractContext(
    List<String> allWords,
    String targetWord, [
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final targetCanonical = _canonicalWord(targetWord, wordLevelService, lm);
    final idx = allWords.indexWhere(
      (w) => _canonicalWord(w, wordLevelService, lm) == targetCanonical,
    );
    if (idx == -1) return targetWord;

    final start = (idx - 4).clamp(0, allWords.length);
    final end = (idx + 5).clamp(0, allWords.length);
    final context = allWords.sublist(start, end).join(' ');

    return '...$context...';
  }

  static String _canonicalWord(
    String word, [
    WordLevelService? wordLevelService,
    LanguageModule? languageModule,
  ]) {
    final lm = _resolveLanguageModule(languageModule);
    final canonical = lm.canonicalize(word);
    if (canonical.isEmpty) return canonical;
    return wordLevelService?.canonicalForm(canonical) ?? canonical;
  }

  static bool _isStudyWord(String word, LanguageModule lm) {
    if (word.length < AppConstants.minWordLength) return false;
    if (lm.isCommonWord(word, maxLength: 6)) return false;
    return true;
  }

  static String _generateSimpleMeaning(String word, LanguageModule lm) {
    if (word.endsWith('ing') && word.length > 6) {
      final base = word.substring(0, word.length - 3);
      if (base.endsWith('nn')) {
        final root = base.substring(0, base.length - 1);
        return 'Present participle of "$root"';
      }
      if (base.endsWith(base[base.length - 1])) {
        final root = base.substring(0, base.length - 1);
        if (lm.isCommonWord(root)) return 'Present participle of "$root"';
      }
      if (lm.isCommonWord(base)) return 'Present participle of "$base"';
    }
    if (word.endsWith('ly') && word.length > 5) {
      final base = word.substring(0, word.length - 2);
      if (lm.isCommonWord(base)) return 'Adverb form of "$base"';
    }
    if (word.endsWith('ment') ||
        word.endsWith('tion') ||
        word.endsWith('sion')) {
      return '(noun) Tap for full definition';
    }
    if (word.endsWith('ous') ||
        word.endsWith('ive') ||
        word.endsWith('ful') ||
        word.endsWith('less')) {
      return '(adjective) Tap for full definition';
    }

    return 'Tap to look up definition';
  }

  static List<SyntaxPattern> _analyzeSyntax(
    List<String> sentences,
    LanguageModule lm,
  ) {
    final patterns = <SyntaxPattern>[];

    for (final sentence in sentences) {
      final words = sentence.trim().split(RegExp(r'\s+'));
      final wordCount = words.length;
      final lower = sentence.toLowerCase();

      if (wordCount > AppConstants.longSentenceThreshold) {
        patterns.add(
          SyntaxPattern(
            type: 'long_sentence',
            originalSentence: sentence.trim(),
            simplifiedSentence: '(This sentence contains $wordCount words)',
            explanation:
                'This is a complex sentence with $wordCount words. '
                'Long sentences often contain multiple clauses and ideas. '
                'Try breaking it down into smaller parts to understand each piece.',
          ),
        );
        continue;
      }

      for (final marker in lm.subordinatingMarkers) {
        if (lower.contains(' $marker ')) {
          patterns.add(
            SyntaxPattern(
              type: '${marker}_clause',
              originalSentence: sentence.trim(),
              simplifiedSentence:
                  '(Contains a subordinate clause with "$marker")',
              explanation:
                  'This sentence uses "$marker" to introduce a subordinate clause. '
                  'The part after "$marker" provides additional context or explanation '
                  'for the main idea.',
            ),
          );
          break;
        }
      }
    }

    if (patterns.length > AppConstants.syntaxLimit) {
      return patterns.take(AppConstants.syntaxLimit).toList();
    }
    return patterns;
  }

  static Comprehension _buildComprehension(
    List<String> sentences,
    List<Vocabulary> vocabulary,
    List<SyntaxPattern> syntax,
  ) {
    final wordCount = sentences.join(' ').split(RegExp(r'\s+')).length;
    final sentenceCount = sentences.length;

    return Comprehension(
      whatHappened:
          'This passage contains $sentenceCount sentences with approximately $wordCount words. '
          '${vocabulary.length} vocabulary words were identified for your study.',
      whyHappened:
          'The text was analyzed for vocabulary difficulty and sentence complexity. '
          'Words not in the common English vocabulary were flagged as study targets. '
          'Long or syntactically complex sentences were identified for syntax analysis.',
      implicitMeaning:
          'Reading this passage will help you expand your vocabulary by ${vocabulary.length} words '
          'and improve your understanding of complex sentence structures. '
          'Try reading each highlighted word in context and use the built-in dictionary '
          'to look up unfamiliar terms.',
    );
  }

  static List<Practice> _buildPractice(
    List<String> sentences,
    List<Vocabulary> vocabulary,
    List<SyntaxPattern> syntax,
  ) {
    final practice = <Practice>[];

    if (vocabulary.isNotEmpty) {
      final v = vocabulary.first;
      practice.add(
        Practice(
          type: 'vocabulary_in_context',
          question:
              'Look at the word "${v.word}" in the passage. '
              'Based on the context, what do you think it means before looking it up?',
          expectedReasoning:
              'Context clue: "${v.context}". '
              'Try to infer the meaning from the surrounding words, then use the dictionary to verify.',
        ),
      );
    }

    if (vocabulary.length > 1) {
      final v = vocabulary[1];
      practice.add(
        Practice(
          type: 'vocabulary_in_context',
          question:
              'Find the word "${v.word}" in the text. '
              'What part of speech is it, and how does it function in its sentence?',
          expectedReasoning:
              'Identify if "${v.word}" is a noun, verb, adjective, or adverb based on its '
              'position and ending. Look at the words around it for clues.',
        ),
      );
    }

    if (syntax.isNotEmpty) {
      practice.add(
        Practice(
          type: 'sentence_structure',
          question:
              'How many clauses can you identify in this sentence?\n'
              '"${syntax.first.originalSentence}"',
          expectedReasoning:
              'Count the subject-verb pairs. Each independent or dependent clause '
              'has its own subject and verb. Try to separate the clauses mentally.',
        ),
      );
    }

    if (sentences.length > 1) {
      practice.add(
        Practice(
          type: 'inference',
          question:
              'Read the full passage. What is the main idea or theme? '
              'Summarize it in your own words.',
          expectedReasoning:
              'Identify the key subject matter, the author\'s perspective, and any '
              'emotional tone. Consider what the passage is trying to convey overall.',
        ),
      );
    }

    if (vocabulary.length > 2) {
      practice.add(
        Practice(
          type: 'paraphrasing',
          question:
              'Try to paraphrase a sentence from the passage that contains '
              'one of the vocabulary words, using simpler language.',
          expectedReasoning:
              'Focus on conveying the same meaning using words you already know well. '
              'Replace difficult words with simpler synonyms while keeping the original meaning.',
        ),
      );
    }

    return practice;
  }

  static Difficulty _calculateDifficulty(
    List<Vocabulary> vocabulary,
    List<SyntaxPattern> syntax,
    List<String> sentences,
  ) {
    final avgFamiliarity = vocabulary.isEmpty
        ? 1.0
        : vocabulary.map((v) => v.familiarity).reduce((a, b) => a + b) /
              vocabulary.length;

    final vocabDifficulty = ((1.0 - avgFamiliarity) * 100).round().clamp(
      0,
      100,
    );

    final longSentenceRatio = sentences.isEmpty
        ? 0.0
        : sentences
                  .where(
                    (s) =>
                        s.split(RegExp(r'\s+')).length >
                        AppConstants.veryLongSentenceThreshold,
                  )
                  .length /
              sentences.length;
    final syntaxDifficulty = (syntax.length * 12 + longSentenceRatio * 50)
        .round()
        .clamp(0, 100);

    final inferenceDifficulty = (vocabulary.length * 2 + syntax.length * 3)
        .clamp(0, 100);

    String explanation;
    if (vocabDifficulty < 30 && syntaxDifficulty < 30) {
      explanation =
          'This is an easy passage. Most vocabulary should be familiar, '
          'and the sentence structures are straightforward.';
    } else if (vocabDifficulty < 50 && syntaxDifficulty < 50) {
      explanation =
          'This passage has moderate difficulty. Some vocabulary may be new, '
          'and there are a few complex sentences to work through.';
    } else if (vocabDifficulty < 70) {
      explanation =
          'This is a challenging passage. Expect to encounter unfamiliar vocabulary '
          'and some complex sentence structures. Take your time.';
    } else {
      explanation =
          'This passage is quite difficult. It contains many unfamiliar words '
          'and complex sentence patterns. Consider using the dictionary frequently '
          'and re-reading sections as needed.';
    }

    return Difficulty(
      vocab: vocabDifficulty,
      syntax: syntaxDifficulty,
      inference: inferenceDifficulty,
      explanation: explanation,
    );
  }
}
