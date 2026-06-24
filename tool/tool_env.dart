import 'dart:io';

Future<Map<String, String>> loadToolEnv({Directory? root}) async {
  final base = root ?? Directory.current;
  final values = Map<String, String>.of(Platform.environment);
  for (final name in const ['.env', '.env.local']) {
    final file = File('${base.path}${Platform.pathSeparator}$name');
    if (!await file.exists()) continue;
    values.addAll(_parseEnvFile(await file.readAsLines()));
  }
  return values;
}

Map<String, String> _parseEnvFile(List<String> lines) {
  final values = <String, String>{};
  for (final rawLine in lines) {
    var line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('export ')) {
      line = line.substring('export '.length).trimLeft();
    }
    final equals = line.indexOf('=');
    if (equals <= 0) continue;
    final key = line.substring(0, equals).trim();
    if (key.isEmpty) continue;
    values[key] = _decodeValue(line.substring(equals + 1).trim());
  }
  return values;
}

String _decodeValue(String value) {
  if (value.length >= 2) {
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
  }
  final commentIndex = value.indexOf(' #');
  if (commentIndex >= 0) return value.substring(0, commentIndex).trimRight();
  return value;
}
