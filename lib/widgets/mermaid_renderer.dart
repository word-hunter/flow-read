import 'dart:math' as math;

import 'package:flow_ai/flow_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MermaidRenderer {
  const MermaidRenderer._();

  static String toFlowchart(CharacterRelationGraph graph) {
    final nodeById = {
      for (final node in graph.nodes)
        if (node.id.trim().isNotEmpty) node.id.trim(): node,
    };
    final orderedRawIds = <String>[];
    void addId(String id) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) return;
      if (orderedRawIds.any(
        (value) => value.toLowerCase() == trimmed.toLowerCase(),
      )) {
        return;
      }
      orderedRawIds.add(trimmed);
    }

    for (final node in graph.nodes) {
      addId(node.id);
    }
    for (final edge in graph.edges) {
      addId(edge.fromCharacterId);
      addId(edge.toCharacterId);
    }

    final idMap = _stableMermaidIds(orderedRawIds);
    final buffer = StringBuffer('flowchart TD\n');
    if (orderedRawIds.isEmpty) {
      buffer.writeln('  empty["No character relations"]');
      return buffer.toString().trimRight();
    }

    for (final rawId in orderedRawIds) {
      final node = nodeById[rawId];
      final label = node?.label.trim().isNotEmpty == true ? node!.label : rawId;
      buffer.writeln('  ${idMap[rawId]}["${_escapeFlowchartLabel(label)}"]');
    }
    for (final edge in graph.edges) {
      final from = idMap[edge.fromCharacterId.trim()];
      final to = idMap[edge.toCharacterId.trim()];
      if (from == null || to == null) continue;
      final relation = edge.relation.trim();
      if (relation.isEmpty) {
        buffer.writeln('  $from --> $to');
      } else {
        buffer.writeln('  $from -->|${_escapeEdgeLabel(relation)}| $to');
      }
    }
    return buffer.toString().trimRight();
  }

  static String toMindMap(MindMapGraph graph) {
    final buffer = StringBuffer('mindmap\n');
    _writeMindMapNode(buffer, graph.root, 1);
    return buffer.toString().trimRight();
  }

  static Map<String, String> _stableMermaidIds(List<String> rawIds) {
    final result = <String, String>{};
    final used = <String>{};
    for (final rawId in rawIds) {
      final base = _sanitizeIdentifier(rawId);
      var candidate = base;
      var suffix = 2;
      while (!used.add(candidate.toLowerCase())) {
        candidate = '${base}_$suffix';
        suffix += 1;
      }
      result[rawId] = candidate;
    }
    return result;
  }

  static String _sanitizeIdentifier(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) return 'node';
    if (RegExp(r'^[0-9]').hasMatch(sanitized)) return 'n_$sanitized';
    return sanitized;
  }

  static void _writeMindMapNode(
    StringBuffer buffer,
    MindMapNode node,
    int depth,
  ) {
    final indent = '  ' * depth;
    final label = _escapeMindMapLabel(
      node.label.trim().isEmpty ? node.id : node.label,
    );
    buffer.writeln('$indent$label');
    for (final child in node.children) {
      _writeMindMapNode(buffer, child, depth + 1);
    }
  }

  static String _escapeFlowchartLabel(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _escapeEdgeLabel(String value) {
    return value.replaceAll('|', '/').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _escapeMindMapLabel(String value) {
    return value
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'[:{}\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class BookSynthesisVisualization extends StatelessWidget {
  const BookSynthesisVisualization({
    super.key,
    required this.synthesis,
  });

  final BookSynthesisResult synthesis;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(text: '概要'),
              Tab(text: '人物关系'),
              Tab(text: '思维导图'),
              Tab(text: '主题'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 340,
            child: TabBarView(
              children: [
                _OverviewPane(synthesis: synthesis),
                CharacterRelationGraphView(graph: synthesis.characterGraph),
                MindMapGraphView(graph: synthesis.bookMindMap),
                _ThemePane(synthesis: synthesis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterRelationGraphView extends StatelessWidget {
  const CharacterRelationGraphView({
    super.key,
    required this.graph,
  });

  final CharacterRelationGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mermaid = MermaidRenderer.toFlowchart(graph);
    if (graph.nodes.isEmpty && graph.edges.isEmpty) {
      return _VisualizationShell(
        title: '人物关系',
        mermaid: mermaid,
        child: _InlineEmpty(message: '暂无人物关系图数据'),
      );
    }

    return _VisualizationShell(
      title: '人物关系',
      mermaid: mermaid,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CharacterGraphCanvas(graph: graph),
            if (graph.edges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '关系',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...graph.edges.take(8).map((edge) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${edge.fromCharacterId} → ${edge.toCharacterId}'
                    '${edge.relation.trim().isEmpty ? '' : ' · ${edge.relation}'}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class MindMapGraphView extends StatelessWidget {
  const MindMapGraphView({
    super.key,
    required this.graph,
  });

  final MindMapGraph graph;

  @override
  Widget build(BuildContext context) {
    final mermaid = MermaidRenderer.toMindMap(graph);
    return _VisualizationShell(
      title: '思维导图',
      mermaid: mermaid,
      child: graph.root.label.trim().isEmpty && graph.root.children.isEmpty
          ? _InlineEmpty(message: '暂无思维导图数据')
          : SingleChildScrollView(
              child: _MindMapTree(node: graph.root),
            ),
    );
  }
}

class _VisualizationShell extends StatelessWidget {
  const _VisualizationShell({
    required this.title,
    required this.mermaid,
    required this.child,
  });

  final String title;
  final String mermaid;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '复制 Mermaid',
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mermaid));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已复制 Mermaid'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CharacterGraphCanvas extends StatelessWidget {
  const _CharacterGraphCanvas({required this.graph});

  final CharacterRelationGraph graph;

  @override
  Widget build(BuildContext context) {
    final visibleNodes = _visibleNodes(graph).take(12).toList(growable: false);
    if (visibleNodes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, 420.0);
        const height = 230.0;
        final positions = _nodePositions(visibleNodes, Size(width, height));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CharacterGraphPainter(
                      graph: graph,
                      positions: positions,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
                for (final node in visibleNodes)
                  Positioned(
                    left: positions[node.id]!.dx - 52,
                    top: positions[node.id]!.dy - 22,
                    width: 104,
                    height: 44,
                    child: _GraphNodeChip(node: node),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static List<GraphNode> _visibleNodes(CharacterRelationGraph graph) {
    if (graph.nodes.isNotEmpty) return graph.nodes;
    final ids = <String>[];
    void add(String id) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) return;
      if (ids.any((value) => value.toLowerCase() == trimmed.toLowerCase())) {
        return;
      }
      ids.add(trimmed);
    }

    for (final edge in graph.edges) {
      add(edge.fromCharacterId);
      add(edge.toCharacterId);
    }
    return ids
        .map((id) => GraphNode(id: id, label: id))
        .toList(growable: false);
  }

  static Map<String, Offset> _nodePositions(List<GraphNode> nodes, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = math.max(90.0, size.width / 2 - 78);
    final radiusY = math.max(58.0, size.height / 2 - 56);
    final positions = <String, Offset>{};
    for (var i = 0; i < nodes.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / nodes.length);
      positions[nodes[i].id] = Offset(
        center.dx + math.cos(angle) * radiusX,
        center.dy + math.sin(angle) * radiusY,
      );
    }
    return positions;
  }
}

class _GraphNodeChip extends StatelessWidget {
  const _GraphNodeChip({required this.node});

  final GraphNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = node.label.trim().isEmpty ? node.id : node.label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterGraphPainter extends CustomPainter {
  const _CharacterGraphPainter({
    required this.graph,
    required this.positions,
    required this.colorScheme,
  });

  final CharacterRelationGraph graph;
  final Map<String, Offset> positions;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in graph.edges) {
      final from = positions[edge.fromCharacterId];
      final to = positions[edge.toCharacterId];
      if (from == null || to == null) continue;
      final direction = to - from;
      if (direction.distance == 0) continue;
      final unit = direction / direction.distance;
      final start = from + unit * 54;
      final end = to - unit * 54;
      canvas.drawLine(start, end, paint);

      final left = Offset(-unit.dy, unit.dx);
      final arrowA = end - unit * 9 + left * 5;
      final arrowB = end - unit * 9 - left * 5;
      canvas
        ..drawLine(end, arrowA, arrowPaint)
        ..drawLine(end, arrowB, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CharacterGraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.positions != positions ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _MindMapTree extends StatelessWidget {
  const _MindMapTree({
    required this.node,
    this.depth = 0,
  });

  final MindMapNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;
    return Padding(
      padding: EdgeInsets.only(left: isRoot ? 0 : 14, bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isRoot
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: isRoot ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRoot ? Icons.account_tree_outlined : Icons.circle,
                    size: isRoot ? 18 : 7,
                    color: isRoot
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.label.trim().isEmpty ? node.id : node.label,
                      style:
                          (isRoot
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.bodySmall)
                              ?.copyWith(
                                fontWeight: isRoot
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                    ),
                  ),
                ],
              ),
              if (node.children.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final child in node.children)
                  _MindMapTree(node: child, depth: depth + 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({required this.synthesis});

  final BookSynthesisResult synthesis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(synthesis.fullStoryline, style: theme.textTheme.bodyMedium),
          if (synthesis.keyInsights.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: synthesis.keyInsights
                  .map(
                    (insight) => Chip(
                      label: Text(insight),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemePane extends StatelessWidget {
  const _ThemePane({required this.synthesis});

  final BookSynthesisResult synthesis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = [
      if (synthesis.structure.trim().isNotEmpty)
        ('结构', synthesis.structure.trim()),
      if (synthesis.themeAnalysis.trim().isNotEmpty)
        ('主题', synthesis.themeAnalysis.trim()),
      if (synthesis.keyInsights.isNotEmpty)
        ('洞察', synthesis.keyInsights.join('\n')),
    ];
    if (sections.isEmpty) {
      return const _InlineEmpty(message: '暂无主题分析数据');
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (title, body) in sections) ...[
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
