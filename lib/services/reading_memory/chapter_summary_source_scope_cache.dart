import 'dart:convert';

import 'package:flow_ai/flow_ai.dart';

import '../../models/reading_memory.dart';
import 'reading_memory_ids.dart';
import 'source_scope_service.dart';

final class SourceScopeCacheTypes {
  const SourceScopeCacheTypes._();

  static const chapterSummary = 'chapter_summary';
  static const storylineContext = 'storyline_context';
  static const characterRegistry = 'character_registry';
  static const termIndex = 'term_index';
  static const articleReadingContext = 'article_reading_context';
}

final class SourceScopedChapterSummaryEntry {
  const SourceScopedChapterSummaryEntry({
    required this.bookId,
    required this.chapterIndex,
    required this.summary,
    required this.updatedAt,
    this.outputLanguage,
  });

  final String bookId;
  final int chapterIndex;
  final AISummary summary;
  final DateTime updatedAt;
  final String? outputLanguage;
}

class ChapterSummarySourceScopeCache {
  ChapterSummarySourceScopeCache({required SourceScopeService sourceScope})
    : _sourceScope = sourceScope;

  static const schemaVersion = 1;
  static const cacheType = SourceScopeCacheTypes.chapterSummary;

  final SourceScopeService _sourceScope;

  Future<void> saveChapterSummary({
    required String bookId,
    required String bookTitle,
    required int chapterIndex,
    required AISummary summary,
    String? author,
    String? languageCode,
    String? outputLanguage,
  }) async {
    await _sourceScope.upsertBookSource(
      bookId: bookId,
      title: bookTitle,
      author: author,
      languageCode: languageCode,
    );
    await _sourceScope.upsertSourceScopeCache(
      sourceId: _sourceId(bookId),
      cacheType: cacheType,
      cacheId: _cacheId(
        bookId: bookId,
        chapterIndex: chapterIndex,
        outputLanguage: outputLanguage,
      ),
      payload: jsonEncode({
        'schemaVersion': schemaVersion,
        'bookId': bookId,
        'chapterIndex': chapterIndex,
        'outputLanguage': outputLanguage,
        'summary': summary.toJson(),
      }),
      retentionPolicy: EvidenceRetentionPolicy.deleteWithSource,
    );
  }

  Future<List<SourceScopedChapterSummaryEntry>> loadBookSummaries(
    String bookId, {
    int? maxChapter,
    int limit = 1000,
  }) async {
    final rows = await _sourceScope.sourceScopeCacheForSource(
      _sourceId(bookId),
      cacheType: cacheType,
      limit: limit,
    );
    final entries = <SourceScopedChapterSummaryEntry>[];
    for (final row in rows) {
      final entry = _entryFromCache(row);
      if (entry == null) continue;
      if (entry.bookId != bookId) continue;
      if (maxChapter != null && entry.chapterIndex > maxChapter) continue;
      entries.add(entry);
    }
    entries.sort((a, b) {
      final chapterCompare = a.chapterIndex.compareTo(b.chapterIndex);
      if (chapterCompare != 0) return chapterCompare;
      return a.updatedAt.compareTo(b.updatedAt);
    });
    return entries;
  }

  static SourceScopedChapterSummaryEntry? _entryFromCache(
    SourceScopeCacheItem item,
  ) {
    try {
      final decoded = jsonDecode(item.payload);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final bookId = map['bookId'];
      final chapterIndex = map['chapterIndex'];
      final summaryJson = map['summary'];
      if (bookId is! String || chapterIndex is! int || summaryJson is! Map) {
        return null;
      }
      return SourceScopedChapterSummaryEntry(
        bookId: bookId,
        chapterIndex: chapterIndex,
        summary: AISummary.fromJson(Map<String, dynamic>.from(summaryJson)),
        updatedAt: item.updatedAt,
        outputLanguage: map['outputLanguage'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static String _sourceId(String bookId) {
    return ReadingMemoryIds.source(SourceKind.book, bookId);
  }

  static String _cacheId({
    required String bookId,
    required int chapterIndex,
    String? outputLanguage,
  }) {
    final language = outputLanguage?.trim();
    return [
      'source_scope_cache',
      Uri.encodeComponent(_sourceId(bookId)),
      cacheType,
      chapterIndex.toString(),
      if (language != null && language.isNotEmpty)
        Uri.encodeComponent(language),
    ].join(':');
  }
}
