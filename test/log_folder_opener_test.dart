import 'dart:io';

import 'package:flow_read/services/app_logger.dart';
import 'package:flow_read/services/log_folder_opener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppLogger logger;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flow_read_log_open_test_');
    logger = AppLogger(
      logDirectoryProvider: () async => tempDir,
      includeDebugProvider: () => true,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns the logger folder path', () async {
    final opener = LogFolderOpener(
      logger: logger,
      platform: LogFolderOpenPlatform.linux,
      isWeb: false,
    );

    expect(await opener.logsFolderPath(), tempDir.path);
  });

  test('opens Linux log folder through xdg-open', () async {
    String? executable;
    List<String>? arguments;
    final opener = LogFolderOpener(
      logger: logger,
      platform: LogFolderOpenPlatform.linux,
      isWeb: false,
      processRunner: (command, args) async {
        executable = command;
        arguments = args;
        return ProcessResult(123, 0, '', '');
      },
    );

    await opener.openLogsFolder();

    expect(executable, 'xdg-open');
    expect(arguments, [tempDir.path]);
  });

  test('reports unsupported platforms without running a command', () async {
    final opener = LogFolderOpener(
      logger: logger,
      platform: LogFolderOpenPlatform.unsupported,
      isWeb: false,
      processRunner: (_, _) async => ProcessResult(123, 0, '', ''),
    );

    expect(opener.openLogsFolder, throwsA(isA<LogFolderOpenException>()));
  });
}
