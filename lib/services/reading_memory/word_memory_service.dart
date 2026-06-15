import '../../models/reading_memory.dart';
import '../../models/user_vocabulary.dart';
import '../../storage/repositories/reading_memory_repository.dart';
import '../../storage/repositories/repository_language.dart';
import '../user_vocabulary_service.dart';
import '../word_context_service.dart';
import 'reading_memory_ids.dart';

class WordMemoryService {
  WordMemoryService({
    required ReadingMemoryRepository repository,
    required UserVocabularyService userVocabulary,
    required WordContextService wordContext,
    String? languageCode,
  }) : _repository = repository,
       _userVocabulary = userVocabulary,
       _wordContext = wordContext,
       _languageCode = normalizeRepositoryLanguageCode(languageCode);

  final ReadingMemoryRepository _repository;
  final UserVocabularyService _userVocabulary;
  final WordContextService _wordContext;
  final String _languageCode;

  Future<void> init() {
    return _repository.init();
  }

  Future<WordMemoryCard> getWordCard({
    required String canonical,
    String? displayText,
    String? languageCode,
  }) async {
    final normalized = ReadingMemoryIds.normalizeCanonical(canonical);
    final language = normalizeRepositoryLanguageCode(
      languageCode ?? _languageCode,
    );
    if (normalized.isEmpty) {
      return WordMemoryCard(
        canonical: '',
        displayText: displayText?.trim() ?? '',
        languageCode: language,
        lookupCount: 0,
      );
    }

    final entity = await _repository.entityByCanonical(
      languageCode: language,
      type: KnowledgeEntityType.word,
      canonicalKey: normalized,
    );
    final explanations = entity == null
        ? const <MemoryKnowledgeExplanation>[]
        : await _repository.explanationsForEntity(entity.id);
    final evidences = entity == null
        ? const <MemoryKnowledgeEvidence>[]
        : await _repository.evidencesForEntity(entity.id);
    final recentEvents = await _repository.eventsForCanonical(
      languageCode: language,
      canonicalKey: normalized,
    );
    final lookupCount = await _repository.eventCountForCanonical(
      languageCode: language,
      canonicalKey: normalized,
      type: MemoryEventType.lookup,
    );

    return WordMemoryCard(
      canonical: normalized,
      displayText: displayText?.trim().isNotEmpty == true
          ? displayText!.trim()
          : entity?.displayText ?? normalized,
      languageCode: language,
      userStatus: _statusFor(normalized),
      entity: entity,
      lookupCount: lookupCount,
      contextExamples: _wordContext.examplesFor(normalized),
      savedExplanations: explanations,
      evidences: evidences,
      recentEvents: recentEvents,
    );
  }

  UserWordStatus? _statusFor(String canonical) {
    return _userVocabulary.getStatus(canonical);
  }
}
