import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('book synthesis result parses structured graph and mind map data', () {
    final result = BookSynthesisResult.fromJson({
      'fullStoryline': 'Alice enters a strange world.',
      'characterGraph': {
        'nodes': [
          {'id': 'alice', 'label': 'Alice', 'role': 'protagonist'},
          {'id': 'rabbit', 'label': 'White Rabbit'},
        ],
        'edges': [
          {
            'from': 'alice',
            'to': 'rabbit',
            'relation': 'follows',
            'confidence': 0.8,
            'anchors': [
              {
                'chapter_index': 0,
                'quote_snippet': 'Alice started to her feet',
                'confidence': 0.7,
              },
            ],
          },
        ],
      },
      'bookMindMap': {
        'root': {
          'label': 'Wonderland',
          'children': [
            {'label': 'Characters'},
          ],
        },
      },
      'structure': 'Opening and descent.',
      'themeAnalysis': 'Curiosity drives the plot.',
      'keyInsights': ['Notice scale changes.'],
      'schema_version': '1.0.0',
      'generated_at': '2026-06-24T10:00:00Z',
    });

    expect(result.fullStoryline, contains('Alice'));
    expect(result.characterGraph.nodes, hasLength(2));
    expect(result.characterGraph.edges.single.fromCharacterId, 'alice');
    expect(result.characterGraph.edges.single.anchors.single.chapterIndex, 0);
    expect(result.bookMindMap.root.id, 'wonderland');
    expect(result.bookMindMap.root.children.single.label, 'Characters');
    expect(result.keyInsights, ['Notice scale changes.']);

    final restored = BookSynthesisResult.fromJson(result.toJson());
    expect(restored.fullStoryline, result.fullStoryline);
    expect(restored.characterGraph.edges.single.relation, 'follows');
  });

  test('book synthesis result tolerates optional missing graph fields', () {
    final result = BookSynthesisResult.fromJson({
      'fullStoryline': 'Only a storyline was returned.',
    });

    expect(result.characterGraph.nodes, isEmpty);
    expect(result.characterGraph.edges, isEmpty);
    expect(result.bookMindMap.root.label, 'Analysis');
    expect(result.keyInsights, isEmpty);
  });

  test('book synthesis result requires a non-empty storyline', () {
    expect(
      () => BookSynthesisResult.fromJson({'fullStoryline': 42}),
      throwsA(isA<FormatException>()),
    );
  });
}
