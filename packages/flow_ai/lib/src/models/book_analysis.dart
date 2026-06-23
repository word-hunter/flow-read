import '../prompt_builder.dart';
import 'chapter_insight.dart';

class AnalysisScope {
  final String bookId;
  final int startChapterIndex;
  final int endChapterIndex;
  final SpoilerBoundary spoilerBoundary;
  final String sourceLanguage;
  final String outputLanguage;
  final String? learningFocus;

  const AnalysisScope({
    required this.bookId,
    required this.startChapterIndex,
    required this.endChapterIndex,
    required this.spoilerBoundary,
    required this.sourceLanguage,
    required this.outputLanguage,
    this.learningFocus,
  });

  factory AnalysisScope.readSoFar({
    required String bookId,
    required int currentChapterIndex,
    String sourceLanguage = 'en',
    String outputLanguage = 'zh',
    String? learningFocus,
  }) {
    return AnalysisScope(
      bookId: bookId,
      startChapterIndex: 0,
      endChapterIndex: currentChapterIndex,
      spoilerBoundary: SpoilerBoundary.chapter(
        bookId: bookId,
        chapterIndex: currentChapterIndex,
        scope: AIContextScope.readSoFar,
      ),
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      learningFocus: learningFocus,
    );
  }

  factory AnalysisScope.fullBook({
    required String bookId,
    required int totalChapters,
    String sourceLanguage = 'en',
    String outputLanguage = 'zh',
    String? learningFocus,
  }) {
    final lastChapter = totalChapters <= 0 ? 0 : totalChapters - 1;
    return AnalysisScope(
      bookId: bookId,
      startChapterIndex: 0,
      endChapterIndex: lastChapter,
      spoilerBoundary: SpoilerBoundary.chapter(
        bookId: bookId,
        chapterIndex: lastChapter,
        scope: AIContextScope.fullBook,
      ),
      sourceLanguage: sourceLanguage,
      outputLanguage: outputLanguage,
      learningFocus: learningFocus,
    );
  }

  String get scopeHash => _stableHash(
    [
      bookId,
      startChapterIndex,
      endChapterIndex,
      spoilerBoundary.scope.promptValue,
      spoilerBoundary.currentUnitId,
      spoilerBoundary.maxReadUnitOrder,
      sourceLanguage,
      outputLanguage,
      learningFocus ?? '',
    ].join('|'),
  );

  AnalysisScope copyWith({
    String? bookId,
    int? startChapterIndex,
    int? endChapterIndex,
    SpoilerBoundary? spoilerBoundary,
    String? sourceLanguage,
    String? outputLanguage,
    String? learningFocus,
  }) {
    return AnalysisScope(
      bookId: bookId ?? this.bookId,
      startChapterIndex: startChapterIndex ?? this.startChapterIndex,
      endChapterIndex: endChapterIndex ?? this.endChapterIndex,
      spoilerBoundary: spoilerBoundary ?? this.spoilerBoundary,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      learningFocus: learningFocus ?? this.learningFocus,
    );
  }
}

class BookAnalysisData {
  final String bookId;
  final AnalysisScope scope;
  final List<CharacterCard> characters;
  final List<StoryEvent> storyEvents;
  final List<LocationNode> locations;
  final List<String> themes;
  final double coverage;
  final String schemaVersion;
  final DateTime analyzedAt;

  BookAnalysisData({
    required this.bookId,
    required this.scope,
    Iterable<CharacterCard> characters = const [],
    Iterable<StoryEvent> storyEvents = const [],
    Iterable<LocationNode> locations = const [],
    Iterable<String> themes = const [],
    required this.coverage,
    required this.schemaVersion,
    required this.analyzedAt,
  }) : characters = List.unmodifiable(characters),
       storyEvents = List.unmodifiable(storyEvents),
       locations = List.unmodifiable(locations),
       themes = List.unmodifiable(themes);

  BookAnalysisData copyWith({
    String? bookId,
    AnalysisScope? scope,
    Iterable<CharacterCard>? characters,
    Iterable<StoryEvent>? storyEvents,
    Iterable<LocationNode>? locations,
    Iterable<String>? themes,
    double? coverage,
    String? schemaVersion,
    DateTime? analyzedAt,
  }) {
    return BookAnalysisData(
      bookId: bookId ?? this.bookId,
      scope: scope ?? this.scope,
      characters: characters ?? this.characters,
      storyEvents: storyEvents ?? this.storyEvents,
      locations: locations ?? this.locations,
      themes: themes ?? this.themes,
      coverage: coverage ?? this.coverage,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }
}

class CharacterCard {
  final String canonicalName;
  final Set<String> aliases;
  final String? role;
  final List<String> traits;
  final List<String> actions;
  final int firstChapter;
  final int lastChapter;
  final Set<int> activeChapters;
  final String? status;
  final List<SourceAnchor> anchors;
  final double confidence;

  CharacterCard({
    required this.canonicalName,
    Iterable<String> aliases = const {},
    this.role,
    Iterable<String> traits = const [],
    Iterable<String> actions = const [],
    required this.firstChapter,
    required this.lastChapter,
    Iterable<int> activeChapters = const {},
    this.status,
    Iterable<SourceAnchor> anchors = const [],
    this.confidence = 1.0,
  }) : aliases = Set.unmodifiable(aliases),
       traits = List.unmodifiable(traits),
       actions = List.unmodifiable(actions),
       activeChapters = Set.unmodifiable(activeChapters),
       anchors = List.unmodifiable(anchors);

  CharacterCard copyWith({
    String? canonicalName,
    Iterable<String>? aliases,
    String? role,
    Iterable<String>? traits,
    Iterable<String>? actions,
    int? firstChapter,
    int? lastChapter,
    Iterable<int>? activeChapters,
    String? status,
    Iterable<SourceAnchor>? anchors,
    double? confidence,
  }) {
    return CharacterCard(
      canonicalName: canonicalName ?? this.canonicalName,
      aliases: aliases ?? this.aliases,
      role: role ?? this.role,
      traits: traits ?? this.traits,
      actions: actions ?? this.actions,
      firstChapter: firstChapter ?? this.firstChapter,
      lastChapter: lastChapter ?? this.lastChapter,
      activeChapters: activeChapters ?? this.activeChapters,
      status: status ?? this.status,
      anchors: anchors ?? this.anchors,
      confidence: confidence ?? this.confidence,
    );
  }
}

class StoryEvent {
  final String description;
  final List<String> participants;
  final String? location;
  final int chapterIndex;
  final List<SourceAnchor> anchors;
  final double confidence;

  StoryEvent({
    required this.description,
    Iterable<String> participants = const [],
    this.location,
    required this.chapterIndex,
    Iterable<SourceAnchor> anchors = const [],
    this.confidence = 1.0,
  }) : participants = List.unmodifiable(participants),
       anchors = List.unmodifiable(anchors);

  StoryEvent copyWith({
    String? description,
    Iterable<String>? participants,
    String? location,
    int? chapterIndex,
    Iterable<SourceAnchor>? anchors,
    double? confidence,
  }) {
    return StoryEvent(
      description: description ?? this.description,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      anchors: anchors ?? this.anchors,
      confidence: confidence ?? this.confidence,
    );
  }
}

class LocationNode {
  final String name;
  final String? description;
  final Set<int> chapters;
  final List<SourceAnchor> anchors;
  final double confidence;

  LocationNode({
    required this.name,
    this.description,
    Iterable<int> chapters = const {},
    Iterable<SourceAnchor> anchors = const [],
    this.confidence = 1.0,
  }) : chapters = Set.unmodifiable(chapters),
       anchors = List.unmodifiable(anchors);

  LocationNode copyWith({
    String? name,
    String? description,
    Iterable<int>? chapters,
    Iterable<SourceAnchor>? anchors,
    double? confidence,
  }) {
    return LocationNode(
      name: name ?? this.name,
      description: description ?? this.description,
      chapters: chapters ?? this.chapters,
      anchors: anchors ?? this.anchors,
      confidence: confidence ?? this.confidence,
    );
  }
}

String _stableHash(String value) {
  const offsetBasis = 0x811c9dc5;
  const prime = 0x01000193;
  var hash = offsetBasis;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * prime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
