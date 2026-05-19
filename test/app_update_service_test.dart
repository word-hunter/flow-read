import 'dart:convert';

import 'package:flow_read/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('finds newer matching prerelease with macOS zip asset', () async {
    final service = AppUpdateService(
      client: MockClient((request) async {
        expect(request.url.path, '/repos/word-hunter/flow-read/releases');
        return http.Response(
          jsonEncode([
            _release(
              tagName: 'v0.0.2-alpha',
              prerelease: true,
              assetName: 'flow_read-macos-0.0.2-alpha.zip',
              downloadUrl:
                  'https://github.com/word-hunter/flow-read/releases/download/v0.0.2-alpha/flow_read-macos-0.0.2-alpha.zip',
            ),
          ]),
          200,
        );
      }),
    );

    final update = await service.checkForUpdate(
      currentReleaseName: '0.0.1-alpha',
      currentChannel: 'alpha',
    );

    expect(update, isNotNull);
    expect(update!.version, '0.0.2-alpha');
    expect(update.tagName, 'v0.0.2-alpha');
    expect(update.assetName, 'flow_read-macos-0.0.2-alpha.zip');
    expect(update.hasDownloadAsset, isTrue);
  });

  test('ignores unrelated prerelease channel', () async {
    final service = AppUpdateService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode([
            _release(tagName: 'v0.0.9-beta', prerelease: true),
            _release(tagName: 'v0.0.2-alpha', prerelease: true),
          ]),
          200,
        );
      }),
    );

    final update = await service.checkForUpdate(
      currentReleaseName: '0.0.1-alpha',
      currentChannel: 'alpha',
    );

    expect(update?.version, '0.0.2-alpha');
  });

  test('stable channel ignores prereleases', () async {
    final service = AppUpdateService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode([
            _release(tagName: 'v0.0.2-alpha', prerelease: true),
            _release(tagName: 'v0.0.3', prerelease: true),
            _release(tagName: 'v0.0.1', prerelease: false),
          ]),
          200,
        );
      }),
    );

    final update = await service.checkForUpdate(
      currentReleaseName: '0.0.1',
      currentChannel: 'stable',
    );

    expect(update, isNull);
  });

  test('returns null when there is no newer release', () async {
    final service = AppUpdateService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode([
            _release(tagName: 'v0.0.1-alpha', prerelease: true),
            _release(tagName: 'v0.0.0-alpha', prerelease: true),
          ]),
          200,
        );
      }),
    );

    final update = await service.checkForUpdate(
      currentReleaseName: '0.0.1-alpha',
      currentChannel: 'alpha',
    );

    expect(update, isNull);
  });

  test('throws readable message for GitHub errors', () async {
    final service = AppUpdateService(
      client: MockClient((_) async {
        return http.Response(jsonEncode({'message': 'rate limit'}), 403);
      }),
    );

    expect(
      service.checkForUpdate(
        currentReleaseName: '0.0.1-alpha',
        currentChannel: 'alpha',
      ),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.message,
          'message',
          contains('rate limit'),
        ),
      ),
    );
  });

  test('explains private release repository on 404', () async {
    final service = AppUpdateService(
      client: MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      }),
    );

    expect(
      service.checkForUpdate(
        currentReleaseName: '0.0.1-alpha',
        currentChannel: 'alpha',
      ),
      throwsA(
        isA<AppUpdateException>()
            .having((error) => error.message, 'message', contains('私有'))
            .having(
              (error) => error.actionUrl.toString(),
              'actionUrl',
              'https://github.com/word-hunter/flow-read/releases',
            ),
      ),
    );
  });
}

Map<String, dynamic> _release({
  required String tagName,
  required bool prerelease,
  String assetName = 'flow_read-macos.zip',
  String downloadUrl = 'https://example.com/flow_read-macos.zip',
}) {
  final version = tagName.replaceFirst(RegExp(r'^v'), '');
  return {
    'tag_name': tagName,
    'name': 'Flow Read $version',
    'html_url':
        'https://github.com/word-hunter/flow-read/releases/tag/$tagName',
    'draft': false,
    'prerelease': prerelease,
    'published_at': '2026-05-19T00:00:00Z',
    'body': '### Fixed\n\n- Test update.',
    'assets': [
      {'name': assetName, 'browser_download_url': downloadUrl},
    ],
  };
}
