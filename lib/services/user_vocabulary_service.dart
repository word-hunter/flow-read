import '../models/user_vocabulary.dart';
import '../storage/repositories/user_vocabulary_repository.dart';
import 'reading_memory/reading_memory_service.dart';

class UserVocabularyService {
  static const emptyRevisionSignature = '811c9dc5';

  UserVocabularyService({
    required UserVocabularyRepository repository,
    ReadingMemoryService? readingMemory,
    String? languageCode,
  }) : languageCode = _normalizeLanguageCode(languageCode),
       _repository = repository,
       _readingMemory = readingMemory;

  final String languageCode;
  final UserVocabularyRepository _repository;
  final ReadingMemoryService? _readingMemory;

  Future<void> init() async {
    await _repository.init();
  }

  UserWordStatus? getStatus(String word) {
    return _repository.getStatus(word);
  }

  bool isKnown(String word) {
    return getStatus(word) == UserWordStatus.known;
  }

  bool isLearning(String word) {
    return getStatus(word) == UserWordStatus.learning;
  }

  Set<String> get knownWords {
    return _repository.wordsWithStatus(UserWordStatus.known);
  }

  Set<String> get learningWords {
    return _repository.wordsWithStatus(UserWordStatus.learning);
  }

  Map<String, UserWordStatus> get allWords {
    return _repository.allWords;
  }

  String get revisionSignature {
    final entries = allWords.entries.toList()
      ..sort((a, b) {
        final wordResult = a.key.compareTo(b.key);
        if (wordResult != 0) return wordResult;
        return a.value.name.compareTo(b.value.name);
      });

    var hash = 0x811c9dc5;
    for (final entry in entries) {
      final token = '${entry.key}:${entry.value.name};';
      for (var i = 0; i < token.length; i += 1) {
        hash ^= token.codeUnitAt(i);
        hash = (hash * 0x01000193) & 0xffffffff;
      }
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<void> setKnown(String word) async {
    await _repository.setStatus(word, UserWordStatus.known);
    await _recordMemoryStatus(word, UserWordStatus.known);
  }

  Future<void> setLearning(String word) async {
    await _repository.setStatus(word, UserWordStatus.learning);
    await _recordMemoryStatus(word, UserWordStatus.learning);
  }

  Future<void> setUnknown(String word) async {
    await _repository.remove(word);
    await _recordMemoryStatus(word, null);
  }

  Future<void> close() async {
    await _repository.close();
  }

  static String _normalizeLanguageCode(String? code) {
    final normalized = code?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ? 'en' : normalized;
  }

  Future<void> _recordMemoryStatus(String word, UserWordStatus? status) async {
    await _readingMemory?.recordVocabularyStatus(
      targetText: word,
      canonical: word,
      status: status,
      languageCode: languageCode,
    );
  }
}
