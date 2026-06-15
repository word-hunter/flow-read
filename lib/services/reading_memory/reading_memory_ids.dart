import '../../models/reading_memory.dart';
import '../../storage/repositories/repository_language.dart';

final class ReadingMemoryIds {
  const ReadingMemoryIds._();

  static String source(SourceKind kind, String localId) {
    final normalized = Uri.encodeComponent(localId.trim());
    return '${kind.storageValue}:$normalized';
  }

  static String entity({
    required String languageCode,
    required KnowledgeEntityType type,
    required String canonicalKey,
  }) {
    final language = normalizeRepositoryLanguageCode(languageCode);
    final canonical = Uri.encodeComponent(normalizeCanonical(canonicalKey));
    return 'entity:$language:${type.storageValue}:$canonical';
  }

  static String normalizeCanonical(String value) {
    return value.toLowerCase().trim();
  }
}
