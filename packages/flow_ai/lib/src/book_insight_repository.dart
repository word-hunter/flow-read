import 'ai_cache_service.dart';
import 'models/book_analysis.dart';

class BookInsightRepository {
  BookInsightRepository({
    required AICacheService cacheService,
  }) : _cacheService = cacheService;

  final AICacheService _cacheService;
  final Map<String, BookAnalysisData> _analysisSnapshots = {};

  int get analysisSnapshotCount => _analysisSnapshots.length;

  void saveAnalysisSnapshot({
    required BookAnalysisData data,
    required String chapterCoverageHash,
  }) {
    final key = BookAnalysisSnapshotKey.fromData(
      data,
      chapterCoverageHash: chapterCoverageHash,
    );
    _analysisSnapshots[key.cacheKey] = data;
  }

  BookAnalysisData? loadAnalysisSnapshot(BookAnalysisSnapshotKey key) {
    return _analysisSnapshots[key.cacheKey];
  }

  void clearAnalysisForBook(String bookId) {
    _analysisSnapshots.removeWhere((_, data) => data.bookId == bookId);
  }

  void clearAllAnalysisSnapshots() {
    _analysisSnapshots.clear();
  }

  Future<void> saveSynthesisResult({
    required BookSynthesisCacheKey key,
    required String jsonString,
  }) {
    return _cacheService.saveBookArtifact(
      key: key.toBookCacheKey(),
      response: jsonString,
    );
  }

  Future<String?> loadSynthesisResult(BookSynthesisCacheKey key) {
    return _cacheService.loadBookArtifact(key: key.toBookCacheKey());
  }
}

class BookAnalysisSnapshotKey {
  final String bookId;
  final String scopeHash;
  final String chapterCoverageHash;
  final String schemaVersion;
  final String sourceLanguage;
  final String outputLanguage;

  const BookAnalysisSnapshotKey({
    required this.bookId,
    required this.scopeHash,
    required this.chapterCoverageHash,
    required this.schemaVersion,
    required this.sourceLanguage,
    required this.outputLanguage,
  });

  factory BookAnalysisSnapshotKey.fromData(
    BookAnalysisData data, {
    required String chapterCoverageHash,
  }) {
    return BookAnalysisSnapshotKey(
      bookId: data.bookId,
      scopeHash: data.scope.scopeHash,
      chapterCoverageHash: chapterCoverageHash,
      schemaVersion: data.schemaVersion,
      sourceLanguage: data.scope.sourceLanguage,
      outputLanguage: data.scope.outputLanguage,
    );
  }

  String get cacheKey => _joinKeyParts([
    bookId,
    scopeHash,
    chapterCoverageHash,
    schemaVersion,
    sourceLanguage,
    outputLanguage,
  ]);
}

class BookSynthesisCacheKey {
  final String bookId;
  final String synthesisType;
  final String scopeHash;
  final String coverageHash;
  final int promptVersion;
  final String schemaVersion;
  final String modelId;
  final String sourceLanguage;
  final String outputLanguage;
  final String spoilerBoundaryHash;

  const BookSynthesisCacheKey({
    required this.bookId,
    required this.synthesisType,
    required this.scopeHash,
    required this.coverageHash,
    required this.promptVersion,
    required this.schemaVersion,
    required this.modelId,
    this.sourceLanguage = 'book',
    required this.outputLanguage,
    required this.spoilerBoundaryHash,
  });

  AIBookCacheKey toBookCacheKey() {
    return AIBookCacheKey(
      kind: 'book_synthesis',
      variant: synthesisType,
      bookId: bookId,
      contentHash: coverageHash,
      promptVersion: promptVersion,
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      schemaVersion: schemaVersion,
      scopeHash: scopeHash,
      coverageHash: coverageHash,
      modelId: modelId,
      spoilerBoundaryHash: spoilerBoundaryHash,
    );
  }

  BookSynthesisCacheKey copyWith({
    String? bookId,
    String? synthesisType,
    String? scopeHash,
    String? coverageHash,
    int? promptVersion,
    String? schemaVersion,
    String? modelId,
    String? sourceLanguage,
    String? outputLanguage,
    String? spoilerBoundaryHash,
  }) {
    return BookSynthesisCacheKey(
      bookId: bookId ?? this.bookId,
      synthesisType: synthesisType ?? this.synthesisType,
      scopeHash: scopeHash ?? this.scopeHash,
      coverageHash: coverageHash ?? this.coverageHash,
      promptVersion: promptVersion ?? this.promptVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      modelId: modelId ?? this.modelId,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      spoilerBoundaryHash: spoilerBoundaryHash ?? this.spoilerBoundaryHash,
    );
  }
}

String _joinKeyParts(List<Object?> parts) {
  return parts.map((part) => Uri.encodeComponent(part.toString())).join('|');
}
