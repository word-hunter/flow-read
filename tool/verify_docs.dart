// tool/verify_docs.dart
//
// Lightweight script to detect stale assertions in docs/*.md
// before trusting those docs for code generation.
//
// Usage: dart run tool/verify_docs.dart
//
// Checks:
//   1. @source file paths in docs exist in the repo
//   2. Hive type IDs referenced in docs/data-model.md match hive_type_ids.dart
//   3. Box names referenced in docs/storage-contract.md match hive_box_names.dart
//   4. Key service classes referenced in docs exist under lib/services/
//
// This is not a CI gate. It is a quick sanity check.
// Exit code 0 = all checks pass. Non-zero = issue found.

import 'dart:io';

final _repoRoot = Directory.current.path;
final _docsDir = Directory('$_repoRoot/docs');
final _libDir = '$_repoRoot/lib';
final _hiveTypeIdsFile = File('$_libDir/storage/hive_type_ids.dart');
final _hiveBoxNamesFile = File('$_libDir/storage/hive_box_names.dart');
final _servicesDir = Directory('$_libDir/services');

void main(List<String> args) {
  var allOk = true;

  if (!_docsDir.existsSync()) {
    stderr.writeln('[FAIL] docs/ directory not found');
    exit(1);
  }

  final docFiles = _docsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  if (docFiles.isEmpty) {
    stderr.writeln('[WARN] No .md files in docs/');
    exit(0);
  }

  stdout.writeln('=== Flow Read Doc Freshness Check ===');
  stdout.writeln('Checking ${docFiles.length} doc(s)...\n');

  // ── Check 1: @source paths ────────────────────────────────
  stdout.writeln('── @source path check ──');
  for (final doc in docFiles) {
    final lines = doc.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'@source\s+(.+)').firstMatch(line);
      if (match != null) {
        final paths = match.group(1)!.split(RegExp(r'\s+'));
        for (final relPath in paths) {
          final trimmed = relPath.trim();
          if (trimmed.isEmpty) continue;
          final fullPath = '$_repoRoot/$trimmed';
          if (!File(fullPath).existsSync() && !Directory(fullPath).existsSync()) {
            stderr.writeln(
              '  [FAIL] ${doc.path.replaceFirst(_repoRoot, '')}:${i + 1} '
              '@source "$trimmed" not found',
            );
            allOk = false;
          }
        }
      }
    }
  }

  if (!allOk) stdout.writeln('  (some @source paths are stale)\n');

  // ── Check 2: Hive type IDs in docs/data-model.md ───────────
  stdout.writeln('── Hive type ID check ──');
  final dataModelFile = File('${_docsDir.path}/data-model.md');
  if (dataModelFile.existsSync()) {
    final docContent = dataModelFile.readAsStringSync();
    final hiveTypesCode = _hiveTypeIdsFile.existsSync()
        ? _hiveTypeIdsFile.readAsStringSync()
        : '';

    // Extract type IDs from docs: skip "待新增" section markers
    final docContentClean = docContent
        .replaceAll(RegExp(r'待新增模型.*', dotAll: true), '')
        .replaceAll(RegExp(r'1\.6\.0.*待新增.*', dotAll: true), '');
    final docTypeIds = <int>{};
    final docTypeNames = <int, String>{};
    for (final m
        in RegExp(r'\|\s*(\d+)\s*\|\s*`(\w+)`').allMatches(docContentClean)) {
      final id = int.parse(m.group(1)!);
      final name = m.group(2)!;
      // Skip empty/placeholder entries
      if (name.isNotEmpty && name != '—') {
        docTypeIds.add(id);
        docTypeNames[id] = name;
      }
    }

    // Extract type IDs from hive_type_ids.dart
    final hiveTypeIds = <int, String>{};
    for (final m in RegExp(r'static const (\w+)\s*=\s*(\d+);')
        .allMatches(hiveTypesCode)) {
      final name = m.group(1)!;
      if (name == 'reserved') continue;
      final id = int.parse(m.group(2)!);
      hiveTypeIds[id] = name;
    }

    // Cross check (case-insensitive name matching)
    for (final id in docTypeIds) {
      if (!hiveTypeIds.containsKey(id)) {
        stderr.writeln(
          '  [FAIL] data-model.md references HiveType $id '
          '(${docTypeNames[id]}) which does not exist in hive_type_ids.dart',
        );
        allOk = false;
      } else {
        final docName = docTypeNames[id]!.toLowerCase();
        final codeName = hiveTypeIds[id]!.toLowerCase();
        if (docName != codeName) {
          stderr.writeln(
            '  [FAIL] data-model.md HiveType $id: doc says "${docTypeNames[id]}", '
            'code says "${hiveTypeIds[id]}"',
          );
          allOk = false;
        }
      }
    }

    // Check reserved set size
    final reservedCount =
        RegExp(r'static const reserved', multiLine: true).hasMatch(hiveTypesCode)
            ? RegExp(
                r'(\d+),',
              ).allMatches(hiveTypesCode.split('static const reserved').last).length +
                1
            : 0;
    stdout.writeln(
      '  data-model.md: ${docTypeIds.length} types documented, '
      'hive_type_ids.dart: ${hiveTypeIds.length} types in code, '
      'reserved: $reservedCount',
    );
  } else {
    stdout.writeln('  (docs/data-model.md not found, skipping)');
  }

  // ── Check 3: Box names in docs/storage-contract.md ─────────
  stdout.writeln('');
  stdout.writeln('── Hive box name check ──');
  final storageContractFile = File('${_docsDir.path}/storage-contract.md');
  if (storageContractFile.existsSync()) {
    final docContent = storageContractFile.readAsStringSync();
    final boxNamesCode = _hiveBoxNamesFile.existsSync()
        ? _hiveBoxNamesFile.readAsStringSync()
        : '';

    // Extract box names from doc tables and code blocks
    final docBoxNames = <String>{};
    for (final m in RegExp(r'`(\w+)`').allMatches(docContent)) {
      final name = m.group(1)!;
      if (name.endsWith('_{lang}') || name.startsWith('word_') || name == 'settings' || name == 'rss_subscriptions' || name == 'word_levels' || name == 'books_en' || name.endsWith('_en') || name == 'user_vocabulary_en') {
        docBoxNames.add(name);
      }
    }

    // Extract box names from hive_box_names.dart (no explicit type)
    final codeBoxNames = <String>{};
    for (final m
        in RegExp(r"static const (\w+)\s*=\s*'([^']+)'")
            .allMatches(boxNamesCode)) {
      final name = m.group(1)!;
      if (name != 'defaultLanguageCode' && name != 'activeSourceLanguageKey') {
        codeBoxNames.add(m.group(2)!);
      }
    }
    // Computed names are dynamic patterns and are intentionally ignored here.

    stdout.writeln(
      '  storage-contract.md: ~${docBoxNames.length} names referenced, '
      'hive_box_names.dart: ${codeBoxNames.length} static names',
    );

    // Only check names that appear to be concrete box names (not _{lang} patterns)
    final concreteDocNames =
        docBoxNames.where((n) => !n.contains('{lang}')).toSet();
    for (final name in concreteDocNames) {
      if (!codeBoxNames.contains(name)) {
        // Allow known patterns like `books_en`, `user_vocabulary_en` which are generated
        if (!name.endsWith('_en')) {
          stderr.writeln(
            '  [WARN] storage-contract.md references box "$name" '
            'not found as static constant in hive_box_names.dart',
          );
        }
      }
    }
  } else {
    stdout.writeln('  (docs/storage-contract.md not found, skipping)');
  }

  // ── Check 4: Key service classes exist ─────────────────────
  stdout.writeln('');
  stdout.writeln('── Service class existence check ──');
  final keyServices = <String>{
    'DictionaryManagerService', 'BookService', 'EpubService',
    'AIService', 'AICacheService', 'PromptBuilder', 'ChapterAIJob',
    'SettingsService', 'BackupService', 'ReadingSearchService',
    'UserVocabularyService', 'WordLevelService', 'LearningAnalyticsService',
    'CompoundWordAnalyzer', 'LanguageRegistry', 'EnglishLanguageModule',
    'ReadingAssistantAgent',
  };

  for (final className in keyServices) {
    final result = _grep('class $className', _servicesDir);
    if (result.isEmpty) {
      stderr.writeln('  [FAIL] Class "$className" not found in lib/services/');
      allOk = false;
    }
  }
  stdout.writeln('  All ${keyServices.length} key service classes found.');

  // ── Result ─────────────────────────────────────────────────
  stdout.writeln('');
  if (allOk) {
    stdout.writeln('[PASS] All checks passed, docs are consistent with code.');
    exit(0);
  } else {
    stderr.writeln(
      '[FAIL] Some checks failed. See above for details.\n'
      '  Fix: update the stale doc references, or update code to match docs.',
    );
    exit(1);
  }
}

/// Simple recursive grep for a pattern in a directory.
String _grep(String pattern, Directory dir) {
  if (!dir.existsSync()) return '';
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = entity.readAsStringSync();
        if (content.contains(pattern)) {
          return entity.path;
        }
      } catch (_) {
        // skip unreadable files
      }
    }
  }
  return '';
}
