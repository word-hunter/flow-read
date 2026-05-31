import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'readable_image_resource.dart';

typedef ReadableImageBytesFetcher = Future<Uint8List> Function(Uri uri);
typedef ReadableImageBytesSaver =
    Future<String?> Function({
      required String fileName,
      required Uint8List bytes,
    });

class ReadableImageDownloadOutcome {
  final String? path;
  final bool canceled;

  const ReadableImageDownloadOutcome.saved(this.path) : canceled = false;

  const ReadableImageDownloadOutcome.canceled() : path = null, canceled = true;
}

class ReadableImageDownloadService {
  final ReadableImageBytesFetcher _fetchBytes;
  final ReadableImageBytesSaver _saveBytes;

  ReadableImageDownloadService({
    ReadableImageBytesFetcher? fetchBytes,
    ReadableImageBytesSaver? saveBytes,
  }) : _fetchBytes = fetchBytes ?? _defaultFetchBytes,
       _saveBytes = saveBytes ?? _defaultSaveBytes;

  Future<ReadableImageDownloadOutcome> save(
    ReadableImageResource resource,
  ) async {
    final bytes = switch (resource.type) {
      ReadableImageSourceType.memory => resource.bytes,
      ReadableImageSourceType.network => await _fetchBytes(resource.uri!),
    };
    if (bytes == null || bytes.isEmpty) {
      throw StateError('图片数据为空');
    }

    final fileName = suggestedImageFileName(resource, bytes);
    final path = await _saveBytes(fileName: fileName, bytes: bytes);
    if (path == null || path.trim().isEmpty) {
      return const ReadableImageDownloadOutcome.canceled();
    }
    return ReadableImageDownloadOutcome.saved(path);
  }

  static Future<Uint8List> _defaultFetchBytes(Uri uri) async {
    final response = await http
        .get(uri, headers: const {'User-Agent': 'FlowRead/1.0 Image Viewer'})
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('图片下载失败: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static Future<String?> _defaultSaveBytes({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FilePicker.saveFile(
      dialogTitle: '保存图片',
      fileName: fileName,
      bytes: bytes,
    );
  }
}

String suggestedImageFileName(ReadableImageResource resource, Uint8List bytes) {
  final explicit = resource.suggestedFileName;
  final fromSource = explicit == null || explicit.trim().isEmpty
      ? _fileNameFromSource(resource.displaySource)
      : explicit.trim();
  final base = _sanitizeFileName(
    fromSource == null || fromSource.isEmpty ? 'flow-read-image' : fromSource,
  );
  if (_hasImageExtension(base)) return base;

  return '$base${_extensionFromBytes(bytes) ?? '.png'}';
}

String? _fileNameFromSource(String source) {
  final uri = Uri.tryParse(source);
  final segment = uri?.pathSegments.where((part) => part.isNotEmpty).lastOrNull;
  if (segment != null && segment.trim().isNotEmpty) {
    return Uri.decodeComponent(segment.trim());
  }
  return null;
}

String _sanitizeFileName(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
    return 'flow-read-image';
  }
  return sanitized;
}

bool _hasImageExtension(String fileName) {
  final lower = fileName.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}

String? _extensionFromBytes(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return '.png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return '.jpg';
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    return '.gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return '.webp';
  }
  return null;
}
