import 'dart:io';

const _pubspecPath = 'pubspec.yaml';
const _changelogPath = 'CHANGELOG.md';
const _appVersionPath = 'lib/services/app_version.dart';
const _defaultDistDir = 'dist';
const _appBundleName = 'FlowRead.app';
const _requiredReleaseEntitlements = [
  'com.apple.security.network.client',
  'com.apple.security.files.user-selected.read-write',
  'com.apple.security.files.bookmarks.app-scope',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    return;
  }

  try {
    switch (args.first) {
      case 'current':
        _current();
      case 'check':
        _check(args.skip(1).toList());
      case 'notes':
        _notes(args.skip(1).toList());
      case 'bump':
        _bump(args.skip(1).toList());
      case 'package-local':
        await _packageLocal(args.skip(1).toList());
      default:
        throw UsageException('Unknown command: ${args.first}');
    }
  } on UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    _printUsage();
    exitCode = 64;
  } on ReleaseException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

Future<void> _packageLocal(List<String> args) async {
  final options = _Options(args);
  final configuration = options.value('configuration') ?? 'release';
  if (!{'debug', 'release'}.contains(configuration)) {
    throw UsageException(
      'Invalid configuration: $configuration. Use debug or release.',
    );
  }

  final outputDir = options.value('output-dir') ?? _defaultDistDir;
  final skipPubGet = options.has('skip-pub-get');
  final skipTests = options.has('skip-tests');
  final skipArchiveCheck = options.has('skip-archive-check');
  final version = _readVersion();

  _validateReleaseMetadata(version);

  stdout.writeln(
    'Packaging ${version.releaseName} (${version.full}) for local testing.',
  );
  stdout.writeln('Version files will not be changed.');

  if (!skipPubGet) {
    await _runCommand('flutter', ['pub', 'get']);
  }
  if (!skipTests) {
    await _runCommand('flutter', ['test']);
  }

  await _runCommand('flutter', ['build', 'macos', '--$configuration']);

  final appPath = _macosAppPath(configuration);
  if (!Directory(appPath).existsSync()) {
    throw ReleaseException('Build did not produce $appPath.');
  }

  final entitlements = await _runCommandCapture('codesign', [
    '-d',
    '--entitlements',
    ':-',
    appPath,
  ]);
  _verifyEntitlements(entitlements);

  Directory(outputDir).createSync(recursive: true);
  final zipPath = _joinPath(
    outputDir,
    'flow_read-macos-${version.releaseName}-$configuration-local.zip',
  );
  final zipFile = File(zipPath);
  if (zipFile.existsSync()) {
    zipFile.deleteSync();
  }

  await _runCommand('ditto', [
    '-c',
    '-k',
    '--sequesterRsrc',
    '--keepParent',
    appPath,
    zipPath,
  ]);

  if (!zipFile.existsSync() || zipFile.lengthSync() == 0) {
    throw ReleaseException('Package was not created: $zipPath.');
  }

  if (!skipArchiveCheck) {
    await _verifyArchive(zipPath);
  }

  stdout.writeln('');
  stdout.writeln('Local package ready: $zipPath');
}

void _current() {
  stdout.writeln(_readVersion().currentLabel);
}

void _check(List<String> args) {
  final options = _Options(args);
  final version = _readVersion();
  final expected = options.value('version');
  final tag = options.value('tag');

  _validateReleaseMetadata(version, expected: expected, tag: tag);

  stdout.writeln(
    'Release metadata is valid for ${version.releaseName} (${version.full}).',
  );
}

void _validateReleaseMetadata(
  AppVersion version, {
  String? expected,
  String? tag,
}) {
  if (expected != null && !_matchesReleaseName(expected, version)) {
    throw ReleaseException(
      'Expected version $expected, but release metadata contains ${version.releaseName}.',
    );
  }

  if (tag != null && !_matchesReleaseName(tag, version)) {
    throw ReleaseException(
      'Tag $tag does not match release ${version.releaseName}.',
    );
  }

  final changelog = _readRequiredFile(_changelogPath);
  if (!_hasChangelogSection(changelog, version.releaseName)) {
    throw ReleaseException(
      'CHANGELOG.md is missing a release section for ${version.releaseName}.',
    );
  }
  _checkAppVersionFile(version);
}

void _notes(List<String> args) {
  final options = _Options(args);
  final version = options.value('version') ?? _readVersion().releaseName;
  final changelog = _readRequiredFile(_changelogPath);
  stdout.write(
    _extractChangelogSection(changelog, _normalizeReleaseName(version)),
  );
}

void _bump(List<String> args) {
  if (args.isEmpty) {
    throw UsageException('Missing bump level: major, minor, or patch.');
  }

  final level = args.first;
  if (!{'major', 'minor', 'patch'}.contains(level)) {
    throw UsageException('Invalid bump level: $level.');
  }

  final options = _Options(args.skip(1).toList());
  final current = _readVersion();
  final nextName = current.next(level);
  final nextBuild =
      int.tryParse(options.value('build') ?? '') ?? current.build + 1;
  final nextChannel = options.value('channel') ?? current.channel;
  final date = options.value('date') ?? _today();
  final next = AppVersion(nextName, nextBuild, channel: nextChannel);

  _writeVersion(next);
  _writeAppVersion(next);
  _writeChangelogRelease(next.releaseName, date);

  stdout.writeln('Bumped version to ${next.full}.');
  stdout.writeln(
    'Next step: git tag ${next.tag} after committing the release.',
  );
}

AppVersion _readVersion() {
  final pubspec = _readRequiredFile(_pubspecPath);
  final match = RegExp(
    r'^version:[ \t]*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)[ \t]*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw ReleaseException(
      'pubspec.yaml must contain version: MAJOR.MINOR.PATCH+BUILD.',
    );
  }

  return AppVersion(
    match.group(1)!,
    int.parse(match.group(2)!),
    channel: _readAppVersionChannel(),
  );
}

void _writeVersion(AppVersion version) {
  final pubspec = _readRequiredFile(_pubspecPath);
  final next = pubspec.replaceFirst(
    RegExp(
      r'^version:[ \t]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[ \t]*$',
      multiLine: true,
    ),
    'version: ${version.full}',
  );

  File(_pubspecPath).writeAsStringSync(next);
}

void _checkAppVersionFile(AppVersion version) {
  final content = _readRequiredFile(_appVersionPath);
  final expected = _appVersionContent(version);
  if (content.trim() != expected.trim()) {
    throw ReleaseException(
      '$_appVersionPath does not match pubspec.yaml version ${version.full}. '
      'Run dart run tool/release.dart bump <major|minor|patch> or update it.',
    );
  }
}

void _writeAppVersion(AppVersion version) {
  File(_appVersionPath).writeAsStringSync(_appVersionContent(version));
}

String _appVersionContent(AppVersion version) {
  return '''
class FlowReadVersion {
  static const name = '${version.name}';
  static const channel = '${version.channel}';
  static const releaseName = '${version.releaseName}';
  static const buildNumber = ${version.build};
  static const full = '${version.full}';
  static const tag = '${version.tag}';
  static const shortDisplay = '${version.shortDisplay}';
  static const display = '${version.display}';
}
''';
}

void _writeChangelogRelease(String version, String date) {
  final changelog = _readRequiredFile(_changelogPath);
  if (_hasChangelogSection(changelog, version)) {
    throw ReleaseException('CHANGELOG.md already contains $version.');
  }

  final unreleased = _unreleasedContent(changelog).trim();
  final releaseNotes = unreleased.isEmpty
      ? '### Changed\n\n- Prepared $version release.'
      : unreleased;

  final block = RegExp(
    r'^## \[Unreleased\][ \t]*\n[\s\S]*?(?=^## \[[^\]]+\])',
    multiLine: true,
  );
  if (!block.hasMatch(changelog)) {
    throw ReleaseException('CHANGELOG.md must contain ## [Unreleased].');
  }

  final next = changelog.replaceFirst(
    block,
    '## [Unreleased]\n\n## [$version] - $date\n\n$releaseNotes\n\n',
  );

  File(_changelogPath).writeAsStringSync(next);
}

String _unreleasedContent(String changelog) {
  final match = RegExp(
    r'^## \[Unreleased\][ \t]*\n([\s\S]*?)(?=^## \[[^\]]+\])',
    multiLine: true,
  ).firstMatch(changelog);
  return match?.group(1) ?? '';
}

bool _hasChangelogSection(String changelog, String version) {
  return RegExp(
    '^## \\[${RegExp.escape(version)}\\](?: - \\d{4}-\\d{2}-\\d{2})?[ \\t]*\$',
    multiLine: true,
  ).hasMatch(changelog);
}

String _extractChangelogSection(String changelog, String version) {
  final heading = RegExp(
    '^## \\[${RegExp.escape(version)}\\](?: - \\d{4}-\\d{2}-\\d{2})?[ \\t]*\\n',
    multiLine: true,
  );
  final match = heading.firstMatch(changelog);
  if (match == null) {
    throw ReleaseException('CHANGELOG.md is missing $version.');
  }

  final start = match.end;
  final nextHeading = RegExp(
    r'^## \[[^\]]+\]',
    multiLine: true,
  ).firstMatch(changelog.substring(start));
  final end = nextHeading == null
      ? changelog.length
      : start + nextHeading.start;
  return '${changelog.substring(start, end).trim()}\n';
}

String _readRequiredFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw ReleaseException('$path does not exist.');
  }
  return file.readAsStringSync();
}

String _readAppVersionChannel() {
  final file = File(_appVersionPath);
  if (!file.existsSync()) {
    return AppVersion.stableChannel;
  }

  final content = file.readAsStringSync();
  final match = RegExp(
    r"static const channel = '([^']+)';",
  ).firstMatch(content);
  return match?.group(1) ?? AppVersion.stableChannel;
}

String _macosAppPath(String configuration) {
  final productDir = switch (configuration) {
    'debug' => 'Debug',
    'release' => 'Release',
    _ => throw UsageException('Invalid configuration: $configuration.'),
  };
  return _joinPath(
    _joinPath('build/macos/Build/Products', productDir),
    _appBundleName,
  );
}

void _verifyEntitlements(String output) {
  final missing = _requiredReleaseEntitlements
      .where((entitlement) => !output.contains(entitlement))
      .toList();
  if (missing.isNotEmpty) {
    throw ReleaseException(
      'Signed app is missing required entitlements: ${missing.join(', ')}.',
    );
  }
}

Future<void> _verifyArchive(String zipPath) async {
  final tempDir = Directory.systemTemp.createTempSync(
    'flow_read_package_check_',
  );
  try {
    await _runCommand('ditto', ['-x', '-k', zipPath, tempDir.path]);
    final extractedApp = Directory(_joinPath(tempDir.path, _appBundleName));
    if (!extractedApp.existsSync()) {
      throw ReleaseException(
        'Archive check failed: $_appBundleName was not found after extraction.',
      );
    }
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Future<void> _runCommand(String executable, List<String> arguments) async {
  stdout.writeln('');
  stdout.writeln('> ${_formatCommand(executable, arguments)}');
  try {
    final process = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw ReleaseException(
        'Command failed with exit code $exitCode: '
        '${_formatCommand(executable, arguments)}',
      );
    }
  } on ProcessException catch (error) {
    throw ReleaseException(
      'Failed to run ${_formatCommand(executable, arguments)}: '
      '${error.message}',
    );
  }
}

Future<String> _runCommandCapture(
  String executable,
  List<String> arguments,
) async {
  stdout.writeln('');
  stdout.writeln('> ${_formatCommand(executable, arguments)}');
  try {
    final result = await Process.run(executable, arguments);
    final output = '${result.stdout}${result.stderr}';
    stdout.write(output);
    if (result.exitCode != 0) {
      throw ReleaseException(
        'Command failed with exit code ${result.exitCode}: '
        '${_formatCommand(executable, arguments)}',
      );
    }
    return output;
  } on ProcessException catch (error) {
    throw ReleaseException(
      'Failed to run ${_formatCommand(executable, arguments)}: '
      '${error.message}',
    );
  }
}

String _formatCommand(String executable, List<String> arguments) {
  return [executable, ...arguments].map(_shellQuote).join(' ');
}

String _shellQuote(String value) {
  if (value.isEmpty) {
    return "''";
  }
  if (!RegExp(r'''[\s'"\\$`!]''').hasMatch(value)) {
    return value;
  }
  return "'${value.replaceAll("'", r"'\''")}'";
}

String _joinPath(String parent, String child) {
  if (parent.isEmpty) {
    return child;
  }
  return parent.endsWith(Platform.pathSeparator)
      ? '$parent$child'
      : '$parent${Platform.pathSeparator}$child';
}

bool _matchesReleaseName(String value, AppVersion version) {
  final normalized = _normalizeReleaseName(value);
  return normalized == version.releaseName || normalized == version.name;
}

String _normalizeReleaseName(String value) {
  final trimmed = value.trim();
  final humanAlpha = RegExp(r'^alpha\s+([0-9]+\.[0-9]+\.[0-9]+)$');
  final humanMatch = humanAlpha.firstMatch(trimmed);
  if (humanMatch != null) {
    return '${humanMatch.group(1)}-alpha';
  }

  final version = trimmed.replaceFirst(RegExp(r'^v'), '');
  return version.split('+').first;
}

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/release.dart current
  dart run tool/release.dart check [--tag v1.2.3 | --version 1.2.3]
  dart run tool/release.dart notes [--version 1.2.3]
  dart run tool/release.dart bump <major|minor|patch> [--build 12] [--channel alpha] [--date YYYY-MM-DD]
  dart run tool/release.dart package-local [--configuration release|debug] [--output-dir dist] [--skip-pub-get] [--skip-tests] [--skip-archive-check]
''');
}

class AppVersion {
  AppVersion(this.name, this.build, {String channel = stableChannel})
    : channel = channel.trim().isEmpty ? stableChannel : channel.trim() {
    final parts = name.split('.');
    if (parts.length != 3 || parts.any((part) => int.tryParse(part) == null)) {
      throw ReleaseException('Invalid semantic version: $name.');
    }
  }

  static const stableChannel = 'stable';

  final String name;
  final int build;
  final String channel;

  String get full => '$name+$build';
  String get releaseName => channel == stableChannel ? name : '$name-$channel';
  String get currentLabel =>
      channel == stableChannel ? full : '$releaseName+$build';
  String get tag => 'v$releaseName';
  String get shortDisplay => channel == stableChannel ? name : '$channel $name';
  String get display => '$shortDisplay ($build)';

  String next(String level) {
    final parts = name.split('.').map(int.parse).toList();
    switch (level) {
      case 'major':
        parts[0] += 1;
        parts[1] = 0;
        parts[2] = 0;
      case 'minor':
        parts[1] += 1;
        parts[2] = 0;
      case 'patch':
        parts[2] += 1;
    }

    return parts.join('.');
  }
}

class _Options {
  _Options(this.args);

  final List<String> args;

  String? value(String name) {
    final flag = '--$name';
    final index = args.indexOf(flag);
    if (index == -1) {
      return null;
    }
    if (index == args.length - 1 || args[index + 1].startsWith('--')) {
      throw UsageException('Missing value for $flag.');
    }
    return args[index + 1];
  }

  bool has(String name) {
    return args.contains('--$name');
  }
}

class ReleaseException implements Exception {
  ReleaseException(this.message);

  final String message;
}

class UsageException implements Exception {
  UsageException(this.message);

  final String message;
}
