import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/services/app_logger.dart';
import 'package:flow_read/services/diagnostic_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late Directory logDir;
  late Directory exportDir;
  late DateTime now;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'flow_read_diagnostic_export_test_',
    );
    logDir = Directory('${tempDir.path}/logs');
    exportDir = Directory('${tempDir.path}/exports');
    now = DateTime.utc(2026, 6, 2, 8, 30);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exports sanitized app info and logs into a zip archive', () async {
    final logger = AppLogger(
      logDirectoryProvider: () async => logDir,
      includeDebugProvider: () => true,
      clock: () => now,
    );
    logger.event(
      'diagnostic.sample',
      level: AppLogLevel.warning,
      source: 'diagnostic_test',
      metadata: {
        'apiKey': 'sk-secret-value',
        'localPath': '/Users/example/private/book.epub',
      },
      error: StateError('private failure'),
    );
    await logger.drain();

    final service = DiagnosticExportService(
      logger: logger,
      tempDirectoryProvider: () async => exportDir,
      clock: () => now,
    );

    final path = await service.export();
    final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    final names = archive.files.map((file) => file.name).toSet();

    expect(names, contains('app_info.json'));
    expect(names, contains('logs/flow_read-2026-06-02.log'));
    expect(path, endsWith('.zip'));

    final appInfo =
        jsonDecode(utf8.decode(_bytesFor(archive.findFile('app_info.json')!)))
            as Map<String, dynamic>;
    expect(appInfo['exportType'], 'diagnostic');
    expect(appInfo['appName'], 'Flow Read');

    final appInfoJson = jsonEncode(appInfo);
    expect(appInfoJson, isNot(contains('apiKey')));
    expect(appInfoJson, isNot(contains('/Users/')));
    expect(appInfoJson, isNot(contains('bookmark')));

    final logText = utf8.decode(
      _bytesFor(archive.findFile('logs/flow_read-2026-06-02.log')!),
    );
    expect(logText, contains('<redacted>'));
    expect(logText, contains('<local_path>'));
    expect(logText, isNot(contains('sk-secret-value')));
    expect(logText, isNot(contains('/Users/example')));
  });
}

Uint8List _bytesFor(ArchiveFile file) {
  return file.content;
}
