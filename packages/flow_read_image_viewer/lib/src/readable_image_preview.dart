import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'readable_image_resource.dart';
import 'readable_image_viewer.dart';

class ReadableImagePreview extends StatelessWidget {
  static const double _fallbackAspectRatio = 4 / 3;

  final ReadableImageResource resource;
  final double? width;
  final double? height;
  final double maxHeight;
  final double maxWidth;
  final Alignment alignment;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const ReadableImagePreview({
    super.key,
    required this.resource,
    this.width,
    this.height,
    this.maxHeight = 520,
    this.maxWidth = double.infinity,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            width ??
            (constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : maxWidth.isFinite
                ? maxWidth
                : 720.0);
        final aspectRatio = resource.aspectRatio ?? _fallbackAspectRatio;
        final constrainedWidth = math.min(
          availableWidth,
          maxWidth.isFinite ? maxWidth : availableWidth,
        );
        final naturalHeight = height ?? constrainedWidth / aspectRatio;
        final resolvedHeight = math.min(maxHeight, naturalHeight);
        final resolvedWidth = height == null && naturalHeight > maxHeight
            ? math.min(constrainedWidth, resolvedHeight * aspectRatio)
            : constrainedWidth;

        return Tooltip(
          message: '查看图片',
          child: Semantics(
            button: true,
            image: true,
            label: resource.alt == null || resource.alt!.trim().isEmpty
                ? '查看图片'
                : '查看图片，${resource.alt}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    showReadableImageViewer(context, resource: resource),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: SizedBox(
                    width: resolvedWidth,
                    height: resolvedHeight,
                    child: _ReadableImage(
                      resource: resource,
                      fit: fit,
                      alignment: alignment,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReadableImage extends StatelessWidget {
  final ReadableImageResource resource;
  final BoxFit fit;
  final Alignment alignment;

  const _ReadableImage({
    required this.resource,
    required this.fit,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return switch (resource.type) {
      ReadableImageSourceType.memory => Image.memory(
        resource.bytes!,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        semanticLabel: resource.alt,
        errorBuilder: (_, _, _) => const _ImageErrorPlaceholder(),
      ),
      ReadableImageSourceType.network => Image.network(
        resource.uri!.toString(),
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        semanticLabel: resource.alt,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) => const _ImageErrorPlaceholder(),
      ),
    };
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
