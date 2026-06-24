import 'dart:io';

import 'tool_env.dart';

Future<void> main(List<String> args) async {
  final flutter = await _resolveFlutterCommand();
  final env = await loadToolEnv();
  final flutterArgs = <String>[
    'run',
    ..._withConfiguredAIDebugMirror(_withDefaultDevice(args), env),
  ];

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
  if (!Platform.isMacOS || _hasDeviceSelector(args) || _isHelpCommand(args)) {
    return args;
  }
  return [...args, '-d', 'macos'];
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
