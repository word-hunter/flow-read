enum ReadingMemoryOverlayMarkerType {
  learning,
  repeatedLookup,
  reviewDue,
  bookTerm,
}

final class ReadingMemoryOverlayMarker {
  const ReadingMemoryOverlayMarker({
    required this.canonicalKey,
    required this.displayText,
    required this.types,
    this.contextText,
  });

  final String canonicalKey;
  final String displayText;
  final Set<ReadingMemoryOverlayMarkerType> types;
  final String? contextText;

  ReadingMemoryOverlayMarker merge(ReadingMemoryOverlayMarker other) {
    return ReadingMemoryOverlayMarker(
      canonicalKey: canonicalKey,
      displayText: displayText.isNotEmpty ? displayText : other.displayText,
      contextText: contextText ?? other.contextText,
      types: {...types, ...other.types},
    );
  }

  ReadingMemoryOverlayMarkerType get primaryType {
    for (final type in const [
      ReadingMemoryOverlayMarkerType.reviewDue,
      ReadingMemoryOverlayMarkerType.bookTerm,
      ReadingMemoryOverlayMarkerType.learning,
      ReadingMemoryOverlayMarkerType.repeatedLookup,
    ]) {
      if (types.contains(type)) return type;
    }
    return ReadingMemoryOverlayMarkerType.repeatedLookup;
  }
}

final class ReadingMemoryOverlayProjection {
  const ReadingMemoryOverlayProjection({
    this.markersByCanonical = const {},
  });

  static const empty = ReadingMemoryOverlayProjection();

  final Map<String, ReadingMemoryOverlayMarker> markersByCanonical;

  bool get isEmpty => markersByCanonical.isEmpty;
  bool get isNotEmpty => markersByCanonical.isNotEmpty;

  ReadingMemoryOverlayMarker? markerFor(String canonicalKey) {
    return markersByCanonical[canonicalKey.toLowerCase().trim()];
  }

  static ReadingMemoryOverlayProjection fromMarkers(
    Iterable<ReadingMemoryOverlayMarker> markers,
  ) {
    final byCanonical = <String, ReadingMemoryOverlayMarker>{};
    for (final marker in markers) {
      final canonical = marker.canonicalKey.toLowerCase().trim();
      if (canonical.isEmpty || marker.types.isEmpty) continue;
      final normalized = ReadingMemoryOverlayMarker(
        canonicalKey: canonical,
        displayText: marker.displayText.trim(),
        contextText: _trimOrNull(marker.contextText),
        types: marker.types,
      );
      byCanonical[canonical] =
          byCanonical[canonical]?.merge(normalized) ?? normalized;
    }
    if (byCanonical.isEmpty) return empty;
    return ReadingMemoryOverlayProjection(
      markersByCanonical: Map.unmodifiable(byCanonical),
    );
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
