import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tool_env.dart';

const _defaultPort = 18731;
const _bundleIds = <String>[
  'com.example.flowRead.debug',
  'com.example.flowRead.profile',
  'com.example.flowRead',
];

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    _printUsage();
    return;
  }

  final latest = await _findLatestTrace();
  if (args.contains('--open-dir')) {
    final directory = latest?.parent ?? await _findFirstTraceDirectory();
    if (directory == null) {
      _fail('No AI debug trace directory found.');
    }
    await _open(directory.path);
    stdout.writeln('[FlowRead][AI Debug] trace dir: ${directory.path}');
    return;
  }

  if (args.contains('--open-latest')) {
    if (latest == null) {
      _fail('No AI debug trace file found.');
    }
    await _open(latest.path);
    stdout.writeln('[FlowRead][AI Debug] latest trace: ${latest.path}');
    return;
  }

  final port = _parsePort(args) ?? _defaultPort;
  final server = await _bindServer(port);
  final url = 'http://127.0.0.1:${server.port}/';

  stdout.writeln('[FlowRead][AI Debug] viewer: $url');
  if (latest == null) {
    stdout.writeln('[FlowRead][AI Debug] latest trace: not found');
  } else {
    stdout.writeln('[FlowRead][AI Debug] latest trace: ${latest.path}');
  }

  if (!args.contains('--no-open')) {
    await _open(url);
  }

  stdout.writeln('[FlowRead][AI Debug] press Ctrl+C to stop the viewer');
  await for (final request in server) {
    unawaited(_handleRequest(request));
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  try {
    final path = request.uri.path;
    if (path == '/' || path == '/index.html') {
      await _serveFile(
        request,
        File('${_toolDirectory().path}/ai_debug_viewer/index.html'),
        contentType: 'text/html; charset=utf-8',
      );
      return;
    }

    if (path == '/trace/latest.jsonl') {
      final latest = await _findLatestTrace();
      if (latest == null) {
        _writeJson(
          request,
          HttpStatus.notFound,
          {'error': 'No AI debug trace file found.'},
        );
        return;
      }
      await _serveFile(
        request,
        latest,
        contentType: 'application/x-ndjson; charset=utf-8',
      );
      return;
    }

    if (path == '/trace/info.json') {
      final latest = await _findLatestTrace();
      _writeJson(request, HttpStatus.ok, {
        'latestTrace': latest?.path,
        'traceDir':
            latest?.parent.path ?? (await _findFirstTraceDirectory())?.path,
      });
      return;
    }

    _writeJson(request, HttpStatus.notFound, {'error': 'Not found'});
  } catch (error, stackTrace) {
    stderr.writeln('[FlowRead][AI Debug] viewer error: $error\n$stackTrace');
    try {
      _writeJson(
        request,
        HttpStatus.internalServerError,
        {'error': error.toString()},
      );
    } catch (_) {
      await request.response.close();
    }
  }
}

Future<void> _serveFile(
  HttpRequest request,
  File file, {
  required String contentType,
}) async {
  if (!await file.exists()) {
    _writeJson(request, HttpStatus.notFound, {'error': 'File not found'});
    return;
  }
  request.response.statusCode = HttpStatus.ok;
  request.response.headers
    ..set(HttpHeaders.contentTypeHeader, contentType)
    ..set(HttpHeaders.cacheControlHeader, 'no-store');
  await request.response.addStream(file.openRead());
  await request.response.close();
}

void _writeJson(
  HttpRequest request,
  int statusCode,
  Map<String, Object?> payload,
) {
  request.response.statusCode = statusCode;
  request.response.headers
    ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
    ..set(HttpHeaders.cacheControlHeader, 'no-store');
  request.response.write(jsonEncode(payload));
  unawaited(request.response.close());
}

Future<HttpServer> _bindServer(int preferredPort) async {
  for (var offset = 0; offset < 20; offset += 1) {
    final port = preferredPort + offset;
    try {
      return await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      continue;
    }
  }
  return HttpServer.bind(InternetAddress.loopbackIPv4, 0);
}

Future<File?> _findLatestTrace() async {
  final files = <File>[];
  for (final directory in await _traceDirectories()) {
    if (!await directory.exists()) continue;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('flow_read_ai_trace-') && name.endsWith('.jsonl')) {
        files.add(entity);
      }
    }
  }
  if (files.isEmpty) return null;

  files.sort((a, b) {
    final modifiedA = a.lastModifiedSync();
    final modifiedB = b.lastModifiedSync();
    return modifiedB.compareTo(modifiedA);
  });
  return files.first;
}

Future<Directory?> _findFirstTraceDirectory() async {
  for (final directory in await _traceDirectories()) {
    if (await directory.exists()) return directory;
  }
  return null;
}

Future<List<Directory>> _traceDirectories() async {
  final home = Platform.environment['HOME'];

  final directories = <Directory>[];
  final env = await loadToolEnv();
  final mirrorDir = env['FLOW_AI_DEBUG_TRACE_MIRROR_DIR']?.trim();
  if (mirrorDir != null && mirrorDir.isNotEmpty) {
    directories.add(Directory(mirrorDir));
  }

  if (home == null || home.isEmpty) {
    return directories;
  }

  if (Platform.isMacOS) {
    for (final bundleId in _bundleIds) {
      directories.add(
        Directory(
          '$home/Library/Containers/$bundleId/Data/Library/Application Support/'
          '$bundleId/ai_debug',
        ),
      );
    }
    final containers = Directory('$home/Library/Containers');
    if (await containers.exists()) {
      await for (final entity in containers.list()) {
        if (entity is! Directory) continue;
        final segments = entity.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .toList(growable: false);
        final bundleId = segments.isEmpty ? null : segments.last;
        if (bundleId == null || !bundleId.startsWith('com.example.flowRead')) {
          continue;
        }
        directories.add(
          Directory(
            '${entity.path}/Data/Library/Application Support/$bundleId/'
            'ai_debug',
          ),
        );
      }
    }
  }

  directories.add(
    Directory('$home/Library/Application Support/flow_read/ai_debug'),
  );
  directories.add(
    Directory('$home/.local/share/flow_read/ai_debug'),
  );

  final seen = <String>{};
  return [
    for (final directory in directories)
      if (seen.add(directory.path)) directory,
  ];
}

Directory _toolDirectory() {
  final script = File.fromUri(Platform.script);
  return script.parent;
}

int? _parsePort(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      return int.tryParse(arg.substring('--port='.length));
    }
  }
  return null;
}

Future<void> _open(String target) async {
  if (Platform.isMacOS) {
    await Process.start('open', [target]);
    return;
  }
  stdout.writeln(target);
}

Never _fail(String message) {
  stderr.writeln('[FlowRead][AI Debug] $message');
  exit(1);
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tool/ai_debug_viewer.dart [options]

Options:
  --no-open       Start the local viewer server without opening a browser.
  --open-dir      Open the latest trace directory in Finder.
  --open-latest   Open the latest trace JSONL file.
  --port=<port>   Preferred local viewer port. Defaults to $_defaultPort.
''');
}
