import 'package:flow_ai/flow_ai.dart';

import '../../models/reading_memory.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import '../user_vocabulary_service.dart';
import 'reading_memory_ids.dart';

class ContextRetrievalService {
  ContextRetrievalService({
    required ReadingMemoryRepository repository,
    required UserVocabularyService userVocabulary,
    String? languageCode,
    int repeatedLookupThreshold = 2,
  }) : _repository = repository,
       _userVocabulary = userVocabulary,
       _languageCode = normalizeRepositoryLanguageCode(languageCode),
       _repeatedLookupThreshold = repeatedLookupThreshold;

  final ReadingMemoryRepository _repository;
  final UserVocabularyService _userVocabulary;
  final String _languageCode;
  final int _repeatedLookupThreshold;

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

    return ExplanationContextBundle(
      currentSentence: currentSentence,
      surroundingText: surroundingText,
      sameWordOccurrences: existing?.sameWordOccurrences ?? const [],
      relatedEvents: existing?.relatedEvents ?? const [],
      mentionedCharacters: existing?.mentionedCharacters ?? const [],
      historyLookups: existing?.historyLookups ?? const [],
      knownWords: _matchedVocabulary(_userVocabulary.knownWords, terms),
      learningWords: _matchedVocabulary(_userVocabulary.learningWords, terms),
      repeatedLookupWords: await _repeatedLookupWords(terms),
      savedExplanations: await _savedExplanationPreviews(context, terms),
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

final class _ExplanationQuery {
  const _ExplanationQuery(this.type, this.canonical);

  final KnowledgeEntityType type;
  final String canonical;

  String get key => '${type.storageValue}:$canonical';
}
