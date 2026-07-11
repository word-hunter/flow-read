import 'dart:io';

Future<FlutterCommand> resolveFlutterCommand() async {
  if (await _isExecutableAvailable('fvm', ['--version'])) {
    return FlutterCommand(
      'fvm',
      const ['flutter'],
      _flutterProcessEnvironment(),
    );
  }
  if (await _isExecutableAvailable('flutter', [
    '--no-version-check',
    '--version',
  ])) {
    return FlutterCommand(
      'flutter',
      const [],
      _flutterProcessEnvironment(),
    );
  }

  for (final root in _flutterRootCandidates()) {
    final executable = File(
      '${root.path}${Platform.pathSeparator}bin${Platform.pathSeparator}'
      '${Platform.isWindows ? 'flutter.bat' : 'flutter'}',
    );
    if (executable.existsSync()) {
      return FlutterCommand(
        executable.path,
        const [],
        _flutterProcessEnvironment(),
      );
    }
  }

  throw const FlutterCommandException(
    'Flutter SDK was not found. Install FVM or add Flutter to PATH. '
    'You can also set FLUTTER_ROOT or FLOW_FLUTTER_ROOT.',
  );
}

Map<String, String>? _flutterProcessEnvironment() {
  if (!Platform.isWindows) return null;
  final localAppData = Platform.environment['LOCALAPPDATA']?.trim();
  if (localAppData == null || localAppData.isEmpty) return null;

  final nugetDir = Directory(
    '$localAppData${Platform.pathSeparator}NuGet',
  );
  final nuget = File(
    '${nugetDir.path}${Platform.pathSeparator}nuget.exe',
  );
  if (!nuget.existsSync()) return null;

  final environment = Map<String, String>.of(Platform.environment);
  final currentPath = environment['PATH'] ?? environment['Path'] ?? '';
  environment['PATH'] = currentPath.isEmpty
      ? nugetDir.path
      : '${nugetDir.path};$currentPath';
  return environment;
}

Iterable<Directory> _flutterRootCandidates() sync* {
  final seen = <String>{};
  for (final key in const ['FLOW_FLUTTER_ROOT', 'FLUTTER_ROOT']) {
    final value = Platform.environment[key]?.trim();
    if (value != null && value.isNotEmpty && seen.add(value)) {
      yield Directory(value);
    }
  }

  final localFvmRoot = Directory(
    '.fvm${Platform.pathSeparator}flutter_sdk',
  ).absolute;
  if (seen.add(localFvmRoot.path)) {
    yield localFvmRoot;
  }

  var bundledRoot = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 4; i += 1) {
    bundledRoot = bundledRoot.parent;
  }
  if (seen.add(bundledRoot.path)) {
    yield bundledRoot;
  }
}

Future<bool> _isExecutableAvailable(
  String executable,
  List<String> arguments,
) async {
  try {
    final result = await Process.run(executable, arguments);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

class FlutterCommand {
  const FlutterCommand(
    this.executable, [
    this.prefixArgs = const [],
    this.environment,
  ]);

  final String executable;
  final List<String> prefixArgs;
  final Map<String, String>? environment;
}

class FlutterCommandException implements Exception {
  const FlutterCommandException(this.message);

  final String message;
}
