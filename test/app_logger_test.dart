import 'dart:convert';
import 'dart:io';

import 'package:flow_read/services/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late DateTime now;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_logs_test_');
    now = DateTime(2026, 5, 24, 12, 30);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  AppLogger createLogger({bool includeDebug = true}) {
    return AppLogger(
      logDirectoryProvider: () async => tempDir,
      includeDebugProvider: () => includeDebug,
      clock: () => now,
    );
  }

  Future<List<Map<String, dynamic>>> readEntries() async {
    final file = File('${tempDir.path}/flow_read-2026-05-24.log');
    final lines = await file.readAsLines();
    return lines
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  test('writes structured JSONL entries by level', () async {
    final logger = createLogger();

    logger.event(
      'rss.fetch_failed',
      level: AppLogLevel.warning,
      source: 'rss_service',
      metadata: {'usedCache': false, 'statusCode': 500},
      error: StateError('network unavailable'),
      stackTrace: StackTrace.fromString(
        '#0 fetch (package:flow_read/a.dart:1)',
      ),
    );
    await logger.drain();

    final entries = await readEntries();
    expect(entries, hasLength(1));
    expect(entries.single['level'], 'warning');
    expect(entries.single['source'], 'rss_service');
    expect(entries.single['event'], 'rss.fetch_failed');
    expect(entries.single['message'], 'Captured StateError');
    expect(entries.single['errorType'], 'StateError');
    expect(entries.single['error'], '<redacted_error_message>');
    expect(entries.single['metadata'], {'usedCache': false, 'statusCode': 500});
    expect(entries.single['stackTrace'], contains('package:flow_read/a.dart'));
  });

  test('skips debug entries when debug logging is disabled', () async {
    final logger = createLogger(includeDebug: false);

    logger.event(
      'ai.validation_source_missing',
      level: AppLogLevel.debug,
      source: 'ai_service',
    );
    await logger.drain();

    final file = File('${tempDir.path}/flow_read-2026-05-24.log');
    expect(await file.exists(), isFalse);
  });

  test('keeps debug entries when debug logging is enabled', () async {
    final logger = createLogger();

    logger.event(
      'ai.validation_source_missing',
      level: AppLogLevel.debug,
      source: 'ai_service',
      metadata: {'field': 'summary_event'},
    );
    await logger.drain();

    final entries = await readEntries();
    expect(entries.single['level'], 'debug');
    expect(entries.single['metadata'], {'field': 'summary_event'});
  });

  test('cleans log files older than retention window', () async {
    final logger = createLogger();
    await File('${tempDir.path}/flow_read-2026-05-01.log').writeAsString('old');
    await File('${tempDir.path}/flow_read-2026-05-20.log').writeAsString('new');

    await logger.init();

    expect(
      await File('${tempDir.path}/flow_read-2026-05-01.log').exists(),
      isFalse,
    );
    expect(
      await File('${tempDir.path}/flow_read-2026-05-20.log').exists(),
      isTrue,
    );
  });

  test('redacts secrets, content, URL query, and local paths', () async {
    final logger = createLogger();
    const selectedText = 'This paragraph came from a private imported book.';
    const bookTitle = 'Private Book Title';

    logger.event(
      'security.sample',
      level: AppLogLevel.error,
      source: 'security_test',
      metadata: {
        'apiKey': 'sk-super-secret-token',
        'authorization': 'Bearer bearer-secret-token',
        'url': 'https://example.com/feed.xml?token=query-secret#fragment',
        'path': '/Users/alice/Documents/private/book.epub',
        'selectedText': selectedText,
        'bookTitle': bookTitle,
        'safeCode': 'rss',
        'nested': {
          'password': 'password-secret',
          'response': 'AI response text should not be logged',
        },
      },
      error: Exception(
        'Authorization: Bearer error-secret at '
        '/Users/alice/Documents/private/book.epub '
        'https://example.com/api?apiKey=query-secret',
      ),
      stackTrace: StackTrace.fromString(
        '#0 main (/Users/alice/project/lib/main.dart:10:2)',
      ),
    );
    await logger.drain();

    final file = File('${tempDir.path}/flow_read-2026-05-24.log');
    final content = await file.readAsString();

    expect(content, isNot(contains('sk-super-secret-token')));
    expect(content, isNot(contains('bearer-secret-token')));
    expect(content, isNot(contains('error-secret')));
    expect(content, isNot(contains('query-secret')));
    expect(content, isNot(contains('alice')));
    expect(content, isNot(contains('book.epub')));
    expect(content, isNot(contains(selectedText)));
    expect(content, isNot(contains(bookTitle)));
    expect(content, isNot(contains('AI response text should not be logged')));
    expect(content, contains('https://example.com/feed.xml'));
    expect(content, contains('<redacted>'));
    expect(content, contains('<redacted_content>'));
    expect(content, contains('<local_path>'));

    final entry = (await readEntries()).single;
    final metadata = entry['metadata'] as Map<String, dynamic>;
    expect(metadata['safeCode'], 'rss');
    expect(metadata['apiKey'], '<redacted>');
    expect(metadata['selectedText'], '<redacted_content>');
    expect(metadata['path'], '<redacted_content>');
  });
}
