import 'package:flow_dictionary/flow_dictionary.dart';

class CompoundWordAnalyzer {
  CompoundWordAnalyzer({
    required this.isKnownWord,
    required this.getMeaning,
    this.maxComponents = 3,
    this.minComponentLength = 3,
  });

  final bool Function(String word) isKnownWord;
  final String? Function(String word) getMeaning;
  final int maxComponents;
  final int minComponentLength;

  CompoundAnalysisResult? analyze(String word) {
    final normalized = word.toLowerCase().replaceAll(RegExp(r"[^a-z']"), '');
    if (normalized.length < minComponentLength * 2) return null;

    final best = _findBestDecomposition(normalized);
    if (best == null || best.length < 2) return null;
    if (best.every((component) => component.length < 4)) return null;

    return CompoundAnalysisResult(
      components: best,
      componentMeanings: best.map(getMeaning).toList(),
      confidence: best.where(isKnownWord).length / best.length,
    );
  }

  List<String>? _findBestDecomposition(String word) {
    List<String>? best;
    var bestScore = -1;

    void trySplit(int start, List<String> current) {
      if (current.length > maxComponents) return;
      if (start >= word.length) {
        final score = _score(current);
        if (score > bestScore) {
          bestScore = score;
          best = List.of(current);
        }
        return;
      }

      if (current.isNotEmpty && word[start] == 's') {
        trySplit(start + 1, current);
      }

      for (var end = word.length; end >= start + minComponentLength; end--) {
        final part = word.substring(start, end);
        if (!isKnownWord(part)) continue;
        current.add(part);
        trySplit(end, current);
        current.removeLast();
      }
    }

    trySplit(0, []);
    return best;
  }

  int _score(List<String> components) {
    if (components.isEmpty) return -1;
    var score = 100 - components.length * 16;
    for (final component in components) {
      score += component.length * 3;
    }
    return score;
  }
}
