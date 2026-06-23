import 'dart:convert';

import 'package:flow_ai/flow_ai.dart';

import '../../models/book_glossary_entry.dart';
import '../../models/reading_memory.dart';
import '../book_glossary_service.dart';
import '../character_registry.dart';
import 'chapter_summary_source_scope_cache.dart';
import 'reading_memory_ids.dart';
import 'source_scope_service.dart';

final class BookInsightSourceScopeDataKinds {
  const BookInsightSourceScopeDataKinds._();

  static const chapterSummaries = 'chapter_summaries';
  static const people = 'people';
  static const places = 'places';
  static const terms = 'terms';
  static const events = 'events';
}

final class BookInsightSourceScopeProjection {
  const BookInsightSourceScopeProjection({
    required this.bookId,
    required this.sourceId,
    required this.maxReadChapter,
    required this.chapterSummaries,
    required this.storyline,
    required this.characterCards,
    required this.characterRegistryEntries,
    required this.glossaryEntries,
    this.coverage,
    this.lastGenerated,
  });

  final String bookId;
  final String sourceId;
  final int? maxReadChapter;
  final Map<int, AISummary> chapterSummaries;
  final BookStoryline storyline;
  final List<BookCharacterCard> characterCards;
  final List<CharacterRegistryEntry> characterRegistryEntries;
  final List<BookGlossaryEntry> glossaryEntries;
  final BookInsightCoverage? coverage;
  final DateTime? lastGenerated;

  bool get isEmpty =>
      chapterSummaries.isEmpty &&
      characterRegistryEntries.isEmpty &&
      glossaryEntries.isEmpty;

  ExplanationContextBundle contextBundleFor({
    required String selectedText,
    required int chapterIndex,
    ExplanationContextSelector contextSelector =
        const ExplanationContextSelector(),
  }) {
    final summaryContext = contextSelector.selectContext(
      selectedText: selectedText,
      chapterIndex: chapterIndex,
      storyline: storyline,
      characterCards: characterCards,
    );
    return ExplanationContextBundle(
      currentSentence: selectedText,
      surroundingText: selectedText,
      sameWordOccurrences: summaryContext.sameWordOccurrences,
      relatedEvents: summaryContext.relatedEvents,
      mentionedCharacters: _mergeCharacters(
        summaryContext.mentionedCharacters,
        registryCharactersMentionedIn(selectedText),
      ),
      bookTerms: bookTermsMentionedIn(selectedText),
    );
  }

  List<RelevantCharacter> registryCharactersMentionedIn(
    String selectedText, {
    int limit = 4,
  }) {
    if (selectedText.trim().isEmpty) return const [];
    final matches = <RelevantCharacter>[];
    for (final entry in characterRegistryEntries) {
      if (!_entryMentioned(entry, selectedText)) continue;
      final aliasSet = {...entry.aliases, ...entry.userOverrides};
      final aliases =
          aliasSet.where((alias) => alias.trim().isNotEmpty).toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      matches.add(
        RelevantCharacter(
          name: entry.canonicalName,
          developments: [
            if (entry.firstAppearanceChapter != null)
              'First appears in chapter ${entry.firstAppearanceChapter! + 1}',
            if (aliases.isNotEmpty) 'Aliases: ${aliases.join(', ')}',
          ],
        ),
      );
      if (matches.length >= limit) break;
    }
    return matches;
  }

  List<BookTermContext> bookTermsMentionedIn(
    String selectedText, {
    int limit = 5,
  }) {
    if (selectedText.trim().isEmpty) return const [];
    final matches = <BookTermContext>[];
    final seen = <String>{};
    for (final entry in glossaryEntries) {
      if (!_glossaryEntryMentioned(entry, selectedText)) continue;
      final key = ReadingMemoryIds.normalizeCanonical(
        entry.canonicalForm ?? entry.word,
      );
      if (!seen.add(key)) continue;
      matches.add(
        BookTermContext(
          word: entry.word,
          canonicalForm: entry.canonicalForm,
          explanation: _compact(entry.explanation),
        ),
      );
      if (matches.length >= limit) break;
    }
    return matches;
  }

  static List<RelevantCharacter> _mergeCharacters(
    List<RelevantCharacter> existing,
    List<RelevantCharacter> additions,
  ) {
    final byName = <String, RelevantCharacter>{};
    for (final character in [...existing, ...additions]) {
      final key = character.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      final current = byName[key];
      if (current == null) {
        byName[key] = character;
        continue;
      }
      byName[key] = RelevantCharacter(
        name: current.name,
        developments: _mergeStrings(
          current.developments,
          character.developments,
        ),
      );
    }
    return byName.values.toList(growable: false);
  }

  static List<String> _mergeStrings(
    List<String> existing,
    List<String> additions,
  ) {
    final merged = <String>[];
    final seen = <String>{};
    for (final value in [...existing, ...additions]) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      merged.add(trimmed);
    }
    return merged;
  }

  static bool _entryMentioned(CharacterRegistryEntry entry, String text) {
    return _containsTerm(text, entry.canonicalName) ||
        entry.aliases.any((alias) => _containsTerm(text, alias)) ||
        entry.userOverrides.any((alias) => _containsTerm(text, alias));
  }

  static bool _glossaryEntryMentioned(BookGlossaryEntry entry, String text) {
    return _containsTerm(text, entry.word) ||
        (entry.canonicalForm != null &&
            _containsTerm(text, entry.canonicalForm!));
  }

  static bool _containsTerm(String text, String term) {
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) return false;
    return RegExp(
      r'(^|[^A-Za-z])' + RegExp.escape(normalizedTerm) + r'([^A-Za-z]|$)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static String _compact(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 180).trimRight()}...';
  }
}

class BookInsightSourceScopeService {
  BookInsightSourceScopeService({
    AICacheService? cacheService,
    ChapterSummarySourceScopeCache? chapterSummarySourceScopeCache,
    BookGlossaryService? glossaryService,
    CharacterRegistry? characterRegistry,
    SourceScopeService? sourceScope,
    BookInsightAggregator bookInsightAggregator = const BookInsightAggregator(),
  }) : _cacheService = cacheService,
       _chapterSummarySourceScopeCache = chapterSummarySourceScopeCache,
       _glossaryService = glossaryService,
       _characterRegistry = characterRegistry,
       _sourceScope = sourceScope,
       _bookInsightAggregator = bookInsightAggregator;

  static const schemaVersion = 1;
  static const sourceScopedDataKinds = <String>[
    BookInsightSourceScopeDataKinds.chapterSummaries,
    BookInsightSourceScopeDataKinds.people,
    BookInsightSourceScopeDataKinds.places,
    BookInsightSourceScopeDataKinds.terms,
    BookInsightSourceScopeDataKinds.events,
  ];

  final AICacheService? _cacheService;
  final ChapterSummarySourceScopeCache? _chapterSummarySourceScopeCache;
  final BookGlossaryService? _glossaryService;
  final CharacterRegistry? _characterRegistry;
  final SourceScopeService? _sourceScope;
  final BookInsightAggregator _bookInsightAggregator;

  Future<BookInsightSourceScopeProjection> loadProjection({
    required String bookId,
    int? maxReadChapter,
    int? totalChapters,
    int? readChapters,
    String? bookTitle,
    String? author,
    String? languageCode,
    bool syncInspectableCaches = true,
  }) async {
    final summaryState = await _loadChapterSummaries(
      bookId: bookId,
      maxReadChapter: maxReadChapter,
    );
    final boundary = maxReadChapter ?? _lastChapter(summaryState.summaries);
    final storyline = _bookInsightAggregator.buildStorylineFromChapters(
      bookId,
      summaryState.summaries,
      boundary,
    );
    final characterCards = _bookInsightAggregator.buildCharacterCards(
      bookId,
      summaryState.summaries,
      boundary,
    );
    final projection = BookInsightSourceScopeProjection(
      bookId: bookId,
      sourceId: sourceIdForBook(bookId),
      maxReadChapter: maxReadChapter,
      chapterSummaries: Map.unmodifiable(summaryState.summaries),
      storyline: storyline,
      characterCards: List.unmodifiable(characterCards),
      characterRegistryEntries: List.unmodifiable(
        await _loadCharacterRegistry(
          bookId: bookId,
          maxReadChapter: maxReadChapter,
        ),
      ),
      glossaryEntries: List.unmodifiable(await _loadGlossary(bookId)),
      coverage: totalChapters == null
          ? null
          : _bookInsightAggregator.buildCoverage(
              bookId,
              totalChapters,
              summaryState.summaries.keys.toSet(),
              readChapters ?? _readChapters(maxReadChapter, totalChapters),
              summaryState.lastGenerated,
            ),
      lastGenerated: summaryState.lastGenerated,
    );

    if (syncInspectableCaches) {
      await _syncInspectableCaches(
        projection,
        bookTitle: bookTitle,
        author: author,
        languageCode: languageCode,
      );
    }
    return projection;
  }

  Future<ExplanationContextBundle> contextFor({
    required String bookId,
    required int maxReadChapter,
    required String selectedText,
    ExplanationContextSelector contextSelector =
        const ExplanationContextSelector(),
  }) async {
    try {
      final projection = await loadProjection(
        bookId: bookId,
        maxReadChapter: maxReadChapter,
      );
      return projection.contextBundleFor(
        selectedText: selectedText,
        chapterIndex: maxReadChapter,
        contextSelector: contextSelector,
      );
    } catch (_) {
      return ExplanationContextBundle(
        currentSentence: selectedText,
        surroundingText: selectedText,
      );
    }
  }

  Future<void> deleteBookInsight(
    String bookId, {
    bool clearLegacyAICache = false,
    bool clearSourceScopeCache = true,
  }) async {
    await Future.wait([
      if (clearLegacyAICache && _cacheService != null)
        _cacheService.clearBookCache(bookId),
      if (_glossaryService != null) _glossaryService.clearBookGlossary(bookId),
      if (_characterRegistry != null) _clearCharacterRegistry(bookId),
      if (clearSourceScopeCache && _sourceScope != null)
        _sourceScope.clearSourceScopeCache(sourceIdForBook(bookId)),
    ]);
  }

  Future<_ChapterSummaryState> _loadChapterSummaries({
    required String bookId,
    int? maxReadChapter,
  }) async {
    final summaries = <int, AISummary>{};
    DateTime? lastGenerated;
    final cache = _cacheService;
    if (cache != null) {
      final entries = await cache.listBookSummaries(bookId);
      for (final entry in entries) {
        if (maxReadChapter != null && entry.chapterIndex > maxReadChapter) {
          continue;
        }
        summaries[entry.chapterIndex] = entry.summary;
        lastGenerated = _latest(lastGenerated, entry.generatedAt);
      }
    }

    final scopedCache = _chapterSummarySourceScopeCache;
    if (scopedCache != null) {
      final entries = await scopedCache.loadBookSummaries(
        bookId,
        maxChapter: maxReadChapter,
      );
      for (final entry in entries) {
        summaries[entry.chapterIndex] = entry.summary;
        lastGenerated = _latest(lastGenerated, entry.updatedAt);
      }
    }
    return _ChapterSummaryState(
      summaries: summaries,
      lastGenerated: lastGenerated,
    );
  }

  Future<List<BookGlossaryEntry>> _loadGlossary(String bookId) async {
    final service = _glossaryService;
    if (service == null) return const [];
    final entries = await service.getBookGlossary(bookId);
    entries.sort((a, b) {
      final wordCompare = a.word.toLowerCase().compareTo(
        b.word.toLowerCase(),
      );
      if (wordCompare != 0) return wordCompare;
      return (a.canonicalForm ?? '').toLowerCase().compareTo(
        (b.canonicalForm ?? '').toLowerCase(),
      );
    });
    return entries;
  }

  Future<List<CharacterRegistryEntry>> _loadCharacterRegistry({
    required String bookId,
    int? maxReadChapter,
  }) async {
    final registry = _characterRegistry;
    if (registry == null) return const [];
    await registry.init();
    final entries = registry
        .getAll(bookId)
        .where((entry) => entry.canonicalName.trim().isNotEmpty)
        .where((entry) {
          final firstChapter = entry.firstAppearanceChapter;
          return maxReadChapter == null ||
              firstChapter == null ||
              firstChapter <= maxReadChapter;
        })
        .toList();
    entries.sort((a, b) {
      final chapterA = a.firstAppearanceChapter ?? 1 << 30;
      final chapterB = b.firstAppearanceChapter ?? 1 << 30;
      final chapterCompare = chapterA.compareTo(chapterB);
      if (chapterCompare != 0) return chapterCompare;
      return a.canonicalName.toLowerCase().compareTo(
        b.canonicalName.toLowerCase(),
      );
    });
    return entries;
  }

  Future<void> _syncInspectableCaches(
    BookInsightSourceScopeProjection projection, {
    String? bookTitle,
    String? author,
    String? languageCode,
  }) async {
    final sourceScope = _sourceScope;
    if (sourceScope == null || projection.isEmpty) return;
    final title = _trimOrNull(bookTitle);
    if (title != null) {
      await sourceScope.upsertBookSource(
        bookId: projection.bookId,
        title: title,
        author: author,
        languageCode: languageCode,
      );
    }

    await _upsertInspectableCache(
      sourceScope,
      sourceId: projection.sourceId,
      cacheType: SourceScopeCacheTypes.storylineContext,
      payload: {
        'schemaVersion': schemaVersion,
        'bookId': projection.bookId,
        'sourceScopedDataKinds': sourceScopedDataKinds,
        'maxReadChapter': projection.maxReadChapter,
        'events': projection.storyline.events
            .map(
              (event) => {
                'chapterIndex': event.chapterIndex,
                'description': event.description,
                'significance': event.significance,
                'source': event.source,
                'confidence': event.confidence,
              },
            )
            .toList(growable: false),
        'places': const <String>[],
      },
    );
    await _upsertInspectableCache(
      sourceScope,
      sourceId: projection.sourceId,
      cacheType: SourceScopeCacheTypes.characterRegistry,
      payload: {
        'schemaVersion': schemaVersion,
        'bookId': projection.bookId,
        'maxReadChapter': projection.maxReadChapter,
        'registry': projection.characterRegistryEntries
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'inferredCards': projection.characterCards
            .map(
              (card) => {
                'canonicalName': card.canonicalName,
                'firstSeenChapter': card.firstSeenChapter,
                'currentState': card.currentState,
                'evidenceSnippets': card.evidenceSnippets,
              },
            )
            .toList(growable: false),
      },
    );
    await _upsertInspectableCache(
      sourceScope,
      sourceId: projection.sourceId,
      cacheType: SourceScopeCacheTypes.termIndex,
      payload: {
        'schemaVersion': schemaVersion,
        'bookId': projection.bookId,
        'terms': projection.glossaryEntries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
    );
  }

  Future<void> _upsertInspectableCache(
    SourceScopeService sourceScope, {
    required String sourceId,
    required String cacheType,
    required Map<String, Object?> payload,
  }) async {
    try {
      await sourceScope.upsertSourceScopeCache(
        sourceId: sourceId,
        cacheType: cacheType,
        payload: jsonEncode(payload),
        retentionPolicy: EvidenceRetentionPolicy.deleteWithSource,
      );
    } catch (_) {}
  }

  Future<void> _clearCharacterRegistry(String bookId) async {
    final registry = _characterRegistry;
    if (registry == null) return;
    await registry.init();
    await registry.clearForBook(bookId);
  }

  static String sourceIdForBook(String bookId) {
    return ReadingMemoryIds.source(SourceKind.book, bookId);
  }

  static int _readChapters(int? maxReadChapter, int totalChapters) {
    if (totalChapters <= 0) return 0;
    if (maxReadChapter == null) return totalChapters;
    return (maxReadChapter + 1).clamp(0, totalChapters).toInt();
  }

  static int _lastChapter(Map<int, AISummary> summaries) {
    if (summaries.isEmpty) return 0;
    return summaries.keys.reduce((a, b) => a > b ? a : b);
  }

  static DateTime? _latest(DateTime? current, DateTime? candidate) {
    if (candidate == null) return current;
    if (current == null || candidate.isAfter(current)) return candidate;
    return current;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final class _ChapterSummaryState {
  const _ChapterSummaryState({
    required this.summaries,
    required this.lastGenerated,
  });

  final Map<int, AISummary> summaries;
  final DateTime? lastGenerated;
}
