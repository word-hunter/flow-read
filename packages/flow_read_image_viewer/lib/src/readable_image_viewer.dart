import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_download_service.dart';
import 'readable_image_resource.dart';

Future<void> showReadableImageViewer(
  BuildContext context, {
  required ReadableImageResource resource,
  ReadableImageDownloadService? downloadService,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (_) => _ReadableImageViewerDialog(
      resource: resource,
      downloadService: downloadService ?? ReadableImageDownloadService(),
    ),
  );
}

class _ReadableImageViewerDialog extends StatefulWidget {
  final ReadableImageResource resource;
  final ReadableImageDownloadService downloadService;

  const _ReadableImageViewerDialog({
    required this.resource,
    required this.downloadService,
  });

  @override
  State<_ReadableImageViewerDialog> createState() =>
      _ReadableImageViewerDialogState();
}

class _ReadableImageViewerDialogState
    extends State<_ReadableImageViewerDialog> {
  static const double _minScale = 0.5;
  static const double _maxScale = 6;
  static const double _scaleStep = 0.35;
  static const double _mobileToolbarTopPadding = 12;
  static const double _desktopToolbarTopPadding = 36;

  final TransformationController _controller = TransformationController();
  double _scale = 1;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setScale(double value) {
    final next = value.clamp(_minScale, _maxScale).toDouble();
    setState(() => _scale = next);
    _controller.value = Matrix4.identity()..scaleByDouble(next, next, next, 1);
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final outcome = await widget.downloadService.save(widget.resource);
      if (!mounted || outcome.canceled) return;
      _showSnackBar('已保存图片');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: const EdgeInsets.all(160),
              onInteractionUpdate: (_) {
                final next = _controller.value.getMaxScaleOnAxis();
                if ((next - _scale).abs() > 0.02) {
                  setState(() => _scale = next);
                }
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ViewerImage(resource: widget.resource),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, _toolbarTopPadding, 12, 12),
                child: Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.close,
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _ToolbarButton(
                      icon: Icons.remove,
                      tooltip: '缩小',
                      onPressed: _scale <= _minScale
                          ? null
                          : () => _setScale(_scale - _scaleStep),
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.add,
                      tooltip: '放大',
                      onPressed: _scale >= _maxScale
                          ? null
                          : () => _setScale(_scale + _scaleStep),
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.center_focus_strong_outlined,
                      tooltip: '重置',
                      onPressed: () => _setScale(1),
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: _saving
                          ? Icons.downloading_outlined
                          : Icons.download_outlined,
                      tooltip: '下载图片',
                      onPressed: _saving ? null : _saveImage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _toolbarTopPadding {
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => _desktopToolbarTopPadding,
      _ => _mobileToolbarTopPadding,
    };
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        disabledColor: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

class _ViewerImage extends StatelessWidget {
  final ReadableImageResource resource;

  const _ViewerImage({required this.resource});

  @override
  Widget build(BuildContext context) {
    return switch (resource.type) {
      ReadableImageSourceType.memory => Image.memory(
        resource.bytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: resource.alt,
      ),
      ReadableImageSourceType.network => Image.network(
        resource.uri!.toString(),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: resource.alt,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 42,
        ),
      ),
    };
  }
}
