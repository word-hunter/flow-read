import 'package:flow_language/flow_language.dart';

import '../../models/book_glossary_entry.dart';
import '../../models/reading_memory.dart';
import '../../models/reading_memory_overlay.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import '../book_glossary_service.dart';
import '../user_vocabulary_service.dart';
import '../word_level_service.dart';
import 'reading_memory_ids.dart';

class ReadingMemoryOverlayService {
  ReadingMemoryOverlayService({
    required ReadingMemoryRepository repository,
    required UserVocabularyService userVocabulary,
    BookGlossaryService? glossaryService,
    String? languageCode,
    int repeatedLookupThreshold = 2,
    int maxCandidateTerms = 96,
    int maxMarkers = 48,
  }) : _repository = repository,
       _userVocabulary = userVocabulary,
       _glossaryService = glossaryService,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _repeatedLookupThreshold = repeatedLookupThreshold,
       _maxCandidateTerms = maxCandidateTerms,
       _maxMarkers = maxMarkers;

  final ReadingMemoryRepository _repository;
  final UserVocabularyService _userVocabulary;
  final BookGlossaryService? _glossaryService;
  final String _languageCode;
  final int _repeatedLookupThreshold;
  final int _maxCandidateTerms;
  final int _maxMarkers;

  Future<void> init() async {
    await _repository.init();
    await _userVocabulary.init();
  }

  Future<ReadingMemoryOverlayProjection> buildForText({
    required String text,
    String? bookId,
    LanguageModule? languageModule,
    WordLevelService? wordLevelService,
  }) async {
    final terms = _candidateTerms(
      text,
      languageModule: languageModule,
      wordLevelService: wordLevelService,
    );
    if (terms.isEmpty) return ReadingMemoryOverlayProjection.empty;

    final builder = _ReadingMemoryOverlayBuilder(maxMarkers: _maxMarkers);
    _addLearningMarkers(builder, terms);
    await _addRepeatedLookupMarkers(builder, terms);
    await _addReviewDueMarkers(builder, terms);
    await _addBookTermMarkers(builder, terms, bookId: bookId);
    return builder.build();
  }

  List<_OverlayTerm> _candidateTerms(
    String text, {
    LanguageModule? languageModule,
    WordLevelService? wordLevelService,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return const [];

    final terms = <_OverlayTerm>[];
    final seen = <String>{};
    final module = languageModule ?? LanguageRegistry.instance.defaultModule;
    final tokens = module?.tokenize(trimmedText) ?? const <String>[];

    if (tokens.isNotEmpty) {
      for (final surface in tokens) {
        final canonical = _normalizeCanonical(
          module?.canonicalize(surface) ?? surface,
          wordLevelService,
        );
        if (!_shouldKeepTerm(canonical) || !seen.add(canonical)) continue;
        terms.add(_OverlayTerm(canonical: canonical, displayText: surface));
        if (terms.length >= _maxCandidateTerms) return terms;
      }
      return terms;
    }

    for (final match in RegExp(
      r"[A-Za-z]+(?:[-'][A-Za-z]+)?",
    ).allMatches(trimmedText)) {
      final surface = match.group(0)!;
      final canonical = _normalizeCanonical(surface, wordLevelService);
      if (!_shouldKeepTerm(canonical) || !seen.add(canonical)) continue;
      terms.add(_OverlayTerm(canonical: canonical, displayText: surface));
      if (terms.length >= _maxCandidateTerms) break;
    }
    return terms;
  }

  void _addLearningMarkers(
    _ReadingMemoryOverlayBuilder builder,
    List<_OverlayTerm> terms,
  ) {
    final learningWords = {
      for (final word in _userVocabulary.learningWords)
        ReadingMemoryIds.normalizeCanonical(word),
    };
    if (learningWords.isEmpty) return;

    for (final term in terms) {
      if (!learningWords.contains(term.canonical)) continue;
      builder.add(
        term.canonical,
        displayText: term.displayText,
        type: ReadingMemoryOverlayMarkerType.learning,
      );
    }
  }

  Future<void> _addRepeatedLookupMarkers(
    _ReadingMemoryOverlayBuilder builder,
    List<_OverlayTerm> terms,
  ) async {
    for (final term in terms) {
      final count = await _repository.eventCountForCanonical(
        languageCode: _languageCode,
        canonicalKey: term.canonical,
        type: MemoryEventType.lookup,
      );
      if (count < _repeatedLookupThreshold) continue;
      builder.add(
        term.canonical,
        displayText: term.displayText,
        type: ReadingMemoryOverlayMarkerType.repeatedLookup,
      );
    }
  }

  Future<void> _addReviewDueMarkers(
    _ReadingMemoryOverlayBuilder builder,
    List<_OverlayTerm> terms,
  ) async {
    final termsByCanonical = {
      for (final term in terms) term.canonical: term,
    };
    final candidates = await _repository.reviewCandidates(
      status: ReviewCandidateStatus.pending,
      limit: _maxCandidateTerms,
    );
    for (final candidate in candidates) {
      final entity = await _repository.entityById(candidate.entityId);
      if (entity == null) continue;
      final term = termsByCanonical[entity.canonicalKey];
      if (term == null) continue;
      builder.add(
        term.canonical,
        displayText: term.displayText,
        type: ReadingMemoryOverlayMarkerType.reviewDue,
      );
    }
  }

  Future<void> _addBookTermMarkers(
    _ReadingMemoryOverlayBuilder builder,
    List<_OverlayTerm> terms, {
    required String? bookId,
  }) async {
    final trimmedBookId = bookId?.trim();
    final glossary = _glossaryService;
    if (trimmedBookId == null || trimmedBookId.isEmpty || glossary == null) {
      return;
    }

    final termsByCanonical = {
      for (final term in terms) term.canonical: term,
    };
    final entries = await glossary.getBookGlossary(trimmedBookId);
    for (final entry in entries) {
      final canonical = _canonicalForBookTerm(entry);
      final term = termsByCanonical[canonical];
      if (term == null) continue;
      builder.add(
        term.canonical,
        displayText: term.displayText,
        type: ReadingMemoryOverlayMarkerType.bookTerm,
        contextText: entry.sourceContext,
      );
    }
  }

  String _canonicalForBookTerm(BookGlossaryEntry entry) {
    final raw = entry.canonicalForm?.trim().isNotEmpty == true
        ? entry.canonicalForm!
        : entry.word;
    return ReadingMemoryIds.normalizeCanonical(raw);
  }

  String _normalizeCanonical(String value, WordLevelService? wordLevelService) {
    final canonical = ReadingMemoryIds.normalizeCanonical(value);
    if (canonical.isEmpty) return canonical;
    return wordLevelService?.canonicalForm(canonical) ?? canonical;
  }

  bool _shouldKeepTerm(String canonical) {
    return canonical.length >= 2;
  }
}

final class _OverlayTerm {
  const _OverlayTerm({required this.canonical, required this.displayText});

  final String canonical;
  final String displayText;
}

final class _ReadingMemoryOverlayBuilder {
  _ReadingMemoryOverlayBuilder({required this.maxMarkers});

  final int maxMarkers;
  final Map<String, ReadingMemoryOverlayMarker> _markers = {};

  void add(
    String canonicalKey, {
    required String displayText,
    required ReadingMemoryOverlayMarkerType type,
    String? contextText,
  }) {
    final canonical = canonicalKey.toLowerCase().trim();
    if (canonical.isEmpty) return;
    if (!_markers.containsKey(canonical) && _markers.length >= maxMarkers) {
      return;
    }
    final marker = ReadingMemoryOverlayMarker(
      canonicalKey: canonical,
      displayText: displayText,
      contextText: contextText,
      types: {type},
    );
    _markers[canonical] = _markers[canonical]?.merge(marker) ?? marker;
  }

  ReadingMemoryOverlayProjection build() {
    if (_markers.isEmpty) return ReadingMemoryOverlayProjection.empty;
    return ReadingMemoryOverlayProjection.fromMarkers(_markers.values);
  }
}
