import 'dart:io';

import 'package:flow_read/app/flow_read_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseV2Enabled reads common dotenv forms', () {
    expect(FlowReadEnv.parseV2Enabled('FLOW_V2=true'), isTrue);
    expect(FlowReadEnv.parseV2Enabled('export FLOW_V2="true"'), isTrue);
    expect(FlowReadEnv.parseV2Enabled("FLOW_V2='false'"), isFalse);
    expect(FlowReadEnv.parseV2Enabled('OTHER=true'), isNull);
  });

  test('loadV2Enabled prefers dart define and process environment', () async {
    expect(
      await FlowReadEnv.loadV2Enabled(
        compileTimeEnabled: true,
        environment: const {FlowReadEnv.flowV2Key: 'false'},
      ),
      isTrue,
    );
    expect(
      await FlowReadEnv.loadV2Enabled(
        compileTimeEnabled: false,
        environment: const {FlowReadEnv.flowV2Key: 'true'},
      ),
      isTrue,
    );
  });

  test(
    'loadV2Enabled reads ignored local env from parent directories',
    () async {
      final root = await Directory.systemTemp.createTemp('flow_read_env_test_');
      try {
        await File('${root.path}/.env').writeAsString('FLOW_V2=true\n');
        final nested = Directory('${root.path}/build/macos/Build');
        await nested.create(recursive: true);

        final enabled = await FlowReadEnv.loadV2Enabled(
          compileTimeEnabled: false,
          environment: const {},
          currentDirectory: nested,
          executablePath: '',
        );

        expect(enabled, isTrue);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test('loadV2Enabled searches upward from executable path', () async {
    final root = await Directory.systemTemp.createTemp('flow_read_env_test_');
    try {
      await File('${root.path}/.env').writeAsString('FLOW_V2=true\n');
      final executablePath =
          '${root.path}/build/macos/Build/Products/Debug/'
          'flow_read.app/Contents/MacOS/flow_read';

      final enabled = await FlowReadEnv.loadV2Enabled(
        compileTimeEnabled: false,
        environment: const {},
        currentDirectory: Directory.systemTemp,
        executablePath: executablePath,
      );

      expect(enabled, isTrue);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
