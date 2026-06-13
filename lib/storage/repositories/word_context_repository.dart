abstract class WordContextRepository {
  Future<void> init();
  String? getEncodedExamples(String word);
  Future<void> putEncodedExamples(String word, String encodedExamples);
  Future<void> close();
}
