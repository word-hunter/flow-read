import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:epub_reader_core/epub_reader_core.dart' as core;

import '../models/book.dart';
import 'epub_service.dart';

class EpubParseCancelledException implements Exception {
  const EpubParseCancelledException();

  @override
  String toString() => 'EPUB parse cancelled';
}

class EpubParseTask {
  EpubParseTask._();

  final Completer<Book> _completer = Completer<Book>();
  final List<ReceivePort> _ports = [];

  Isolate? _isolate;
  bool _isCancelled = false;

  Future<Book> get future => _completer.future;
  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_completer.isCompleted) return;
    _isCancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _completeError(const EpubParseCancelledException());
  }

  Future<void> _startFile(
    String filePath, {
    core.EpubParseProgressCallback? onProgress,
  }) async {
    final resultPort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final progressPort = onProgress == null ? null : ReceivePort();
    _ports.addAll([resultPort, errorPort, exitPort]);
    if (progressPort != null) {
      _ports.add(progressPort);
    }

    resultPort.listen((message) {
      if (message is Book) {
        _complete(message);
      } else {
        _completeError(StateError('EPUB parse isolate returned no book.'));
      }
    });
    errorPort.listen((message) {
      if (_isCancelled) return;
      if (message is List && message.isNotEmpty) {
        _completeError(
          RemoteError(
            message.first.toString(),
            message.length > 1 ? message[1].toString() : '',
          ),
        );
        return;
      }
      _completeError(StateError('EPUB parse isolate failed: $message'));
    });
    progressPort?.listen((message) {
      if (_isCancelled || _completer.isCompleted) return;
      if (message is core.EpubParseEvent) {
        onProgress?.call(message);
      }
    });
    exitPort.listen((_) {
      if (_isCancelled || _completer.isCompleted) return;
      _completeError(
        StateError('EPUB parse isolate exited before returning a book.'),
      );
    });

    try {
      _isolate = await Isolate.spawn(
        _parseFileEntry,
        _EpubParseFileRequest(
          filePath,
          resultPort.sendPort,
          progressPort?.sendPort,
        ),
        errorsAreFatal: true,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
    } catch (error, stackTrace) {
      _completeError(error, stackTrace);
    }
  }

  void _complete(Book book) {
    if (_completer.isCompleted) return;
    _dispose();
    _completer.complete(book);
  }

  void _completeError(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return;
    _dispose();
    _completer.completeError(error, stackTrace);
  }

  void _dispose() {
    for (final port in _ports) {
      port.close();
    }
    _ports.clear();
    _isolate = null;
  }
}

class EpubParseWorker {
  const EpubParseWorker._();

  static Future<EpubParseTask> startParseInIsolate(
    String filePath, {
    core.EpubParseProgressCallback? onProgress,
  }) async {
    final task = EpubParseTask._();
    await task._startFile(filePath, onProgress: onProgress);
    return task;
  }

  static Future<Book> parseInIsolate(
    String filePath, {
    core.EpubParseProgressCallback? onProgress,
  }) async {
    final task = await startParseInIsolate(filePath, onProgress: onProgress);
    return task.future;
  }

  static ({Stream<core.EpubParseEvent> progress, Future<Book> result})
  parseWithProgress(String filePath) {
    final controller = StreamController<core.EpubParseEvent>.broadcast();
    final result = parseInIsolate(
      filePath,
      onProgress: controller.add,
    ).whenComplete(controller.close);
    return (progress: controller.stream, result: result);
  }

  static Future<Book> parseBytesInIsolate(Uint8List bytes) {
    return Isolate.run(() => EpubService.parseBytesSync(bytes));
  }
}

class _EpubParseFileRequest {
  const _EpubParseFileRequest(this.filePath, this.replyTo, this.progressPort);

  final String filePath;
  final SendPort replyTo;
  final SendPort? progressPort;
}

void _parseFileEntry(_EpubParseFileRequest request) {
  request.replyTo.send(
    _parseFileInBackground(
      request.filePath,
      progressPort: request.progressPort,
    ),
  );
}

Book _parseFileInBackground(String filePath, {SendPort? progressPort}) {
  final bytes = File(filePath).readAsBytesSync();
  return EpubService.parseBytesSync(
    bytes,
    onProgress: progressPort == null
        ? null
        : (event) => progressPort.send(event),
  );
}
