import 'package:flow_ai/flow_ai.dart';
import 'package:flow_read/widgets/mermaid_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders character relation graph as Mermaid flowchart', () {
    final graph = CharacterRelationGraph(
      nodes: [
        const GraphNode(id: 'alice', label: 'Alice'),
        const GraphNode(id: 'white rabbit', label: 'White "Rabbit"'),
      ],
      edges: [
        GraphEdge(
          fromCharacterId: 'alice',
          toCharacterId: 'white rabbit',
          relation: 'follows | questions',
        ),
      ],
    );

    expect(
      MermaidRenderer.toFlowchart(graph),
      [
        'flowchart TD',
        '  alice["Alice"]',
        r'  white_rabbit["White \"Rabbit\""]',
        '  alice -->|follows / questions| white_rabbit',
      ].join('\n'),
    );
  });

  test('renders mind map as Mermaid mindmap', () {
    const graph = MindMapGraph(
      root: MindMapNode(
        id: 'root',
        label: 'Wonderland',
        children: [
          MindMapNode(
            id: 'theme',
            label: 'Curiosity: doors',
            children: [
              MindMapNode(id: 'alice', label: 'Alice explores'),
            ],
          ),
        ],
      ),
    );

    expect(
      MermaidRenderer.toMindMap(graph),
      [
        'mindmap',
        '  Wonderland',
        '    Curiosity doors',
        '      Alice explores',
      ].join('\n'),
    );
  });

  testWidgets('renders synthesis visualization panes', (tester) async {
    final synthesis = BookSynthesisResult(
      fullStoryline: 'Alice follows the rabbit.',
      characterGraph: CharacterRelationGraph(
        nodes: const [
          GraphNode(id: 'alice', label: 'Alice'),
          GraphNode(id: 'rabbit', label: 'White Rabbit'),
        ],
        edges: [
          GraphEdge(
            fromCharacterId: 'alice',
            toCharacterId: 'rabbit',
            relation: 'follows',
          ),
        ],
      ),
      bookMindMap: const MindMapGraph(
        root: MindMapNode(
          id: 'root',
          label: 'Wonderland',
          children: [
            MindMapNode(id: 'theme', label: 'Curiosity'),
          ],
        ),
      ),
      structure: 'Opening movement.',
      themeAnalysis: 'Curiosity matters.',
      keyInsights: const ['Watch repeated doors.'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 420,
            child: BookSynthesisVisualization(synthesis: synthesis),
          ),
        ),
      ),
    );

    expect(find.text('概要'), findsOneWidget);
    expect(find.text('人物关系'), findsOneWidget);
    expect(find.text('思维导图'), findsOneWidget);
    expect(find.text('Alice follows the rabbit.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 320,
            child: CharacterRelationGraphView(graph: synthesis.characterGraph),
          ),
        ),
      ),
    );
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('White Rabbit'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 320,
            child: MindMapGraphView(graph: synthesis.bookMindMap),
          ),
        ),
      ),
    );
    expect(find.text('Wonderland'), findsOneWidget);
    expect(find.text('Curiosity'), findsOneWidget);
  });
}
