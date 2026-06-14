import 'package:flow_ai/flow_ai.dart';
import 'package:flow_language/flow_language.dart';

import '../models/book.dart';
import 'learning_analytics_service.dart';

class ReadingInsightService {
  ReadingInsightService({
    required this.analytics,
    required LanguageModule languageModule,
  }) : _languageModule = languageModule;

  final LearningAnalyticsService analytics;
  final LanguageModule _languageModule;

  ReadingInsightProfile compute({
    required String bookId,
    required Book book,
  }) {
    final totalWords = _totalWordCount(book);
    final totalLookups = _totalLookups(bookId, book);
    final repeatedLookups = _totalRepeatedLookups(bookId, book);
    final lookupDensity = _perThousand(totalLookups, totalWords);
    final recheckRate =
        totalLookups > 0 ? repeatedLookups / totalLookups : 0.0;

    final focusAreas = _inferFocusAreas(bookId, book);
    final weakPosCategories = _inferWeakCategories(bookId, book, totalLookups);

    return ReadingInsightProfile(
      focusAreas: focusAreas,
      weakPosCategories: weakPosCategories,
      lookupDensity: lookupDensity,
      recheckRate: recheckRate,
    );
  }

  Set<String> _inferFocusAreas(String bookId, Book book) {
    final areas = <String>{};
    for (var i = 0; i < book.chapters.length; i++) {
      final lookupCount = analytics.lookupCountForChapter(bookId, i);
      if (lookupCount >= 5) areas.add('vocabulary_dense');
      final practiceCount =
          analytics.practiceAnsweredCountForChapter(bookId, i);
      if (practiceCount >= 3) areas.add('active_practice');
    }
    if (areas.isEmpty) return const {};
    return areas;
  }

  Map<String, double> _inferWeakCategories(
    String bookId,
    Book book,
    int totalLookups,
  ) {
    if (totalLookups == 0) return const {};

    final categories = <String, int>{};
    for (var i = 0; i < book.chapters.length; i++) {
      final words = _lookedUpWordsForChapter(bookId, i);
      for (final word in words) {
        final category = _classifyWord(word);
        categories[category] = (categories[category] ?? 0) + 1;
      }
    }

    final result = <String, double>{};
    for (final entry in categories.entries) {
      final ratio = entry.value / totalLookups;
      if (ratio > 0.1) {
        result[entry.key] = ratio;
      }
    }
    return result;
  }

  List<String> _lookedUpWordsForChapter(String bookId, int chapterIndex) {
    return analytics.lookedUpWordsForChapter(bookId, chapterIndex);
  }

  String _classifyWord(String word) {
    if (word.isEmpty) return 'unknown';

    if (RegExp(r'^[A-Z][a-z]+$').hasMatch(word)) return 'proper_nouns';

    // Simple heuristic classification
    if (word.endsWith('ing')) return 'verbs';
    if (word.endsWith('ed') && word.length > 4) return 'verbs';
    if (word.endsWith('ly')) return 'adverbs';
    if (word.endsWith('tion') ||
        word.endsWith('sion') ||
        word.endsWith('ment') ||
        word.endsWith('ness')) {
      return 'abstract_nouns';
    }

    return 'common_vocabulary';
  }

  int _totalWordCount(Book book) {
    var total = 0;
    for (final chapter in book.chapters) {
      total += _languageModule.wordCount(chapter.plainText);
    }
    return total;
  }

  int _totalLookups(String bookId, Book book) {
    var total = 0;
    for (var i = 0; i < book.chapters.length; i += 1) {
      total += analytics.lookupCountForChapter(bookId, i);
    }
    return total;
  }

  int _totalRepeatedLookups(String bookId, Book book) {
    var total = 0;
    for (var i = 0; i < book.chapters.length; i += 1) {
      total += analytics.repeatedLookupCountForChapter(bookId, i);
    }
    return total;
  }

  double _perThousand(int count, int wordCount) {
    if (count <= 0 || wordCount <= 0) return 0;
    return count / wordCount * 1000;
  }
}
