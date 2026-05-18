import 'word_repository.dart';

class CompositeWordRepository implements WordRepository {
  final List<WordRepository> _sources;

  CompositeWordRepository(this._sources);

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    for (final source in _sources) {
      final result = await source.lookup(word);
      if (result != null) return result;
    }
    return null;
  }
}
