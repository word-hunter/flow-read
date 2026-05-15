import 'package:flutter/services.dart';

import 'app_version.dart';

class ReleaseNotes {
  const ReleaseNotes({
    required this.version,
    required this.raw,
    required this.sections,
  });

  final String version;
  final String raw;
  final List<ReleaseNotesSection> sections;

  bool get isEmpty => raw.trim().isEmpty && sections.isEmpty;
}

class ReleaseNotesSection {
  const ReleaseNotesSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class ChangelogService {
  static Future<ReleaseNotes> loadCurrentReleaseNotes({
    AssetBundle? bundle,
  }) async {
    final changelogBundle = bundle ?? rootBundle;
    try {
      final changelog = await changelogBundle.loadString('CHANGELOG.md');
      return parseForVersion(changelog, FlowReadVersion.releaseName);
    } catch (_) {
      return ReleaseNotes(
        version: FlowReadVersion.releaseName,
        raw: '',
        sections: const [],
      );
    }
  }

  static ReleaseNotes parseForVersion(String changelog, String version) {
    final raw = extractVersionSection(changelog, version).trim();
    return ReleaseNotes(
      version: version,
      raw: raw,
      sections: _parseSections(raw),
    );
  }

  static String extractVersionSection(String changelog, String version) {
    final heading = RegExp(
      '^## \\[${RegExp.escape(version)}\\](?: - \\d{4}-\\d{2}-\\d{2})?[ \\t]*\\n',
      multiLine: true,
    );
    final match = heading.firstMatch(changelog);
    if (match == null) {
      return '';
    }

    final start = match.end;
    final nextHeading = RegExp(
      r'^## \[[^\]]+\]',
      multiLine: true,
    ).firstMatch(changelog.substring(start));
    final end = nextHeading == null
        ? changelog.length
        : start + nextHeading.start;
    return changelog.substring(start, end);
  }

  static String localizedSectionTitle(String title) {
    return switch (title.trim().toLowerCase()) {
      'added' => '新增',
      'changed' => '变更',
      'fixed' => '修复',
      'removed' => '移除',
      'deprecated' => '弃用',
      'security' => '安全',
      _ => title.trim(),
    };
  }

  static List<ReleaseNotesSection> _parseSections(String raw) {
    final sections = <ReleaseNotesSection>[];
    String currentTitle = '更新内容';
    var currentItems = <String>[];

    void flush() {
      if (currentItems.isEmpty) return;
      sections.add(
        ReleaseNotesSection(
          title: localizedSectionTitle(currentTitle),
          items: List.unmodifiable(currentItems),
        ),
      );
      currentItems = <String>[];
    }

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('### ')) {
        flush();
        currentTitle = trimmed.substring(4).trim();
        continue;
      }

      if (trimmed.startsWith('- ')) {
        currentItems.add(trimmed.substring(2).trim());
        continue;
      }

      currentItems.add(trimmed);
    }

    flush();
    return sections;
  }
}
