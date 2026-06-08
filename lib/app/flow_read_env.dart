import 'dart:io';

class FlowReadEnv {
  static const flowV2Key = 'FLOW_V2';

  const FlowReadEnv._();

  static Future<bool> loadV2Enabled({
    required bool compileTimeEnabled,
    Map<String, String>? environment,
    Directory? currentDirectory,
    String? executablePath,
    Uri? scriptUri,
  }) async {
    final result = await loadV2Config(
      compileTimeEnabled: compileTimeEnabled,
      environment: environment,
      currentDirectory: currentDirectory,
      executablePath: executablePath,
      scriptUri: scriptUri,
    );
    return result.enabled;
  }

  static Future<FlowReadV2Config> loadV2Config({
    required bool compileTimeEnabled,
    Map<String, String>? environment,
    Directory? currentDirectory,
    String? executablePath,
    Uri? scriptUri,
  }) async {
    if (compileTimeEnabled) {
      return const FlowReadV2Config(enabled: true, source: 'dart-define');
    }

    final envValue = _parseBool(
      (environment ?? Platform.environment)[flowV2Key],
    );
    if (envValue != null) {
      return FlowReadV2Config(enabled: envValue, source: 'process-env');
    }

    final fileResult = await _readLocalEnv(
      currentDirectory: currentDirectory ?? Directory.current,
      executablePath: executablePath ?? Platform.resolvedExecutable,
      scriptUri: scriptUri ?? Platform.script,
    );
    final fileValue = parseV2Enabled(fileResult.content);
    if (fileValue != null) {
      return FlowReadV2Config(
        enabled: fileValue,
        source: fileResult.source ?? 'local-env',
        searchedPaths: fileResult.searchedPaths,
      );
    }

    return FlowReadV2Config(
      enabled: false,
      source: 'default',
      searchedPaths: fileResult.searchedPaths,
    );
  }

  static bool? parseV2Enabled(String? content) {
    if (content == null) return null;
    return parseBoolEntry(content, flowV2Key);
  }

  static bool? parseBoolEntry(String content, String key) {
    for (final line in content.split('\n')) {
      var trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (trimmed.startsWith('export ')) {
        trimmed = trimmed.substring('export '.length).trimLeft();
      }
      final eq = trimmed.indexOf('=');
      if (eq < 0) continue;
      if (trimmed.substring(0, eq).trim() != key) continue;
      return _parseBool(_unquote(trimmed.substring(eq + 1).trim()));
    }
    return null;
  }

  static Future<_LocalEnvReadResult> _readLocalEnv({
    required Directory currentDirectory,
    required String executablePath,
    required Uri scriptUri,
  }) async {
    final searchedPaths = <String>[];
    for (final directory in _candidateDirectories(
      currentDirectory,
      executablePath,
      scriptUri,
    )) {
      final file = File('${directory.path}${Platform.pathSeparator}.env');
      searchedPaths.add(file.path);
      try {
        if (await file.exists()) {
          return _LocalEnvReadResult(
            content: await file.readAsString(),
            source: file.path,
            searchedPaths: searchedPaths,
          );
        }
      } catch (_) {
        // Ignore inaccessible candidates and keep searching upward.
      }
    }
    return _LocalEnvReadResult(searchedPaths: searchedPaths);
  }

  static Iterable<Directory> _candidateDirectories(
    Directory currentDirectory,
    String executablePath,
    Uri scriptUri,
  ) sync* {
    final seen = <String>{};
    yield* _selfAndParents(currentDirectory, seen: seen);

    if (executablePath.trim().isNotEmpty) {
      yield* _selfAndParents(File(executablePath).parent, seen: seen);
    }

    if (scriptUri.scheme == 'file') {
      yield* _selfAndParents(File(scriptUri.toFilePath()).parent, seen: seen);
    }
  }

  static Iterable<Directory> _selfAndParents(
    Directory start, {
    required Set<String> seen,
  }) sync* {
    var directory = start.absolute;
    for (var depth = 0; depth < 12; depth++) {
      final path = directory.path;
      if (seen.add(path)) yield directory;
      final parent = directory.parent;
      if (parent.path == path) return;
      directory = parent;
    }
  }

  static String _unquote(String value) {
    if (value.length < 2) return value;
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static bool? _parseBool(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
    }
    return null;
  }
}

class FlowReadV2Config {
  final bool enabled;
  final String source;
  final List<String> searchedPaths;

  const FlowReadV2Config({
    required this.enabled,
    required this.source,
    this.searchedPaths = const [],
  });
}

class _LocalEnvReadResult {
  final String? content;
  final String? source;
  final List<String> searchedPaths;

  const _LocalEnvReadResult({
    this.content,
    this.source,
    this.searchedPaths = const [],
  });
}
