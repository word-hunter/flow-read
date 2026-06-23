import 'models/ai_summary.dart';
import 'models/book_analysis.dart';
import 'models/chapter_insight.dart';
import 'models/character_registry_entry.dart';

abstract interface class BookAnalysisCharacterRegistry {
  String? matchCanonical(String bookId, String name);
}

class EmptyBookAnalysisCharacterRegistry
    implements BookAnalysisCharacterRegistry {
  const EmptyBookAnalysisCharacterRegistry();

  @override
  String? matchCanonical(String bookId, String name) => null;
}

class StaticBookAnalysisCharacterRegistry
    implements BookAnalysisCharacterRegistry {
  const StaticBookAnalysisCharacterRegistry(this.entriesByBookId);

  final Map<String, List<CharacterRegistryEntry>> entriesByBookId;

  @override
  String? matchCanonical(String bookId, String name) {
    final entries = entriesByBookId[bookId] ?? const [];
    for (final entry in entries) {
      if (entry.matches(name)) return entry.canonicalName;
    }
    return null;
  }
}

class BookAnalysisAggregator {
  const BookAnalysisAggregator({
    this.characterRegistry = const EmptyBookAnalysisCharacterRegistry(),
    this.clock,
  });

  static const schemaVersion = '1.0.0';

  final BookAnalysisCharacterRegistry characterRegistry;
  final DateTime Function()? clock;

  BookAnalysisSession start({
    required String bookId,
    required int totalChapters,
  }) {
    return BookAnalysisSession._(
      bookId: bookId,
      totalChapters: totalChapters,
      characterRegistry: characterRegistry,
    );
  }

  BookAnalysisData build({
    required AnalysisScope scope,
    required Map<int, ChapterInsight> chapterInsights,
    required int totalChapters,
  }) {
    final session = start(
      bookId: scope.bookId,
      totalChapters: totalChapters,
    );
    final chapters = chapterInsights.keys.toList()..sort();
    for (final chapterIndex in chapters) {
      if (chapterIndex < scope.startChapterIndex ||
          chapterIndex > scope.endChapterIndex) {
        continue;
      }
      session.mergeChapter(chapterIndex, chapterInsights[chapterIndex]!);
    }
    return session.build(
      scope,
      analyzedAt: clock?.call() ?? DateTime.now().toUtc(),
    );
  }
}

class BookAnalysisSession {
  BookAnalysisSession._({
    required this.bookId,
    required this.totalChapters,
    required BookAnalysisCharacterRegistry characterRegistry,
  }) : _characterRegistry = characterRegistry;

  final String bookId;
  final int totalChapters;
  final BookAnalysisCharacterRegistry _characterRegistry;
  final Map<String, _MutableCharacterAccumulator> _characters = {};
  final List<StoryEvent> _events = [];
  final Map<String, _MutableLocationAccumulator> _locations = {};
  final Map<String, _ThemeAccumulator> _themes = {};
  final Set<int> _analyzedChapters = {};

  double get coverage {
    if (totalChapters <= 0) return 0;
    return _analyzedChapters.length / totalChapters;
  }

  void mergeChapter(int chapterIndex, ChapterInsight insight) {
    if (!_analyzedChapters.add(chapterIndex)) return;

    _mergeCharacters(chapterIndex, insight.summary.characterDevelopments);
    _mergeEvents(chapterIndex, insight.summary.events);
    _mergeLocations(chapterIndex, insight.locations);
    _mergeThemes(insight.themes);
  }

  BookAnalysisData build(AnalysisScope scope, {DateTime? analyzedAt}) {
    final characters = _characters.values.map((acc) => acc.freeze()).toList()
      ..sort((a, b) {
        final chapterOrder = a.firstChapter.compareTo(b.firstChapter);
        if (chapterOrder != 0) return chapterOrder;
        return a.canonicalName.toLowerCase().compareTo(
          b.canonicalName.toLowerCase(),
        );
      });

    final events = List<StoryEvent>.of(_events)
      ..sort((a, b) {
        final chapterOrder = a.chapterIndex.compareTo(b.chapterIndex);
        if (chapterOrder != 0) return chapterOrder;
        return a.description.compareTo(b.description);
      });

    final locations = _locations.values.map((acc) => acc.freeze()).toList()
      ..sort((a, b) {
        final firstA = a.chapters.isEmpty ? 0 : a.chapters.reduce(_minInt);
        final firstB = b.chapters.isEmpty ? 0 : b.chapters.reduce(_minInt);
        final chapterOrder = firstA.compareTo(firstB);
        if (chapterOrder != 0) return chapterOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final themes = _themes.values.toList()
      ..sort((a, b) {
        final countOrder = b.count.compareTo(a.count);
        if (countOrder != 0) return countOrder;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

    return BookAnalysisData(
      bookId: scope.bookId,
      scope: scope,
      characters: characters,
      storyEvents: events,
      locations: locations,
      themes: themes.map((theme) => theme.label),
      coverage: coverage,
      schemaVersion: BookAnalysisAggregator.schemaVersion,
      analyzedAt: analyzedAt ?? DateTime.now().toUtc(),
    );
  }

  void _mergeCharacters(
    int chapterIndex,
    List<CharacterDevelopment> developments,
  ) {
    for (final development in developments) {
      final rawName = development.character.trim();
      if (rawName.isEmpty) continue;
      final canonical =
          _characterRegistry.matchCanonical(bookId, rawName) ?? rawName;
      final key = canonical.toLowerCase();
      final acc = _characters.putIfAbsent(
        key,
        () => _MutableCharacterAccumulator(
          canonicalName: canonical,
          firstChapter: chapterIndex,
        ),
      );
      acc.firstChapter = _minInt(acc.firstChapter, chapterIndex);
      acc.lastChapter = chapterIndex > acc.lastChapter
          ? chapterIndex
          : acc.lastChapter;
      acc.activeChapters.add(chapterIndex);
      if (rawName != canonical) {
        acc.aliases.add(rawName);
      }
      _addUnique(acc.traits, development.change);
      _appendUnique(acc.actions, development.change);
      acc.confidence = _minDouble(
        acc.confidence,
        _parseConfidence(development.confidence),
      );
      final anchor = _anchorFromSource(
        chapterIndex: chapterIndex,
        source: development.source,
        confidence: development.confidence,
      );
      if (anchor != null) {
        _appendUniqueAnchor(acc.anchors, anchor);
      }
    }
  }

  void _mergeEvents(int chapterIndex, List<SummaryEvent> events) {
    for (final event in events) {
      final description = event.description.trim();
      if (description.isEmpty) continue;
      final anchor = _anchorFromSource(
        chapterIndex: chapterIndex,
        source: event.source,
        confidence: event.confidence,
      );
      _events.add(
        StoryEvent(
          description: description,
          chapterIndex: chapterIndex,
          anchors: [?anchor],
          confidence: _parseConfidence(event.confidence),
        ),
      );
    }
  }

  void _mergeLocations(int chapterIndex, List<LocationRef> locations) {
    for (final location in locations) {
      final name = location.name.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final acc = _locations.putIfAbsent(
        key,
        () => _MutableLocationAccumulator(
          name: name,
          description: _nonEmpty(location.description),
          confidence: location.confidence,
        ),
      );
      acc.chapters.add(chapterIndex);
      acc.description ??= _nonEmpty(location.description);
      acc.confidence = _minDouble(acc.confidence, location.confidence);
      for (final anchor in location.anchors) {
        _appendUniqueAnchor(acc.anchors, anchor);
      }
    }
  }

  void _mergeThemes(List<String> themes) {
    final seenInChapter = <String>{};
    for (final theme in themes) {
      final label = theme.trim();
      if (label.isEmpty) continue;
      final key = label.toLowerCase();
      if (!seenInChapter.add(key)) continue;
      final acc = _themes.putIfAbsent(key, () => _ThemeAccumulator(label));
      acc.count += 1;
    }
  }
}

class _MutableCharacterAccumulator {
  _MutableCharacterAccumulator({
    required this.canonicalName,
    required this.firstChapter,
  }) : lastChapter = firstChapter;

  final String canonicalName;
  final Set<String> aliases = {};
  final Set<String> traits = {};
  final List<String> actions = [];
  int firstChapter;
  int lastChapter;
  final Set<int> activeChapters = {};
  final List<SourceAnchor> anchors = [];
  double confidence = 1.0;

  CharacterCard freeze() {
    return CharacterCard(
      canonicalName: canonicalName,
      aliases: aliases,
      traits: traits,
      actions: actions,
      firstChapter: firstChapter,
      lastChapter: lastChapter,
      activeChapters: activeChapters,
      anchors: anchors,
      confidence: confidence,
    );
  }
}

class _MutableLocationAccumulator {
  _MutableLocationAccumulator({
    required this.name,
    required this.description,
    required this.confidence,
  });

  final String name;
  String? description;
  final Set<int> chapters = {};
  final List<SourceAnchor> anchors = [];
  double confidence;

  LocationNode freeze() {
    return LocationNode(
      name: name,
      description: description,
      chapters: chapters,
      anchors: anchors,
      confidence: confidence,
    );
  }
}

class _ThemeAccumulator {
  _ThemeAccumulator(this.label);

  final String label;
  int count = 0;
}

SourceAnchor? _anchorFromSource({
  required int chapterIndex,
  required String source,
  required String confidence,
}) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;
  return SourceAnchor(
    chapterIndex: chapterIndex,
    quoteSnippet: trimmed,
    confidence: _parseConfidence(confidence),
  );
}

double _parseConfidence(String value) {
  final normalized = value.trim().toLowerCase();
  final numeric = double.tryParse(normalized);
  if (numeric != null) return numeric.clamp(0, 1).toDouble();
  return switch (normalized) {
    'high' => 0.9,
    'medium' => 0.6,
    'low' => 0.3,
    _ => 0.5,
  };
}

void _appendUnique(List<String> values, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return;
  if (values.any(
    (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
  )) {
    return;
  }
  values.add(trimmed);
}

void _addUnique(Set<String> values, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return;
  if (values.any(
    (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
  )) {
    return;
  }
  values.add(trimmed);
}

void _appendUniqueAnchor(List<SourceAnchor> anchors, SourceAnchor anchor) {
  final key = _anchorKey(anchor);
  if (anchors.any((existing) => _anchorKey(existing) == key)) return;
  anchors.add(anchor);
}

String _anchorKey(SourceAnchor anchor) {
  return [
    anchor.chapterIndex,
    anchor.blockIndex ?? '',
    anchor.startOffset ?? '',
    anchor.endOffset ?? '',
    anchor.quoteSnippet.trim().toLowerCase(),
  ].join('|');
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

int _minInt(int a, int b) => a < b ? a : b;

double _minDouble(double a, double b) => a < b ? a : b;
