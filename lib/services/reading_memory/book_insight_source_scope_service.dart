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
    this.analysisData,
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
  final BookAnalysisData? analysisData;
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
    Iterable<int>? includedChapterIndexes,
    bool syncInspectableCaches = true,
  }) async {
    final includedChapters = _includedChapterSet(includedChapterIndexes);
    final summaryState = await _loadChapterSummaries(
      bookId: bookId,
      maxReadChapter: maxReadChapter,
      includedChapterIndexes: includedChapters,
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
    final characterRegistryEntries = await _loadCharacterRegistry(
      bookId: bookId,
      maxReadChapter: maxReadChapter,
      includedChapterIndexes: includedChapters,
    );
    final analysisResult = await _buildAnalysisData(
      bookId: bookId,
      summaries: summaryState.summaries,
      boundary: boundary,
      totalChapters: totalChapters,
      readChapters: readChapters,
      languageCode: languageCode,
      outputLanguage: summaryState.outputLanguage,
      characterRegistryEntries: characterRegistryEntries,
    );
    final effectiveCharacterRegistryEntries =
        analysisResult?.characterRegistryEntries ?? characterRegistryEntries;
    final projection = BookInsightSourceScopeProjection(
      bookId: bookId,
      sourceId: sourceIdForBook(bookId),
      maxReadChapter: maxReadChapter,
      chapterSummaries: Map.unmodifiable(summaryState.summaries),
      analysisData: analysisResult?.analysisData,
      storyline: storyline,
      characterCards: List.unmodifiable(characterCards),
      characterRegistryEntries: List.unmodifiable(
        effectiveCharacterRegistryEntries,
      ),
      glossaryEntries: List.unmodifiable(await _loadGlossary(bookId)),
      coverage: totalChapters == null
          ? null
          : _buildCoverage(
              bookId: bookId,
              totalChapters: totalChapters,
              cachedChapters: summaryState.summaries.keys.toSet(),
              readChapters:
                  readChapters ?? _readChapters(maxReadChapter, totalChapters),
              lastGenerated: summaryState.lastGenerated,
              includedChapterIndexes: includedChapters,
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

  Future<_AnalysisBuildResult?> _buildAnalysisData({
    required String bookId,
    required Map<int, AISummary> summaries,
    required int boundary,
    required int? totalChapters,
    required int? readChapters,
    required String? languageCode,
    required String? outputLanguage,
    required List<CharacterRegistryEntry> characterRegistryEntries,
  }) async {
    if (summaries.isEmpty) return null;
    final effectiveTotalChapters = _effectiveTotalChapters(
      summaries,
      totalChapters,
      boundary,
    );
    if (effectiveTotalChapters <= 0) return null;

    final scope = _analysisScope(
      bookId: bookId,
      boundary: boundary,
      totalChapters: effectiveTotalChapters,
      readChapters: readChapters,
      languageCode: languageCode,
      outputLanguage: outputLanguage,
    );
    final chapterInsights = <int, ChapterInsight>{};
    for (final entry in summaries.entries) {
      if (entry.key > boundary) continue;
      chapterInsights[entry.key] = ChapterInsight.fromSummary(entry.value);
    }
    if (chapterInsights.isEmpty) return null;

    final registryAdapter = _AutoRegisteringBookAnalysisCharacterRegistry(
      entries: characterRegistryEntries,
    );
    final analysisData =
        BookAnalysisAggregator(
          characterRegistry: registryAdapter,
        ).build(
          scope: scope,
          chapterInsights: chapterInsights,
          totalChapters: effectiveTotalChapters,
        );
    await registryAdapter.flush(
      registry: _characterRegistry,
      bookId: bookId,
    );
    return _AnalysisBuildResult(
      analysisData: analysisData,
      characterRegistryEntries: registryAdapter.sortedEntries(
        maxReadChapter: boundary,
      ),
    );
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
    Set<int>? includedChapterIndexes,
  }) async {
    final summaries = <int, AISummary>{};
    DateTime? lastGenerated;
    String? outputLanguage;
    final cache = _cacheService;
    if (cache != null) {
      final entries = await cache.listBookSummaries(bookId);
      for (final entry in entries) {
        if (maxReadChapter != null && entry.chapterIndex > maxReadChapter) {
          continue;
        }
        if (!_chapterIncluded(entry.chapterIndex, includedChapterIndexes)) {
          continue;
        }
        if (!_isUsableChapterSummary(entry.summary)) continue;
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
        if (!_chapterIncluded(entry.chapterIndex, includedChapterIndexes)) {
          continue;
        }
        if (!_isUsableChapterSummary(entry.summary)) continue;
        summaries[entry.chapterIndex] = entry.summary;
        lastGenerated = _latest(lastGenerated, entry.updatedAt);
        outputLanguage ??= _trimOrNull(entry.outputLanguage);
      }
    }
    return _ChapterSummaryState(
      summaries: summaries,
      lastGenerated: lastGenerated,
      outputLanguage: outputLanguage,
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

  static bool _isUsableChapterSummary(AISummary summary) {
    return !summary.isEmpty && !ChapterAIStatus.isSummaryFallback(summary);
  }

  Future<List<CharacterRegistryEntry>> _loadCharacterRegistry({
    required String bookId,
    int? maxReadChapter,
    Set<int>? includedChapterIndexes,
  }) async {
    final registry = _characterRegistry;
    if (registry == null) return const [];
    await registry.init();
    final entries = registry
        .getAll(bookId)
        .where((entry) => entry.canonicalName.trim().isNotEmpty)
        .where((entry) {
          final firstChapter = entry.firstAppearanceChapter;
          if (firstChapter != null &&
              !_chapterIncluded(firstChapter, includedChapterIndexes)) {
            return false;
          }
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

  BookInsightCoverage _buildCoverage({
    required String bookId,
    required int totalChapters,
    required Set<int> cachedChapters,
    required int readChapters,
    required DateTime? lastGenerated,
    required Set<int>? includedChapterIndexes,
  }) {
    if (includedChapterIndexes == null) {
      return _bookInsightAggregator.buildCoverage(
        bookId,
        totalChapters,
        cachedChapters,
        readChapters,
        lastGenerated,
      );
    }

    final included =
        includedChapterIndexes
            .where(
              (chapterIndex) =>
                  chapterIndex >= 0 && chapterIndex < totalChapters,
            )
            .toList()
          ..sort();
    final readBoundary = readChapters <= 0 ? -1 : readChapters - 1;
    final includedCached = {
      for (final chapterIndex in included)
        if (cachedChapters.contains(chapterIndex)) chapterIndex,
    };
    final missing = [
      for (final chapterIndex in included)
        if (chapterIndex <= readBoundary &&
            !includedCached.contains(chapterIndex))
          chapterIndex,
    ];
    return BookInsightCoverage(
      summarizedChapters: includedCached.length,
      totalChapters: included.length,
      readChapters: included
          .where((chapterIndex) => chapterIndex <= readBoundary)
          .length,
      missingChapters: missing,
      lastGenerated: lastGenerated,
    );
  }

  static Set<int>? _includedChapterSet(Iterable<int>? chapterIndexes) {
    if (chapterIndexes == null) return null;
    return {
      for (final chapterIndex in chapterIndexes)
        if (chapterIndex >= 0) chapterIndex,
    };
  }

  static bool _chapterIncluded(
    int chapterIndex,
    Set<int>? includedChapterIndexes,
  ) {
    return includedChapterIndexes == null ||
        includedChapterIndexes.contains(chapterIndex);
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

  static int _effectiveTotalChapters(
    Map<int, AISummary> summaries,
    int? totalChapters,
    int boundary,
  ) {
    if (totalChapters != null && totalChapters > 0) return totalChapters;
    if (summaries.isEmpty) return boundary + 1;
    final lastSummaryChapter = summaries.keys.reduce((a, b) => a > b ? a : b);
    final inferred = [
      boundary + 1,
      lastSummaryChapter + 1,
    ].reduce((a, b) => a > b ? a : b);
    return inferred < 1 ? 1 : inferred;
  }

  static AnalysisScope _analysisScope({
    required String bookId,
    required int boundary,
    required int totalChapters,
    required int? readChapters,
    required String? languageCode,
    required String? outputLanguage,
  }) {
    final sourceLanguage = SourceLanguage.fromCode(languageCode).code;
    final targetLanguage = _targetOutputLanguage(outputLanguage);
    final fullBookBoundary = totalChapters <= 0 ? 0 : totalChapters - 1;
    final coversFullBook =
        boundary >= fullBookBoundary &&
        (readChapters == null || readChapters >= totalChapters);
    if (coversFullBook) {
      return AnalysisScope.fullBook(
        bookId: bookId,
        totalChapters: totalChapters,
        sourceLanguage: sourceLanguage,
        outputLanguage: targetLanguage,
      );
    }
    return AnalysisScope.readSoFar(
      bookId: bookId,
      currentChapterIndex: boundary.clamp(0, fullBookBoundary).toInt(),
      sourceLanguage: sourceLanguage,
      outputLanguage: targetLanguage,
    );
  }

  static String _targetOutputLanguage(String? outputLanguage) {
    final normalized = outputLanguage?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return OutputLanguage.fromCode(normalized).code;
    }
    return OutputLanguage.zhHans.code;
  }
}

final class _AnalysisBuildResult {
  const _AnalysisBuildResult({
    required this.analysisData,
    required this.characterRegistryEntries,
  });

  final BookAnalysisData analysisData;
  final List<CharacterRegistryEntry> characterRegistryEntries;
}

final class _AutoRegisteringBookAnalysisCharacterRegistry
    implements BookAnalysisCharacterRegistry {
  _AutoRegisteringBookAnalysisCharacterRegistry({
    required List<CharacterRegistryEntry> entries,
  }) : _entriesByKey = {
         for (final entry in entries)
           if (entry.canonicalName.trim().isNotEmpty)
             _key(entry.canonicalName): entry,
       };

  final Map<String, CharacterRegistryEntry> _entriesByKey;
  final Set<String> _dirtyKeys = {};

  @override
  String? matchCanonical(String bookId, String name) {
    return _entryMatching(name)?.canonicalName;
  }

  @override
  void registerCharacterMention(
    String bookId, {
    required String canonicalName,
    required String mention,
    required int chapterIndex,
  }) {
    final canonical = canonicalName.trim();
    final rawMention = mention.trim();
    if (canonical.isEmpty || rawMention.isEmpty) return;

    final key = _key(canonical);
    final conflictingEntry = _entryMatching(rawMention);
    if (conflictingEntry != null &&
        _key(conflictingEntry.canonicalName) != key) {
      return;
    }

    final current = _entriesByKey[key];
    if (current == null) {
      _entriesByKey[key] = CharacterRegistryEntry(
        canonicalName: canonical,
        aliases: _sameName(canonical, rawMention) ? const {} : {rawMention},
        firstAppearanceChapter: chapterIndex,
        updatedAt: DateTime.now().toUtc(),
      );
      _dirtyKeys.add(key);
      return;
    }

    final nextAliases = {...current.aliases};
    var changed = false;
    if (!_sameName(current.canonicalName, rawMention) &&
        !current.matches(rawMention)) {
      nextAliases.add(rawMention);
      changed = true;
    }
    final currentFirst = current.firstAppearanceChapter;
    final nextFirst = currentFirst == null || chapterIndex < currentFirst
        ? chapterIndex
        : currentFirst;
    changed = changed || nextFirst != currentFirst;
    if (!changed) return;

    _entriesByKey[key] = CharacterRegistryEntry(
      canonicalName: current.canonicalName,
      aliases: nextAliases,
      userOverrides: current.userOverrides,
      firstAppearanceChapter: nextFirst,
      updatedAt: DateTime.now().toUtc(),
    );
    _dirtyKeys.add(key);
  }

  Future<void> flush({
    required CharacterRegistry? registry,
    required String bookId,
  }) async {
    if (registry == null || _dirtyKeys.isEmpty) return;
    await registry.init();
    final dirtyKeys = _dirtyKeys.toList()..sort();
    for (final key in dirtyKeys) {
      final entry = _entriesByKey[key];
      if (entry == null) continue;
      await registry.addEntry(bookId, entry);
    }
    _dirtyKeys.clear();
  }

  List<CharacterRegistryEntry> sortedEntries({required int? maxReadChapter}) {
    final entries = _entriesByKey.values.where((entry) {
      final firstChapter = entry.firstAppearanceChapter;
      return maxReadChapter == null ||
          firstChapter == null ||
          firstChapter <= maxReadChapter;
    }).toList();
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

  CharacterRegistryEntry? _entryMatching(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    for (final entry in _entriesByKey.values) {
      if (entry.matches(trimmed)) return entry;
    }
    return null;
  }

  static bool _sameName(String a, String b) => _key(a) == _key(b);

  static String _key(String value) => value.trim().toLowerCase();
}

final class _ChapterSummaryState {
  const _ChapterSummaryState({
    required this.summaries,
    required this.lastGenerated,
    this.outputLanguage,
  });

  final Map<int, AISummary> summaries;
  final DateTime? lastGenerated;
  final String? outputLanguage;
}
