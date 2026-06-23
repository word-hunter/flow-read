import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'chapter insight serializes summary and full-book analysis metadata',
    () {
      const anchor = SourceAnchor(
        chapterIndex: 3,
        chapterTitle: 'The Door',
        blockIndex: 2,
        startOffset: 15,
        endOffset: 42,
        quoteSnippet: 'Alice opened the little door.',
        confidence: 0.75,
      );
      const insight = ChapterInsight(
        summary: AISummary(
          events: [
            SummaryEvent(
              description: 'Alice opens the door.',
              source: 'opened the little door',
              significance: 'The scene moves forward.',
              confidence: 'high',
            ),
          ],
          characterDevelopments: [
            CharacterDevelopment(
              character: 'Alice',
              change: 'She becomes more curious.',
              source: 'curiouser and curiouser',
              confidence: 'medium',
            ),
          ],
          keyVocabulary: [],
          readingGuidance: 'Notice how action verbs move the scene.',
        ),
        locations: [
          LocationRef(
            name: 'Hallway',
            description: 'A strange hallway with doors.',
            anchors: [anchor],
            confidence: 0.8,
          ),
        ],
        themes: ['curiosity', 'threshold'],
        anchors: [anchor],
        schemaVersion: '1.0.0',
        contentHash: 'hash-1',
        promptVersion: 7,
      );

      final decoded = ChapterInsight.fromJson(insight.toJson());

      expect(
        decoded.summary.events.single.description,
        'Alice opens the door.',
      );
      expect(decoded.locations.single.name, 'Hallway');
      expect(decoded.locations.single.anchors.single.blockIndex, 2);
      expect(decoded.themes, ['curiosity', 'threshold']);
      expect(
        decoded.anchors.single.quoteSnippet,
        'Alice opened the little door.',
      );
      expect(decoded.schemaVersion, '1.0.0');
      expect(decoded.contentHash, 'hash-1');
      expect(decoded.promptVersion, 7);
    },
  );

  test('chapter insight reads legacy AISummary JSON as an empty extension', () {
    final legacySummaryJson = const AISummary(
      events: [
        SummaryEvent(
          description: 'The train arrives.',
          source: 'The train arrived',
          significance: 'It starts the journey.',
          confidence: 'high',
        ),
      ],
      characterDevelopments: [],
      keyVocabulary: [],
      readingGuidance: 'Track the setting change.',
    ).toJson();

    final insight = ChapterInsight.fromJson(legacySummaryJson);

    expect(insight.summary.events.single.description, 'The train arrives.');
    expect(insight.locations, isEmpty);
    expect(insight.themes, isEmpty);
    expect(insight.anchors, isEmpty);
    expect(insight.schemaVersion, ChapterInsight.currentSchemaVersion);
    expect(insight.contentHash, isEmpty);
    expect(insight.promptVersion, 0);
  });

  test(
    'chapter insight tolerates optional fields and alternate anchor keys',
    () {
      final insight = ChapterInsight.fromJson({
        'summary': AISummary.empty().toJson(),
        'schemaVersion': '1.0.0',
        'contentHash': 'hash-2',
        'promptVersion': '8',
        'locations': [
          {
            'name': 'Garden',
            'anchors': [
              {
                'chapter_index': 1,
                'paragraph_index': 4,
                'quote': 'under the hedge',
                'confidence': 1.4,
              },
            ],
          },
        ],
        'anchors': [
          {
            'chapter_index': 1,
            'quote': 'under the hedge',
            'confidence': -0.5,
          },
        ],
        'themes': [' movement ', '', 'return'],
      });

      expect(insight.schemaVersion, '1.0.0');
      expect(insight.contentHash, 'hash-2');
      expect(insight.promptVersion, 8);
      expect(insight.locations.single.anchors.single.blockIndex, 4);
      expect(insight.locations.single.anchors.single.confidence, 1.0);
      expect(insight.anchors.single.confidence, 0.0);
      expect(insight.themes, ['movement', 'return']);
    },
  );
}
