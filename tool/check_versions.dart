import 'dart:io';

/// Validates SDK and shared dependency version consistency across all
/// pubspec.yaml files in the monorepo. Run with --fix to attempt
/// auto-resolution (not yet implemented).

void main(List<String> args) {
  if (args.contains('--fix')) {
    stderr.writeln('--fix is not implemented yet.');
    exit(64);
  }
  final workspaceRoot = Directory.current.path;
  final pubspecPaths = _findPubspecs(workspaceRoot);

  final allErrors = <String>[];
  final sdkVersions = <String, String>{}; // path -> version
  final depVersions =
      <String, Map<String, String>>{}; // dep -> pkgName -> version

  for (final path in pubspecPaths) {
    final file = File(path);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    final pkgName = _extractString(lines, 'name:');

    final sdk = _extractString(lines, 'sdk:');
    if (sdk != null) {
      sdkVersions[path] = sdk;
    }

    bool inDeps = false;
    bool inDevDeps = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'dependencies:') {
        inDeps = true;
        inDevDeps = false;
        continue;
      }
      if (trimmed == 'dev_dependencies:') {
        inDeps = false;
        inDevDeps = true;
        continue;
      }
      if (trimmed == 'dependency_overrides:') {
        inDeps = false;
        inDevDeps = false;
        continue;
      }
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (!trimmed.startsWith(' ') && trimmed.endsWith(':')) {
        inDeps = false;
        inDevDeps = false;
        continue;
      }
      if (!inDeps && !inDevDeps) continue;

      final parts = trimmed.split(':');
      if (parts.length < 2) continue;
      final depName = parts[0].trim();
      final depValue = parts.sublist(1).join(':').trim();
      if (depValue.startsWith('^')) {
        final label = pkgName ?? path;
        depVersions.putIfAbsent(depName, () => {});
        depVersions[depName]![label] = depValue;
      }
    }
  }

  final uniqueSdks = sdkVersions.values.toSet();
  if (uniqueSdks.length > 1) {
    final details = sdkVersions.entries
        .map((e) => '  ${_relPath(workspaceRoot, e.key)}: ${e.value}')
        .join('\n');
    allErrors.add('SDK version mismatch:\n$details');
  }

  for (final entry in depVersions.entries) {
    final versions = entry.value.values.toSet();
    if (versions.length > 1) {
      final details = entry.value.entries
          .map((e) => '  ${e.key}: ${e.value}')
          .join('\n');
      allErrors.add(
        'Dependency "${entry.key}" has mismatched versions:\n$details',
      );
    }
  }

  if (allErrors.isEmpty) {
    stdout.writeln('All pubspec files are consistent.');
    exit(0);
  }

  stderr.writeln('Version inconsistencies found:');
  for (final error in allErrors) {
    stderr.writeln('- $error');
  }
  exit(1);
}

String? _extractString(List<String> lines, String key) {
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith(key)) {
      final value = trimmed.substring(key.length).trim();
      if (value.startsWith('"') || value.startsWith("'")) {
        return value.substring(1, value.length - 1);
      }
      if (value.startsWith('^')) {
        return value;
      }
      return value.isNotEmpty ? value : null;
    }
  }
  return null;
}

List<String> _findPubspecs(String root) {
  final result = <String>[];
  final excludeSegments = {
    '.dart_tool',
    'build',
    '.symlinks',
    'ephemeral',
    'Pods',
  };
  for (final entity in Directory(root).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      final segments = entity.path.split(Platform.pathSeparator);
      if (segments.any((s) => excludeSegments.contains(s))) continue;
      result.add(entity.path);
    }
  }
  return result;
}

String _relPath(String root, String path) {
  if (path.startsWith(root)) {
    var rel = path.substring(root.length);
    if (rel.startsWith('/')) rel = rel.substring(1);
    return rel;
  }
  return path;
}
