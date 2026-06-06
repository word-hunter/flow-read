class ReadingInsightProfile {
  const ReadingInsightProfile({
    this.focusAreas = const {},
    this.weakPosCategories = const {},
    this.lookupDensity = 0,
    this.recheckRate = 0,
  });

  final Set<String> focusAreas;
  final Map<String, double> weakPosCategories;
  final double lookupDensity;
  final double recheckRate;

  String get learningFocusSummary {
    final parts = <String>[];
    if (focusAreas.isNotEmpty) {
      final focus = focusAreas.toList()..sort();
      parts.add('Focus: ${focus.take(5).join(', ')}');
    }
    if (weakPosCategories.isNotEmpty) {
      final weak = weakPosCategories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      parts.add(
        'Weak POS: ${weak.take(4).map((e) => '${e.key} ${(e.value * 100).round()}%').join(', ')}',
      );
    }
    if (lookupDensity > 0) {
      parts.add('Lookup density: ${lookupDensity.toStringAsFixed(1)}/k words');
    }
    if (recheckRate > 0) {
      parts.add('Recheck rate: ${(recheckRate * 100).round()}%');
    }
    final summary = parts.join('; ');
    if (summary.length <= 800) return summary;
    return summary.substring(0, 800);
  }

  bool get isEmpty =>
      focusAreas.isEmpty &&
      weakPosCategories.isEmpty &&
      lookupDensity == 0 &&
      recheckRate == 0;
}
