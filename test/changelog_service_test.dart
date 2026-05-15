import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/services/changelog_service.dart';

void main() {
  test('extracts release notes for a version', () {
    final notes = ChangelogService.parseForVersion('''
# Changelog

## [Unreleased]

## [1.2.3] - 2026-05-16

### Added

- GitHub release flow.
- Version dialog.

### Fixed

- Startup release note tracking.

## [1.2.2] - 2026-05-15

- Older release.
''', '1.2.3');

    expect(notes.version, '1.2.3');
    expect(notes.sections, hasLength(2));
    expect(notes.sections.first.title, '新增');
    expect(notes.sections.first.items, [
      'GitHub release flow.',
      'Version dialog.',
    ]);
    expect(notes.sections.last.title, '修复');
    expect(notes.sections.last.items.single, 'Startup release note tracking.');
  });

  test('returns empty notes when the version does not exist', () {
    final notes = ChangelogService.parseForVersion('''
# Changelog

## [Unreleased]
''', '9.9.9');

    expect(notes.isEmpty, isTrue);
  });
}
