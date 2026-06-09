/// Compound word analysis result.
class CompoundAnalysisResult {
  final List<String> components;
  final List<String?> componentMeanings;
  final double confidence;

  const CompoundAnalysisResult({
    required this.components,
    required this.componentMeanings,
    required this.confidence,
  });
}
