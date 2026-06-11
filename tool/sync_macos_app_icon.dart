import 'dart:io';

const _sourceLogoPath = 'assets/brand/flow_read_logo.png';
const _appIconDir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
const _iconSizes = [16, 32, 64, 128, 256, 512, 1024];

Future<void> main(List<String> args) async {
  if (args.length != 1 || args.first == '--help' || args.first == '-h') {
    _printUsage();
    exitCode = args.length == 1 ? 0 : 64;
    return;
  }

  try {
    switch (args.first) {
      case '--fix':
        await _syncIcons(checkOnly: false);
      case '--check':
        await _syncIcons(checkOnly: true);
      default:
        throw const _IconSyncException('Expected --fix or --check.');
    }
  } on _IconSyncException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

Future<void> _syncIcons({required bool checkOnly}) async {
  final source = File(_sourceLogoPath);
  if (!source.existsSync()) {
    throw _IconSyncException('Source logo does not exist: $_sourceLogoPath.');
  }

  final appIconDir = Directory(_appIconDir);
  if (!appIconDir.existsSync()) {
    throw _IconSyncException('AppIcon directory does not exist: $_appIconDir.');
  }

  final tempDir = checkOnly
      ? Directory.systemTemp.createTempSync('flow_read_app_icon_check_')
      : null;
  final staleIcons = <String>[];

  try {
    for (final size in _iconSizes) {
      final fileName = 'app_icon_$size.png';
      final expectedPath = _joinPath(_appIconDir, fileName);
      final outputPath = checkOnly
          ? _joinPath(tempDir!.path, fileName)
          : expectedPath;

      await _resizeWithSips(size: size, outputPath: outputPath);

      if (checkOnly && !_sameBytes(File(outputPath), File(expectedPath))) {
        staleIcons.add(expectedPath);
      }
    }
  } finally {
    if (tempDir != null && tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  if (staleIcons.isNotEmpty) {
    throw _IconSyncException(
      'macOS AppIcon is out of sync with $_sourceLogoPath:\n'
      '${staleIcons.map((path) => '- $path').join('\n')}\n\n'
      'Run: dart run tool/sync_macos_app_icon.dart --fix',
    );
  }

  if (checkOnly) {
    stdout.writeln('macOS AppIcon is in sync with $_sourceLogoPath.');
  } else {
    stdout.writeln('Updated macOS AppIcon from $_sourceLogoPath.');
  }
}

Future<void> _resizeWithSips({
  required int size,
  required String outputPath,
}) async {
  try {
    final result = await Process.run('sips', [
      '-z',
      size.toString(),
      size.toString(),
      _sourceLogoPath,
      '--out',
      outputPath,
    ]);

    if (result.exitCode != 0) {
      throw _IconSyncException(
        'Failed to generate $outputPath with sips:\n'
        '${result.stdout}${result.stderr}',
      );
    }
  } on ProcessException catch (error) {
    throw _IconSyncException(
      'Failed to run sips. This tool requires macOS.\n${error.message}',
    );
  }
}

bool _sameBytes(File actual, File expected) {
  if (!actual.existsSync() || !expected.existsSync()) {
    return false;
  }

  final actualBytes = actual.readAsBytesSync();
  final expectedBytes = expected.readAsBytesSync();
  if (actualBytes.length != expectedBytes.length) {
    return false;
  }

  for (var i = 0; i < actualBytes.length; i += 1) {
    if (actualBytes[i] != expectedBytes[i]) {
      return false;
    }
  }
  return true;
}

String _joinPath(String parent, String child) {
  if (parent.endsWith(Platform.pathSeparator)) {
    return '$parent$child';
  }
  return '$parent${Platform.pathSeparator}$child';
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/sync_macos_app_icon.dart --fix
  dart run tool/sync_macos_app_icon.dart --check
''');
}

class _IconSyncException implements Exception {
  const _IconSyncException(this.message);

  final String message;
}
