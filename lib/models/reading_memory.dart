import 'user_vocabulary.dart';
import 'word_context_example.dart';

enum SourceKind {
  book('book'),
  rss('rss'),
  browser('browser'),
  manual('manual'),
  ai('ai');

  const SourceKind(this.storageValue);

  final String storageValue;

  static SourceKind fromStorage(String value) {
    return SourceKind.values.firstWhere(
      (kind) => kind.storageValue == value,
      orElse: () => SourceKind.manual,
    );
  }
}

enum SourceAvailability {
  available('available'),
  archived('archived'),
  deleted('deleted');

  const SourceAvailability(this.storageValue);

  final String storageValue;

  static SourceAvailability fromStorage(String value) {
    return SourceAvailability.values.firstWhere(
      (availability) => availability.storageValue == value,
      orElse: () => SourceAvailability.available,
    );
  }
}

enum KnowledgeEntityType {
  word('word'),
  phrase('phrase'),
  pattern('pattern'),
  grammar('grammar'),
  concept('concept'),
  character('character'),
  bookTerm('book_term'),
  sentence('sentence');

  const KnowledgeEntityType(this.storageValue);

  final String storageValue;

  static KnowledgeEntityType fromStorage(String value) {
    return KnowledgeEntityType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => KnowledgeEntityType.word,
    );
  }
}

enum KnowledgeMasteryState {
  unknown('unknown'),
  learning('learning'),
  mastered('mastered');

  const KnowledgeMasteryState(this.storageValue);

  final String storageValue;

  static KnowledgeMasteryState fromStorage(String value) {
    return KnowledgeMasteryState.values.firstWhere(
      (state) => state.storageValue == value,
      orElse: () => KnowledgeMasteryState.unknown,
    );
  }
}

enum ExplanationSource {
  ai('ai'),
  user('user'),
  dictionary('dictionary'),
  generated('generated');

  const ExplanationSource(this.storageValue);

  final String storageValue;

  static ExplanationSource fromStorage(String value) {
    return ExplanationSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => ExplanationSource.user,
    );
  }
}

enum EvidenceRetentionPolicy {
  deleteWithSource('deleteWithSource'),
  keepSnippet('keepSnippet'),
  keepMetadataOnly('keepMetadataOnly');

  const EvidenceRetentionPolicy(this.storageValue);

  final String storageValue;

  static EvidenceRetentionPolicy fromStorage(String value) {
    return EvidenceRetentionPolicy.values.firstWhere(
      (policy) => policy.storageValue == value,
      orElse: () => EvidenceRetentionPolicy.keepSnippet,
    );
  }
}

enum MemoryEventType {
  lookup('lookup'),
  aiAnalyze('ai_analyze'),
  saveExplanation('save_explanation'),
  markLearning('mark_learning'),
  markKnown('mark_known'),
  markUnknown('mark_unknown'),
  review('review'),
  bookmark('bookmark');

  const MemoryEventType(this.storageValue);

  final String storageValue;

  static MemoryEventType fromStorage(String value) {
    return MemoryEventType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => MemoryEventType.lookup,
    );
  }
}

enum ReviewCandidateStatus {
  pending('pending'),
  accepted('accepted'),
  dismissed('dismissed'),
  converted('converted');

  const ReviewCandidateStatus(this.storageValue);

  final String storageValue;

  static ReviewCandidateStatus fromStorage(String value) {
    return ReviewCandidateStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => ReviewCandidateStatus.pending,
    );
  }
}

final class MemorySourceRecord {
  const MemorySourceRecord({
    required this.id,
    required this.sourceKind,
    required this.titleSnapshot,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    this.authorSnapshot,
    this.fingerprint,
    this.availability = SourceAvailability.available,
    this.deletedAt,
  });

  final String id;
  final SourceKind sourceKind;
  final String titleSnapshot;
  final String? authorSnapshot;
  final String languageCode;
  final String? fingerprint;
  final SourceAvailability availability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

final class MemoryKnowledgeEntity {
  const MemoryKnowledgeEntity({
    required this.id,
    required this.languageCode,
    required this.type,
    required this.canonicalKey,
    required this.displayText,
    required this.normalizedText,
    required this.createdAt,
    required this.updatedAt,
    this.masteryState = KnowledgeMasteryState.unknown,
    this.confidence = 0,
    this.lastAccessedAt,
  });

  final String id;
  final String languageCode;
  final KnowledgeEntityType type;
  final String canonicalKey;
  final String displayText;
  final String normalizedText;
  final KnowledgeMasteryState masteryState;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
}

final class MemoryKnowledgeExplanation {
  const MemoryKnowledgeExplanation({
    required this.id,
    required this.entityId,
    required this.explanation,
    required this.source,
    required this.targetLanguage,
    required this.createdAt,
    required this.updatedAt,
    this.promptVersion,
  });

  final String id;
  final String entityId;
  final String explanation;
  final ExplanationSource source;
  final String targetLanguage;
  final String? promptVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class MemoryKnowledgeEvidence {
  const MemoryKnowledgeEvidence({
    required this.id,
    required this.entityId,
    required this.sourceKind,
    required this.shortExcerpt,
    required this.sourceTitleSnapshot,
    required this.sourceAvailability,
    required this.retentionPolicy,
    required this.createdAt,
    this.sourceId,
    this.bookId,
    this.chapterIndex,
    this.locationLocator,
    this.excerptHash,
  });

  final String id;
  final String entityId;
  final String? sourceId;
  final SourceKind sourceKind;
  final String? bookId;
  final int? chapterIndex;
  final String? locationLocator;
  final String shortExcerpt;
  final String? excerptHash;
  final String sourceTitleSnapshot;
  final SourceAvailability sourceAvailability;
  final EvidenceRetentionPolicy retentionPolicy;
  final DateTime createdAt;
}

final class MemoryEvent {
  const MemoryEvent({
    required this.id,
    required this.type,
    required this.languageCode,
    required this.targetText,
    required this.canonicalKey,
    required this.createdAt,
    this.sourceId,
    this.entityId,
    this.sourceRefJson = '{}',
    this.metadataJson = '{}',
  });

  final String id;
  final MemoryEventType type;
  final String languageCode;
  final String? sourceId;
  final String? entityId;
  final String targetText;
  final String canonicalKey;
  final String sourceRefJson;
  final String metadataJson;
  final DateTime createdAt;
}

final class MemorySourceRef {
  const MemorySourceRef({
    required this.sourceId,
    required this.sourceKind,
    required this.sourceTitleSnapshot,
    this.bookId,
    this.chapterIndex,
    this.locationLocator,
    this.sourceAvailability = SourceAvailability.available,
  });

  final String sourceId;
  final SourceKind sourceKind;
  final String sourceTitleSnapshot;
  final String? bookId;
  final int? chapterIndex;
  final String? locationLocator;
  final SourceAvailability sourceAvailability;
}

final class WordMemoryCard {
  const WordMemoryCard({
    required this.canonical,
    required this.displayText,
    required this.languageCode,
    required this.lookupCount,
    this.entity,
    this.userStatus,
    this.contextExamples = const [],
    this.savedExplanations = const [],
    this.evidences = const [],
    this.recentEvents = const [],
  });

  final String canonical;
  final String displayText;
  final String languageCode;
  final UserWordStatus? userStatus;
  final MemoryKnowledgeEntity? entity;
  final int lookupCount;
  final List<WordContextExample> contextExamples;
  final List<MemoryKnowledgeExplanation> savedExplanations;
  final List<MemoryKnowledgeEvidence> evidences;
  final List<MemoryEvent> recentEvents;

  bool get hasPersonalMemory {
    return userStatus != null ||
        lookupCount > 0 ||
        contextExamples.isNotEmpty ||
        savedExplanations.isNotEmpty ||
        evidences.isNotEmpty ||
        recentEvents.isNotEmpty;
  }
}

final class ReviewCandidate {
  const ReviewCandidate({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.targetText,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.explanationId,
    this.evidenceId,
    this.suggestedQuestionType,
  });

  final String id;
  final String entityId;
  final KnowledgeEntityType entityType;
  final String targetText;
  final String? explanationId;
  final String? evidenceId;
  final String? suggestedQuestionType;
  final double priority;
  final ReviewCandidateStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
