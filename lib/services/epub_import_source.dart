import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

abstract class EpubImportSource {
  const EpubImportSource({required this.fileName});

  final String fileName;

  factory EpubImportSource.path(String path, {String? fileName}) {
    return _PathEpubImportSource(
      path: path,
      fileName: _effectiveFileName(fileName ?? _fileNameFromPath(path)),
    );
  }

  factory EpubImportSource.bytes(Uint8List bytes, {required String fileName}) {
    return _BytesEpubImportSource(
      bytes: bytes,
      fileName: _effectiveFileName(fileName),
    );
  }

  factory EpubImportSource.stream(
    Stream<List<int>> stream, {
    required String fileName,
  }) {
    return _StreamEpubImportSource(
      stream: stream,
      fileName: _effectiveFileName(fileName),
    );
  }

  static EpubImportSource? tryFromPlatformFile(PlatformFile file) {
    final readStream = file.readStream;
    if (readStream != null) {
      return EpubImportSource.stream(readStream, fileName: file.name);
    }

    final bytes = file.bytes;
    if (bytes != null) {
      return EpubImportSource.bytes(bytes, fileName: file.name);
    }

    final path = file.path?.trim();
    if (path != null && path.isNotEmpty) {
      return EpubImportSource.path(path, fileName: file.name);
    }

    return null;
  }

  Future<void> writeTo(String targetPath);
}

class _PathEpubImportSource extends EpubImportSource {
  const _PathEpubImportSource({required this.path, required super.fileName});

  final String path;

  @override
  Future<void> writeTo(String targetPath) async {
    await File(path).copy(targetPath);
  }
}

class _BytesEpubImportSource extends EpubImportSource {
  const _BytesEpubImportSource({required this.bytes, required super.fileName});

  final Uint8List bytes;

  @override
  Future<void> writeTo(String targetPath) async {
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }
}

class _StreamEpubImportSource extends EpubImportSource {
  const _StreamEpubImportSource({
    required this.stream,
    required super.fileName,
  });

  final Stream<List<int>> stream;

  @override
  Future<void> writeTo(String targetPath) async {
    final sink = File(targetPath).openWrite();
    try {
      await sink.addStream(stream);
    } finally {
      await sink.close();
    }
  }
}

String _fileNameFromPath(String path) {
  final segments = File(path).uri.pathSegments;
  if (segments.isEmpty) return path;
  return segments.last;
}

String _effectiveFileName(String fileName) {
  final trimmed = fileName.trim();
  return trimmed.isEmpty ? 'book.epub' : trimmed;
}
