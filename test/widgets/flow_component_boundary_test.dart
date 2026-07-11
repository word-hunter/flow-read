import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('business UI uses Flow platform adapters for core primitives', () {
    final disallowed = RegExp(
      r'\b(FilledButton|OutlinedButton|TextButton|TextField|AlertDialog|NavigationBar|AppBar)\b|showModalBottomSheet',
    );
    final allowedPrefixes = [
      'lib/widgets/flow/',
      'lib/theme/',
    ];
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (allowedPrefixes.any(path.startsWith)) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        if (disallowed.hasMatch(lines[index])) {
          violations.add('$path:${index + 1}: ${lines[index].trim()}');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
