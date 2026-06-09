import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const supportedManifestFormatVersion = 1;
const manifestDataPath = 'data/app.json';
const maxBackupBookBytes = 500 * 1024 * 1024;

bool isZipFileHeader(Uint8List header) {
  if (header.length < 4) return false;
  return header[0] == 0x50 &&
      header[1] == 0x4B &&
      header[2] == 0x03 &&
      header[3] == 0x04;
}

String encodeBookId(String bookId) => Uri.encodeComponent(bookId);

String bookSourceEntryPath(String bookId) =>
    'books/${encodeBookId(bookId)}/source.epub';

String bookCoverEntryPath(String bookId) =>
    'books/${encodeBookId(bookId)}/cover.png';

void _assertValidEntryPath(String path) {
  if (path.isEmpty) throw const FormatException('entry path 不能为空');
  if (path.startsWith('/')) {
    throw const FormatException('entry path 不能是绝对路径');
  }
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.' || segment == '..') {
      throw FormatException('entry path 包含非法路径段: $path');
    }
  }
}

Map<String, dynamic> buildManifest({
  required String appId,
  required int formatVersion,
  required DateTime createdAt,
  required List<String> bookIds,
  required Map<String, bool> bookHasCover,
}) {
  final books = <String, Map<String, String>>{};
  for (final id in bookIds) {
    final entry = <String, String>{
      'source': bookSourceEntryPath(id),
    };
    if (bookHasCover[id] == true) {
      entry['cover'] = bookCoverEntryPath(id);
    }
    books[id] = entry;
  }

  return {
    'app': appId,
    'formatVersion': formatVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'dataPath': manifestDataPath,
    'books': books,
  };
}

void validateManifest(Map<String, dynamic> manifest, String expectedAppId) {
  final app = manifest['app'];
  if (app is! String || app != expectedAppId) {
    throw const FormatException('不是 Flow Read 备份文件');
  }
  final formatVersion = manifest['formatVersion'];
  if (formatVersion is! int) {
    throw const FormatException('备份格式无效');
  }
  if (formatVersion > supportedManifestFormatVersion) {
    throw const FormatException('备份版本过新，请升级 Flow Read 后再导入');
  }
  final dataPath = manifest['dataPath'];
  if (dataPath is! String || dataPath.isEmpty) {
    throw const FormatException('备份数据路径缺失');
  }
  _assertValidEntryPath(dataPath);
  final books = manifest['books'];
  if (books is! Map) {
    throw const FormatException('备份书籍索引缺失');
  }
  for (final entry in books.entries) {
    final bookEntry = entry.value;
    if (bookEntry is! Map) {
      throw FormatException('书籍 "${entry.key}" 索引格式无效');
    }
    final source = bookEntry['source'];
    if (source is! String || source.isEmpty) {
      throw FormatException('书籍 "${entry.key}" 缺少源文件路径');
    }
    _assertValidEntryPath(source);
    final cover = bookEntry['cover'];
    if (cover != null) {
      if (cover is! String || cover.isEmpty) {
        throw FormatException('书籍 "${entry.key}" 封面路径无效');
      }
      _assertValidEntryPath(cover);
    }
  }
}

Map<String, dynamic> buildDataPayload({
  required int schemaVersion,
  required Map<String, dynamic> boxes,
}) {
  return {
    'schemaVersion': schemaVersion,
    'boxes': boxes,
  };
}

void validateDataSchema(Map<String, dynamic> data, int currentSchemaVersion) {
  final schemaVersion = data['schemaVersion'];
  if (schemaVersion is! int) {
    throw const FormatException('备份数据格式无效');
  }
  if (schemaVersion < 1) {
    throw const FormatException('备份数据格式无效');
  }
  if (schemaVersion > currentSchemaVersion) {
    throw const FormatException('备份版本过新，请升级 Flow Read 后再导入');
  }
  final boxes = data['boxes'];
  if (boxes is! Map<String, dynamic>) {
    throw const FormatException('备份数据缺失');
  }
}

Set<String> manifestBookIds(Map<String, dynamic> manifest) {
  final books = manifest['books'];
  if (books is! Map) return const {};
  return books.keys.map((k) => k.toString()).toSet();
}

Uint8List encodeZipArchive(Map<String, dynamic> input) {
  final manifestJson = input['manifestJson'] as String;
  final dataJson = input['dataJson'] as String;
  final entries = input['entries'] as Map<String, dynamic>;

  final archive = Archive();

  void addEntry(String path, Uint8List bytes, bool compress) {
    final file = ArchiveFile.bytes(path, bytes);
    file.compression = compress ? CompressionType.deflate : CompressionType.none;
    if (compress) {
      file.compressionLevel = 6;
    }
    archive.addFile(file);
  }

  for (final entry in entries.entries) {
    final info = entry.value as Map<String, dynamic>;
    final bytes = info['bytes'] as Uint8List;
    final compress = info['compress'] as bool? ?? false;
    addEntry(entry.key, bytes, compress);
  }

  addEntry('manifest.json', utf8.encode(manifestJson), true);
  addEntry('data/app.json', utf8.encode(dataJson), true);

  return ZipEncoder().encodeBytes(archive);
}

Map<String, dynamic> decodeZipArchive(Uint8List zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);

  String? manifestJson;
  String? dataJson;
  final entryBytes = <String, Uint8List>{};

  for (final file in archive.files) {
    if (!file.isFile) continue;
    final content = file.content;
    if (file.name == 'manifest.json') {
      manifestJson = utf8.decode(content);
    } else if (file.name == 'data/app.json') {
      dataJson = utf8.decode(content);
    } else {
      entryBytes[file.name] = content;
    }
  }

  if (manifestJson == null) {
    throw const FormatException('备份文件缺少 manifest.json');
  }
  if (dataJson == null) {
    throw const FormatException('备份文件缺少 data/app.json');
  }

  return {
    'manifestJson': manifestJson,
    'dataJson': dataJson,
    'entryBytes': entryBytes,
  };
}
