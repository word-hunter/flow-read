import 'dart:io';

import 'package:flow_read/app/flow_read_env.dart';

Future<void> main(List<String> args) async {
  final config = await FlowReadEnv.loadV2Config(compileTimeEnabled: false);
  final flutter = await _resolveFlutterCommand();
  final flutterArgs = <String>['run'];

  if (config.source != 'default') {
    flutterArgs.add('--dart-define=${FlowReadEnv.flowV2Key}=${config.enabled}');
  }
  flutterArgs.addAll(args);

  stdout.writeln(
    '[FlowRead] launching with ${FlowReadEnv.flowV2Key}=${config.enabled}'
    ' from ${config.source}',
  );

  final process = await Process.start(
    flutter.executable,
    [...flutter.prefixArgs, ...flutterArgs],
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}

Future<_FlutterCommand> _resolveFlutterCommand() async {
  if (await _isExecutableAvailable('fvm', ['--version'])) {
    return const _FlutterCommand(executable: 'fvm', prefixArgs: ['flutter']);
  }
  return const _FlutterCommand(executable: 'flutter', prefixArgs: []);
}

Future<bool> _isExecutableAvailable(
  String executable,
  List<String> args,
) async {
  try {
    final result = await Process.run(executable, args);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

class _FlutterCommand {
  final String executable;
  final List<String> prefixArgs;

  const _FlutterCommand({
    required this.executable,
    this.prefixArgs = const [],
  });
}
