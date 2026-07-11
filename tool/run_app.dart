import 'dart:io';

import 'flutter_command.dart';
import 'tool_env.dart';

Future<void> main(List<String> args) async {
  try {
    final flutter = await resolveFlutterCommand();
    final env = await loadToolEnv();
    final flutterArgs = <String>[
      '--no-version-check',
      'run',
      ..._withConfiguredAIDebugMirror(_withDefaultDevice(args), env),
    ];

    final process = await Process.start(
      flutter.executable,
      [...flutter.prefixArgs, ...flutterArgs],
      mode: ProcessStartMode.inheritStdio,
      environment: flutter.environment,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      exit(exitCode);
    }
  } on FlutterCommandException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

List<String> _withConfiguredAIDebugMirror(
  List<String> args,
  Map<String, String> env,
) {
  final mirrorDir = env['FLOW_AI_DEBUG_TRACE_MIRROR_DIR']?.trim();
  if (_isHelpCommand(args) ||
      !_hasDartDefine(args, 'FLOW_AI_DEBUG_TRACE', 'true') ||
      _hasDartDefineKey(args, 'FLOW_AI_DEBUG_TRACE_MIRROR_DIR') ||
      mirrorDir == null ||
      mirrorDir.isEmpty) {
    return args;
  }
  return [
    ...args,
    '--dart-define=FLOW_AI_DEBUG_TRACE_MIRROR_DIR=$mirrorDir',
  ];
}

List<String> _withDefaultDevice(List<String> args) {
  if (_hasDeviceSelector(args) || _isHelpCommand(args)) {
    return args;
  }
  final device = switch (Platform.operatingSystem) {
    'macos' => 'macos',
    'windows' => 'windows',
    _ => null,
  };
  return device == null ? args : [...args, '-d', device];
}

bool _hasDeviceSelector(List<String> args) {
  for (final arg in args) {
    if (arg == '-d' || arg == '--device-id') return true;
    if (arg.startsWith('-d') && arg.length > 2) return true;
    if (arg.startsWith('--device-id=')) return true;
  }
  return false;
}

bool _isHelpCommand(List<String> args) {
  return args.contains('-h') || args.contains('--help');
}

bool _hasDartDefine(List<String> args, String key, String value) {
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == '--dart-define' && i + 1 < args.length) {
      if (args[i + 1] == '$key=$value') return true;
    }
    if (arg == '--dart-define=$key=$value') return true;
  }
  return false;
}

bool _hasDartDefineKey(List<String> args, String key) {
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == '--dart-define' && i + 1 < args.length) {
      if (args[i + 1].startsWith('$key=')) return true;
    }
    if (arg.startsWith('--dart-define=$key=')) return true;
  }
  return false;
}
