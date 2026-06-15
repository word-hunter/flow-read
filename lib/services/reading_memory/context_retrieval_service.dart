import 'package:flow_ai/flow_ai.dart';

import '../../models/book_glossary_entry.dart';
import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import '../book_glossary_service.dart';
import '../character_registry.dart';
import '../user_vocabulary_service.dart';
import 'reading_memory_ids.dart';

class ContextRetrievalService {
  ContextRetrievalService({
    required ReadingMemoryRepository repository,
    required UserVocabularyService userVocabulary,
    AICacheService? cacheService,
    BookGlossaryService? glossaryService,
    CharacterRegistry? characterRegistry,
    String? languageCode,
    int repeatedLookupThreshold = 2,
    BookInsightAggregator bookInsightAggregator = const BookInsightAggregator(),
    ExplanationContextSelector contextSelector =
        const ExplanationContextSelector(),
  }) : _repository = repository,
       _userVocabulary = userVocabulary,
       _cacheService = cacheService,
       _glossaryService = glossaryService,
       _characterRegistry = characterRegistry,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _repeatedLookupThreshold = repeatedLookupThreshold,
       _bookInsightAggregator = bookInsightAggregator,
       _contextSelector = contextSelector;

  final ReadingMemoryRepository _repository;
  final UserVocabularyService _userVocabulary;
  final AICacheService? _cacheService;
  final BookGlossaryService? _glossaryService;
  final CharacterRegistry? _characterRegistry;
  final String _languageCode;
  final int _repeatedLookupThreshold;
  final BookInsightAggregator _bookInsightAggregator;
  final ExplanationContextSelector _contextSelector;

  Future<AIContextSnapshot> enrichContext(
    AIContextSnapshot context,
    AIAssistantActionType action,
  ) async {
    if (!_shouldEnrich(action, context)) return context;
    final bundle = await buildForContext(context);
    if (bundle.isEmpty) return context;
    return context.copyWith(contextBundle: bundle);
  }

  Future<ExplanationContextBundle> buildForContext(
    AIContextSnapshot context,
  ) async {
    final currentSentence = _currentSentence(context);
    final surroundingText = _surroundingText(context);
    final terms = _candidateTerms([
      context.word,
      currentSentence,
      surroundingText,
    ]);
    final existing = context.contextBundle;
    final bookContext = await _bookContextFor(
      context,
      currentSentence: currentSentence,
      surroundingText: surroundingText,
    );

    return ExplanationContextBundle(
      currentSentence: currentSentence,
      surroundingText: surroundingText,
      sameWordOccurrences: _mergeStrings(
        existing?.sameWordOccurrences,
        bookContext.sameWordOccurrences,
      ),
      relatedEvents: _mergeEvents(
        existing?.relatedEvents,
        bookContext.relatedEvents,
      ),
      mentionedCharacters: _mergeCharacters(
        existing?.mentionedCharacters,
        bookContext.mentionedCharacters,
      ),
      historyLookups: existing?.historyLookups ?? const [],
      knownWords: _matchedVocabulary(_userVocabulary.knownWords, terms),
      learningWords: _matchedVocabulary(_userVocabulary.learningWords, terms),
      repeatedLookupWords: await _repeatedLookupWords(terms),
      savedExplanations: await _savedExplanationPreviews(context, terms),
      bookTerms: _mergeBookTerms(existing?.bookTerms, bookContext.bookTerms),
    );
  }

  bool _shouldEnrich(AIAssistantActionType action, AIContextSnapshot context) {
    if (!_hasMemoryRelevantText(context)) return false;
    return switch (action) {
      AIAssistantActionType.explain ||
      AIAssistantActionType.phraseExtraction ||
      AIAssistantActionType.pronounReference ||
      AIAssistantActionType.wordAnalysis ||
      AIAssistantActionType.paragraphInsight ||
      AIAssistantActionType.chat => true,
      AIAssistantActionType.translate ||
      AIAssistantActionType.summary ||
      AIAssistantActionType.questionGeneration ||
      AIAssistantActionType.articleQA => false,
    };
  }

  bool _hasMemoryRelevantText(AIContextSnapshot context) {
    return _nonEmpty(context.word) != null ||
        _nonEmpty(context.selectedText) != null ||
        _nonEmpty(context.surroundingPassage) != null;
  }

  String _currentSentence(AIContextSnapshot context) {
    return _nonEmpty(context.wordSentence) ??
        _nonEmpty(context.selectedText) ??
        _nonEmpty(context.surroundingPassage) ??
        _nonEmpty(context.word) ??
        '';
  }

  String _surroundingText(AIContextSnapshot context) {
    return _nonEmpty(context.surroundingPassage) ??
        _nonEmpty(context.wordSentence) ??
        _nonEmpty(context.selectedText) ??
        '';
  }

  List<String> _candidateTerms(Iterable<String?> values) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = _nonEmpty(value);
      if (trimmed == null) continue;
      for (final match in RegExp(
        r"[A-Za-z]+(?:[-'][A-Za-z]+)?",
      ).allMatches(trimmed)) {
        final canonical = ReadingMemoryIds.normalizeCanonical(match.group(0)!);
        if (canonical.length < 2 || !seen.add(canonical)) continue;
        ordered.add(canonical);
        if (ordered.length >= 24) return ordered;
      }
    }
    return ordered;
  }

  List<String> _matchedVocabulary(Set<String> vocabulary, List<String> terms) {
    if (vocabulary.isEmpty || terms.isEmpty) return const [];
    final byCanonical = <String, String>{};
    for (final word in vocabulary) {
      final canonical = ReadingMemoryIds.normalizeCanonical(word);
      if (canonical.isNotEmpty) {
        byCanonical.putIfAbsent(canonical, () => word);
      }
    }

    final matched = <String>[];
    final seen = <String>{};
    for (final term in terms) {
      final word = byCanonical[term];
      if (word == null || !seen.add(term)) continue;
      matched.add(word);
      if (matched.length >= 12) break;
    }
    return matched;
  }

  Future<List<String>> _repeatedLookupWords(List<String> terms) async {
    final repeated = <String>[];
    for (final term in terms.take(24)) {
      final count = await _repository.eventCountForCanonical(
        languageCode: _languageCode,
        canonicalKey: term,
        type: MemoryEventType.lookup,
      );
      if (count < _repeatedLookupThreshold) continue;
      repeated.add(term);
      if (repeated.length >= 8) break;
    }
    return repeated;
  }

  Future<List<String>> _savedExplanationPreviews(
    AIContextSnapshot context,
    List<String> terms,
  ) async {
    final queries = <_ExplanationQuery>[];
    final word = _nonEmpty(context.word);
    if (word != null) {
      queries.add(
        _ExplanationQuery(
          KnowledgeEntityType.word,
          ReadingMemoryIds.normalizeCanonical(word),
        ),
      );
    }

    final selectedText = _nonEmpty(context.selectedText);
    if (selectedText != null) {
      queries.add(
        _ExplanationQuery(
          KnowledgeEntityType.sentence,
          ReadingMemoryIds.normalizeCanonical(selectedText),
        ),
      );
    }

    for (final term in terms.take(12)) {
      queries.add(_ExplanationQuery(KnowledgeEntityType.word, term));
    }

    final previews = <String>[];
    final seenQueries = <String>{};
    final seenExplanations = <String>{};
    for (final query in queries) {
      if (query.canonical.isEmpty || !seenQueries.add(query.key)) continue;
      final entity = await _repository.entityByCanonical(
        languageCode: _languageCode,
        type: query.type,
        canonicalKey: query.canonical,
      );
      if (entity == null) continue;
      final explanations = await _repository.explanationsForEntity(
        entity.id,
        limit: 2,
      );
      for (final explanation in explanations) {
        if (!seenExplanations.add(explanation.id)) continue;
        previews.add(
          '${entity.displayText}: ${_compact(explanation.explanation)}',
        );
        if (previews.length >= 5) return previews;
      }
    }
    return previews;
  }

  Future<_BookInsightContext> _bookContextFor(
    AIContextSnapshot context, {
    required String currentSentence,
    required String surroundingText,
  }) async {
    final bookId = _contextBookId(context);
    final maxReadChapter = _maxReadChapter(context);
    if (bookId == null || maxReadChapter == null) {
      return const _BookInsightContext();
    }

    final selectedText = [
      currentSentence,
      surroundingText,
      context.word,
    ].whereType<String>().join('\n');

    final summaryContext = await _summaryContext(
      bookId: bookId,
      maxReadChapter: maxReadChapter,
      selectedText: selectedText,
    );
    final registryCharacters = await _registryCharacters(
      bookId: bookId,
      maxReadChapter: maxReadChapter,
      selectedText: selectedText,
    );
    final bookTerms = await _bookTerms(bookId, selectedText);

    return _BookInsightContext(
      sameWordOccurrences: summaryContext.sameWordOccurrences,
      relatedEvents: summaryContext.relatedEvents,
      mentionedCharacters: _mergeCharacters(
        summaryContext.mentionedCharacters,
        registryCharacters,
      ),
      bookTerms: bookTerms,
    );
  }

  Future<_BookInsightContext> _summaryContext({
    required String bookId,
    required int maxReadChapter,
    required String selectedText,
  }) async {
    final cache = _cacheService;
    if (cache == null) return const _BookInsightContext();

    try {
      final entries = await cache.listBookSummaries(bookId);
      final summaries = <int, AISummary>{};
      for (final entry in entries) {
        if (entry.chapterIndex > maxReadChapter) continue;
        summaries[entry.chapterIndex] = entry.summary;
      }
      if (summaries.isEmpty) return const _BookInsightContext();

      final storyline = _bookInsightAggregator.buildStorylineFromChapters(
        bookId,
        summaries,
        maxReadChapter,
      );
      final characterCards = _bookInsightAggregator.buildCharacterCards(
        bookId,
        summaries,
        maxReadChapter,
      );
      final bundle = _contextSelector.selectContext(
        selectedText: selectedText,
        chapterIndex: maxReadChapter,
        storyline: storyline,
        characterCards: characterCards,
      );
      return _BookInsightContext(
        sameWordOccurrences: bundle.sameWordOccurrences,
        relatedEvents: bundle.relatedEvents,
        mentionedCharacters: bundle.mentionedCharacters,
      );
    } catch (_) {
      return const _BookInsightContext();
    }
  }

  Future<List<RelevantCharacter>> _registryCharacters({
    required String bookId,
    required int maxReadChapter,
    required String selectedText,
  }) async {
    final registry = _characterRegistry;
    if (registry == null || selectedText.trim().isEmpty) return const [];

    try {
      await registry.init();
      final matches = <RelevantCharacter>[];
      for (final entry in registry.getAll(bookId)) {
        final firstChapter = entry.firstAppearanceChapter;
        if (firstChapter != null && firstChapter > maxReadChapter) continue;
        if (!_entryMentioned(entry, selectedText)) continue;

        final aliasSet = {...entry.aliases, ...entry.userOverrides};
        final aliases =
            aliasSet.where((alias) => alias.trim().isNotEmpty).toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        matches.add(
          RelevantCharacter(
            name: entry.canonicalName,
            developments: [
              if (firstChapter != null)
                'First appears in chapter ${firstChapter + 1}',
              if (aliases.isNotEmpty) 'Aliases: ${aliases.join(', ')}',
            ],
          ),
        );
        if (matches.length >= 4) break;
      }
      return matches;
    } catch (_) {
      return const [];
    }
  }

  Future<List<BookTermContext>> _bookTerms(
    String bookId,
    String selectedText,
  ) async {
    final glossary = _glossaryService;
    if (glossary == null || selectedText.trim().isEmpty) return const [];

    try {
      final entries = await glossary.getBookGlossary(bookId);
      final matches = <BookTermContext>[];
      final seen = <String>{};
      for (final entry in entries) {
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
        if (matches.length >= 5) break;
      }
      return matches;
    } catch (_) {
      return const [];
    }
  }

  String? _contextBookId(AIContextSnapshot context) {
    final boundary = context.spoilerBoundary;
    if (boundary != null && boundary.unitType == 'chapter') {
      final bookId = _nonEmpty(boundary.bookId);
      if (bookId != null) return bookId;
    }
    return _nonEmpty(context.bookId);
  }

  int? _maxReadChapter(AIContextSnapshot context) {
    final boundary = context.spoilerBoundary;
    if (boundary != null && boundary.unitType == 'chapter') {
      return boundary.maxReadUnitOrder;
    }
    return context.chapterIndex;
  }

  bool _entryMentioned(CharacterRegistryEntry entry, String text) {
    return _containsTerm(text, entry.canonicalName) ||
        entry.aliases.any((alias) => _containsTerm(text, alias)) ||
        entry.userOverrides.any((alias) => _containsTerm(text, alias));
  }

  bool _glossaryEntryMentioned(BookGlossaryEntry entry, String text) {
    return _containsTerm(text, entry.word) ||
        (entry.canonicalForm != null &&
            _containsTerm(text, entry.canonicalForm!));
  }

  bool _containsTerm(String text, String term) {
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) return false;
    return RegExp(
      r'(^|[^A-Za-z])' + RegExp.escape(normalizedTerm) + r'([^A-Za-z]|$)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  List<String> _mergeStrings(List<String>? existing, List<String> additions) {
    final merged = <String>[];
    final seen = <String>{};
    for (final value in [...?existing, ...additions]) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      merged.add(trimmed);
    }
    return merged;
  }

  List<RelevantEvent> _mergeEvents(
    List<RelevantEvent>? existing,
    List<RelevantEvent> additions,
  ) {
    final merged = <RelevantEvent>[];
    final seen = <String>{};
    for (final event in [...?existing, ...additions]) {
      final key = '${event.chapterIndex}:${event.description.toLowerCase()}';
      if (!seen.add(key)) continue;
      merged.add(event);
    }
    return merged;
  }

  List<RelevantCharacter> _mergeCharacters(
    List<RelevantCharacter>? existing,
    List<RelevantCharacter> additions,
  ) {
    final byName = <String, RelevantCharacter>{};
    for (final character in [...?existing, ...additions]) {
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
    return byName.values.toList();
  }

  List<BookTermContext> _mergeBookTerms(
    List<BookTermContext>? existing,
    List<BookTermContext> additions,
  ) {
    final merged = <BookTermContext>[];
    final seen = <String>{};
    for (final term in [...?existing, ...additions]) {
      final key = ReadingMemoryIds.normalizeCanonical(
        term.canonicalForm ?? term.word,
      );
      if (key.isEmpty || !seen.add(key)) continue;
      merged.add(term);
    }
    return merged;
  }

  String _compact(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 180).trimRight()}...';
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

final class _BookInsightContext {
  const _BookInsightContext({
    this.sameWordOccurrences = const [],
    this.relatedEvents = const [],
    this.mentionedCharacters = const [],
    this.bookTerms = const [],
  });

  final List<String> sameWordOccurrences;
  final List<RelevantEvent> relatedEvents;
  final List<RelevantCharacter> mentionedCharacters;
  final List<BookTermContext> bookTerms;
}

final class _ExplanationQuery {
  const _ExplanationQuery(this.type, this.canonical);

  final KnowledgeEntityType type;
  final String canonical;

  String get key => '${type.storageValue}:$canonical';
}
