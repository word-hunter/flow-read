import 'word_repository.dart';

class CompositeWordRepository implements WordRepository {
  final List<WordRepository> _sources;

  CompositeWordRepository(this._sources);

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    for (final source in _sources) {
      final result = await source.lookup(word, languageCode: languageCode);
      if (result != null) return result;
    }
    return null;
  }
}
