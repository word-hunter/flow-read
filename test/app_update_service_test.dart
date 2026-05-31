import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flow_read/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._tempPath);

  final String _tempPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('flow_read_update_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
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

  group('downloadAndExtract', () {
    test('extracts zip containing .app and returns app path', () async {
      final zipBytes = _createAppZip();
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response.bytes(
            zipBytes,
            200,
            headers: {'content-type': 'application/zip'},
          );
        }),
        useNativeMacosArchiveExtractor: false,
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: 'FlowRead-macos-1.0.0.zip',
        downloadUrl: Uri.parse('https://example.com/FlowRead-macos-1.0.0.zip'),
      );

      final appPath = await service.downloadAndExtract(update);

      expect(appPath, endsWith('.app'));
      expect(File('$appPath/Contents/Info.plist').existsSync(), isTrue);
    });

    test('uses ditto for macOS app archive extraction', () async {
      final zipFile = File('${Directory.systemTemp.path}/flow_read_test.zip')
        ..writeAsBytesSync(_createAppZip());
      final extractDir = Directory.systemTemp.createTempSync(
        'flow_read_ditto_test_',
      );
      final calls = <({String executable, List<String> arguments})>[];
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response('', 200);
        }),
        useNativeMacosArchiveExtractor: true,
        processRunner: (executable, arguments) async {
          calls.add((executable: executable, arguments: arguments));
          final appDir = Directory('${extractDir.path}/FlowRead.app');
          appDir.createSync(recursive: true);
          File('${appDir.path}/Contents/Info.plist')
            ..createSync(recursive: true)
            ..writeAsStringSync('');
          File('${appDir.path}/Contents/MacOS/FlowRead')
            ..createSync(recursive: true)
            ..writeAsStringSync('hello')
            ..setLastModifiedSync(DateTime(2026, 1, 1));
          if (!Platform.isWindows) {
            await Process.run('chmod', [
              '755',
              '${appDir.path}/Contents/MacOS/FlowRead',
            ]);
          }
          return ProcessResult(1, 0, '', '');
        },
      );

      addTearDown(() {
        if (zipFile.existsSync()) zipFile.deleteSync();
        if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      });

      final appPath = await service.extractAndFindApp(zipFile, extractDir.path);

      expect(appPath, endsWith('FlowRead.app'));
      expect(calls, hasLength(1));
      expect(calls.single.executable, 'ditto');
      expect(calls.single.arguments, [
        '-x',
        '-k',
        zipFile.path,
        extractDir.path,
      ]);
    });

    test('throws when macOS archive extraction command fails', () async {
      final zipFile = File('${Directory.systemTemp.path}/flow_read_test.zip')
        ..writeAsBytesSync(_createAppZip());
      final extractDir = Directory.systemTemp.createTempSync(
        'flow_read_ditto_failure_test_',
      );
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response('', 200);
        }),
        useNativeMacosArchiveExtractor: true,
        processRunner: (_, _) async {
          return ProcessResult(1, 1, '', 'ditto failed');
        },
      );

      addTearDown(() {
        if (zipFile.existsSync()) zipFile.deleteSync();
        if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      });

      expect(
        service.extractAndFindApp(zipFile, extractDir.path),
        throwsA(
          isA<AppUpdateException>().having(
            (error) => error.message,
            'message',
            contains('ditto failed'),
          ),
        ),
      );
    });

    test(
      'preserves executable permissions inside extracted app bundle',
      () async {
        final zipBytes = _createAppZip(includeExecutable: true);
        final service = AppUpdateService(
          client: MockClient((_) async {
            return http.Response.bytes(zipBytes, 200);
          }),
          useNativeMacosArchiveExtractor: false,
        );

        final update = AppUpdateInfo(
          version: '1.0.1',
          tagName: 'v1.0.1',
          releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.1'),
          isPrerelease: false,
          publishedAt: DateTime(2026, 1, 1),
          releaseNotes: 'Test',
          assetName: 'FlowRead-macos-1.0.1.zip',
          downloadUrl: Uri.parse(
            'https://example.com/FlowRead-macos-1.0.1.zip',
          ),
        );

        final appPath = await service.downloadAndExtract(update);
        final executable = File('$appPath/Contents/MacOS/FlowRead');

        expect(executable.existsSync(), isTrue);
        expect(executable.statSync().mode & 0x40, isNot(0));
      },
    );

    test('throws when zip contains no .app bundle', () async {
      final zipBytes = _createNonAppZip();
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response.bytes(zipBytes, 200);
        }),
        useNativeMacosArchiveExtractor: false,
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: 'FlowRead-macos-1.0.0.zip',
        downloadUrl: Uri.parse('https://example.com/FlowRead-macos-1.0.0.zip'),
      );

      expect(
        service.downloadAndExtract(update),
        throwsA(
          isA<AppUpdateException>().having(
            (error) => error.message,
            'message',
            contains('未找到可安装的应用'),
          ),
        ),
      );
    });

    test('throws when app bundle has no launch executable', () async {
      final zipBytes = _createAppZip(includeExecutable: false);
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response.bytes(zipBytes, 200);
        }),
        useNativeMacosArchiveExtractor: false,
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: 'FlowRead-macos-1.0.0.zip',
        downloadUrl: Uri.parse('https://example.com/FlowRead-macos-1.0.0.zip'),
      );

      expect(
        service.downloadAndExtract(update),
        throwsA(
          isA<AppUpdateException>().having(
            (error) => error.message,
            'message',
            contains('未找到可安装的应用'),
          ),
        ),
      );
    });

    test('throws when downloadUrl is null', () async {
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response('', 200);
        }),
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: null,
        downloadUrl: null,
      );

      expect(
        service.downloadAndExtract(update),
        throwsA(
          isA<AppUpdateException>().having(
            (error) => error.message,
            'message',
            contains('没有可下载的资源文件'),
          ),
        ),
      );
    });

    test('calls onProgress with expected phases', () async {
      final zipBytes = _createAppZip();
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response.bytes(zipBytes, 200);
        }),
        useNativeMacosArchiveExtractor: false,
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: 'FlowRead-macos-1.0.0.zip',
        downloadUrl: Uri.parse('https://example.com/FlowRead-macos-1.0.0.zip'),
      );

      final phases = <AppUpdatePhase>[];
      final progressValues = <double>[];

      await service.downloadAndExtract(
        update,
        onProgress: (phase, progress) {
          phases.add(phase);
          progressValues.add(progress);
        },
      );

      expect(phases.length, greaterThanOrEqualTo(3));
      expect(phases, contains(AppUpdatePhase.downloading));
      expect(phases, contains(AppUpdatePhase.extracting));
      expect(phases, contains(AppUpdatePhase.complete));
      expect(progressValues.last, 1.0);
    });

    test('throws AppUpdateException on HTTP error', () async {
      final service = AppUpdateService(
        client: MockClient((_) async {
          return http.Response('Server Error', 500);
        }),
      );

      final update = AppUpdateInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        releasePageUrl: Uri.parse('https://github.com/test/releases/v1.0.0'),
        isPrerelease: false,
        publishedAt: DateTime(2026, 1, 1),
        releaseNotes: 'Test',
        assetName: 'FlowRead-macos-1.0.0.zip',
        downloadUrl: Uri.parse('https://example.com/FlowRead-macos-1.0.0.zip'),
      );

      expect(
        service.downloadAndExtract(update),
        throwsA(isA<AppUpdateException>()),
      );
    });
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

Uint8List _createAppZip({bool includeExecutable = true}) {
  final archive = Archive();
  final infoPlist = ArchiveFile(
    'FlowRead.app/Contents/Info.plist',
    0,
    Uint8List(0),
  );
  archive.addFile(infoPlist);
  if (includeExecutable) {
    final executable = ArchiveFile(
      'FlowRead.app/Contents/MacOS/FlowRead',
      5,
      'hello'.codeUnits,
    )..mode = 0x1ed;
    archive.addFile(executable);
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

Uint8List _createNonAppZip() {
  final archive = Archive();
  final textFile = ArchiveFile('random/notes.txt', 5, 'hello'.codeUnits);
  archive.addFile(textFile);
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}
