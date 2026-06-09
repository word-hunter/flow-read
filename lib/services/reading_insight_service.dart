import '../models/book.dart';
import 'package:flow_ai/flow_ai.dart';
import 'package:flow_language/english/english.dart';
import 'learning_analytics_service.dart';

class ReadingInsightService {
  ReadingInsightService({
    required this.analytics,
  });

  final LearningAnalyticsService analytics;

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

    return ReadingInsightProfile(
      lookupDensity: lookupDensity,
      recheckRate: recheckRate,
    );
  }

  int _totalWordCount(Book book) {
    var total = 0;
    for (final chapter in book.chapters) {
      total += englishWordPattern.allMatches(chapter.plainText).length;
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
