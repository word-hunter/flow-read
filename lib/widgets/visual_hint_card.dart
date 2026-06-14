import 'package:flutter/material.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';

import '../services/external_url_launcher.dart';

class VisualHintCard extends StatelessWidget {
  final VisualDefinition definition;

  const VisualHintCard({super.key, required this.definition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 8),
        _buildContent(context, theme),
        const SizedBox(height: 6),
        _buildAttribution(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      '图像解释',
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    final url = definition.imageUrl ?? definition.thumbnailUrl;
    showReadableImageViewer(
      context,
      resource: ReadableImageResource.network(
        Uri.parse(url),
        alt: definition.label,
        suggestedFileName: '${definition.word}_${definition.entityId}.jpg',
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openImageViewer(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    maxWidth: 100,
                    minHeight: 80,
                  ),
                  child: Image.network(
                    definition.thumbnailUrl,
                    fit: BoxFit.cover,
                    headers: const {'User-Agent': 'FlowRead/1.0'},
                    errorBuilder: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      definition.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (definition.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        definition.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      definition.entityId,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttribution(ThemeData theme) {
    return _SourceLink(
      label: 'Wikidata · Wikimedia Commons',
      url: definition.sourcePageUrl,
    );
  }
}

class _SourceLink extends StatefulWidget {
  final String label;
  final String url;

  const _SourceLink({required this.label, required this.url});

  @override
  State<_SourceLink> createState() => _SourceLinkState();
}

class _SourceLinkState extends State<_SourceLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          try {
            await const ExternalUrlLauncher()
                .open(Uri.parse(widget.url));
          } on ExternalUrlOpenException {
            // silently ignore
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _hovered ? theme.colorScheme.primary : color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 11,
              color: _hovered ? theme.colorScheme.primary : color,
            ),
          ],
        ),
      ),
    );
  }
}

class VisualHintLoadingIndicator extends StatelessWidget {
  const VisualHintLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '加载图像解释…',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
