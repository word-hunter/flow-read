import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analyzedAt = DateTime.utc(2026, 6, 24, 9);
  final scope = AnalysisScope.readSoFar(
    bookId: 'book-1',
    currentChapterIndex: 2,
  );

  test('builds immutable book analysis data from chapter insights', () {
    final aggregator = BookAnalysisAggregator(
      characterRegistry: StaticBookAnalysisCharacterRegistry({
        'book-1': [
          CharacterRegistryEntry(
            canonicalName: 'Eddard Stark',
            aliases: const {'Ned'},
            updatedAt: DateTime.utc(2026, 6, 24),
          ),
        ],
      }),
      clock: () => analyzedAt,
    );

    final data = aggregator.build(
      scope: scope,
      totalChapters: 4,
      chapterInsights: {
        1: ChapterInsight.fromSummary(
          const AISummary(
            events: [
              SummaryEvent(
                description: 'Ned finds a direwolf near Winterfell.',
                source: 'The direwolf lay in the snow.',
                significance: 'This links the children to the north.',
                confidence: 'high',
              ),
            ],
            characterDevelopments: [
              CharacterDevelopment(
                character: 'Ned',
                change: 'Handles the discovery with caution.',
                source: 'Ned knelt beside the direwolf.',
                confidence: 'high',
              ),
            ],
            keyVocabulary: [],
            readingGuidance: '',
          ),
          locations: const [
            LocationRef(
              name: 'Winterfell',
              description: 'The northern home.',
              anchors: [
                SourceAnchor(
                  chapterIndex: 1,
                  quoteSnippet: 'near Winterfell',
                  confidence: 0.8,
                ),
              ],
              confidence: 0.8,
            ),
          ],
          themes: const ['family', 'duty'],
        ),
        2: ChapterInsight.fromSummary(
          const AISummary(
            events: [
              SummaryEvent(
                description: 'Eddard weighs the meaning of the omen.',
                source: 'Eddard stood silent.',
                significance: 'The omen begins to matter.',
                confidence: 'medium',
              ),
            ],
            characterDevelopments: [
              CharacterDevelopment(
                character: 'Eddard Stark',
                change: 'Treats the omen as politically serious.',
                source: 'Eddard stood silent.',
                confidence: 'medium',
              ),
            ],
            keyVocabulary: [],
            readingGuidance: '',
          ),
          locations: const [
            LocationRef(
              name: 'winterfell',
              description: 'Duplicate lower-case name.',
              anchors: [
                SourceAnchor(
                  chapterIndex: 2,
                  quoteSnippet: 'inside Winterfell',
                  confidence: 0.7,
                ),
              ],
              confidence: 0.7,
            ),
          ],
          themes: const ['Family', 'family'],
        ),
      },
    );

    expect(data.bookId, 'book-1');
    expect(data.scope, scope);
    expect(data.coverage, 0.5);
    expect(data.analyzedAt, analyzedAt);
    expect(data.schemaVersion, BookAnalysisAggregator.schemaVersion);

    expect(data.characters, hasLength(1));
    final character = data.characters.single;
    expect(character.canonicalName, 'Eddard Stark');
    expect(character.aliases, {'Ned'});
    expect(character.firstChapter, 1);
    expect(character.lastChapter, 2);
    expect(character.activeChapters, {1, 2});
    expect(character.traits, [
      'Handles the discovery with caution.',
      'Treats the omen as politically serious.',
    ]);
    expect(character.actions, character.traits);
    expect(character.anchors.map((anchor) => anchor.quoteSnippet), [
      'Ned knelt beside the direwolf.',
      'Eddard stood silent.',
    ]);

    expect(data.storyEvents.map((event) => event.description), [
      'Ned finds a direwolf near Winterfell.',
      'Eddard weighs the meaning of the omen.',
    ]);
    expect(data.storyEvents.first.confidence, 0.9);

    expect(data.locations, hasLength(1));
    expect(data.locations.single.name, 'Winterfell');
    expect(data.locations.single.chapters, {1, 2});
    expect(data.locations.single.anchors, hasLength(2));
    expect(data.locations.single.confidence, 0.7);

    expect(data.themes, ['family', 'duty']);
    expect(() => data.characters.add(character), throwsUnsupportedError);
    expect(() => character.aliases.add('Lord Stark'), throwsUnsupportedError);
  });

  test('session ignores duplicate chapter merges', () {
    final session = const BookAnalysisAggregator().start(
      bookId: 'book-1',
      totalChapters: 3,
    );
    final insight = ChapterInsight.fromSummary(
      const AISummary(
        events: [
          SummaryEvent(
            description: 'Alice opens the door.',
            source: 'opened the door',
            significance: 'The scene begins.',
            confidence: 'high',
          ),
        ],
        characterDevelopments: [],
        keyVocabulary: [],
        readingGuidance: '',
      ),
    );

    session
      ..mergeChapter(0, insight)
      ..mergeChapter(0, insight);
    final data = session.build(scope, analyzedAt: analyzedAt);

    expect(data.coverage, 1 / 3);
    expect(data.storyEvents, hasLength(1));
  });

  test('old empty summary cache is accepted as empty analysis input', () {
    final data = const BookAnalysisAggregator().build(
      scope: scope,
      totalChapters: 5,
      chapterInsights: {
        0: ChapterInsight.fromSummary(AISummary.empty()),
      },
    );

    expect(data.coverage, 0.2);
    expect(data.characters, isEmpty);
    expect(data.storyEvents, isEmpty);
    expect(data.locations, isEmpty);
    expect(data.themes, isEmpty);
  });

  test('sorts characters by first chapter and removes duplicate traits', () {
    final data = const BookAnalysisAggregator().build(
      scope: scope,
      totalChapters: 3,
      chapterInsights: {
        2: ChapterInsight.fromSummary(
          const AISummary(
            events: [],
            characterDevelopments: [
              CharacterDevelopment(
                character: 'Beta',
                change: 'Changes once.',
                source: 'Beta changed.',
                confidence: 'medium',
              ),
            ],
            keyVocabulary: [],
            readingGuidance: '',
          ),
        ),
        0: ChapterInsight.fromSummary(
          const AISummary(
            events: [],
            characterDevelopments: [
              CharacterDevelopment(
                character: 'Alpha',
                change: 'Appears first.',
                source: 'Alpha appeared.',
                confidence: 'high',
              ),
              CharacterDevelopment(
                character: 'Alpha',
                change: 'Appears first.',
                source: 'Alpha appeared.',
                confidence: 'high',
              ),
            ],
            keyVocabulary: [],
            readingGuidance: '',
          ),
        ),
      },
    );

    expect(data.characters.map((character) => character.canonicalName), [
      'Alpha',
      'Beta',
    ]);
    expect(data.characters.first.traits, ['Appears first.']);
    expect(data.characters.first.actions, ['Appears first.']);
    expect(data.characters.first.anchors, hasLength(1));
  });

  test('model copyWith preserves immutability', () {
    final card = CharacterCard(
      canonicalName: 'Alice',
      aliases: const {'A.'},
      traits: const ['curious'],
      actions: const ['opens a door'],
      firstChapter: 0,
      lastChapter: 0,
      activeChapters: const {0},
      anchors: const [
        SourceAnchor(
          chapterIndex: 0,
          quoteSnippet: 'Alice opened the door.',
        ),
      ],
    );
    final copied = card.copyWith(aliases: const {'Alice Liddell'});

    expect(card.aliases, {'A.'});
    expect(copied.aliases, {'Alice Liddell'});
    expect(() => copied.actions.add('mutate'), throwsUnsupportedError);
  });
}
