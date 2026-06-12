import '../dao/word_context_dao.dart';
import '../../repositories/hive_repository_box.dart';
import '../../repositories/word_context_repository.dart';

final class DriftWordContextRepository implements WordContextRepository {
  DriftWordContextRepository(
    this._dao, {
    required String languageCode,
    Map<String, String> initialValues = const {},
  }) : _languageCode = activeHiveLanguageCode(languageCode),
       _cache = Map.of(initialValues);

  final WordContextDao _dao;
  final String _languageCode;
  final Map<String, String> _cache;

  @override
  Future<void> init() async {
    final values = await _dao.allValues(_languageCode);
    _cache
      ..clear()
      ..addAll(values);
  }

  @override
  String? getEncodedExamples(String word) => _cache[word];

  @override
  Future<void> putEncodedExamples(String word, String encodedExamples) async {
    await _dao.putData(word, _languageCode, encodedExamples);
    _cache[word] = encodedExamples;
  }

  @override
  Future<void> close() async {}
}
