import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/reading_provider.dart';

class EpubDropImporter extends StatefulWidget {
  const EpubDropImporter({super.key, required this.child});

  final Widget child;

  @override
  State<EpubDropImporter> createState() => _EpubDropImporterState();
}

class _EpubDropImporterState extends State<EpubDropImporter> {
  static const MethodChannel _channel = MethodChannel('flow_read/file_drop');

  bool _dragActive = false;
  bool _importingDroppedFiles = false;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleDropMethodCall);
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleDropMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'dragEntered':
        _setDragActive(true);
        return;
      case 'dragExited':
        _setDragActive(false);
        return;
      case 'filesDropped':
        _setDragActive(false);
        await _importDroppedPaths(_pathsFromArguments(call.arguments));
        return;
    }
  }

  List<String> _pathsFromArguments(Object? arguments) {
    if (arguments is! List) return const [];
    return arguments.whereType<String>().toList(growable: false);
  }

  void _setDragActive(bool value) {
    if (!mounted || _dragActive == value) return;
    setState(() => _dragActive = value);
  }

  Future<void> _importDroppedPaths(List<String> paths) async {
    if (!mounted) return;

    final epubPaths = paths
        .where((path) => path.toLowerCase().endsWith('.epub'))
        .toList(growable: false);

    if (epubPaths.isEmpty) {
      _showSnackBar('请拖入 EPUB 文件');
      return;
    }

    final provider = context.read<ReadingProvider>();
    if (provider.isLoading || _importingDroppedFiles) {
      _showSnackBar('正在导入 EPUB，请稍后再试');
      return;
    }

    setState(() => _importingDroppedFiles = true);
    try {
      for (final path in epubPaths) {
        await provider.importBook(path);
        if (!mounted) return;
        if (provider.errorMessage != null) {
          _showSnackBar(_importErrorMessage(provider.errorMessage!));
          return;
        }
      }

      final message = epubPaths.length == 1
          ? 'EPUB 已导入'
          : '已导入 ${epubPaths.length} 本 EPUB';
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _importingDroppedFiles = false);
      }
    }
  }

  String _importErrorMessage(String message) {
    const prefix = 'Failed to import book: ';
    if (message.startsWith(prefix)) {
      return '导入失败：${message.substring(prefix.length)}';
    }
    return message;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _dragActive ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.scrim.withValues(alpha: 0.42),
              ),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '释放以导入 EPUB',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
