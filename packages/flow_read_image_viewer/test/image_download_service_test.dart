import 'dart:typed_data';

import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';
import 'package:flow_read_image_viewer/src/image_download_service.dart'
    show suggestedImageFileName;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves memory image bytes with inferred file name', () async {
    Uint8List? savedBytes;
    String? savedFileName;
    final service = ReadableImageDownloadService(
      saveBytes: ({required fileName, required bytes}) async {
        savedFileName = fileName;
        savedBytes = bytes;
        return '/tmp/$fileName';
      },
    );
    final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);

    final outcome = await service.save(
      ReadableImageResource.memory(bytes, source: '../Images/map.gif#cover'),
    );

    expect(outcome.canceled, isFalse);
    expect(outcome.path, '/tmp/map.gif');
    expect(savedFileName, 'map.gif');
    expect(savedBytes, bytes);
  });

  test('downloads network image before saving', () async {
    final fetchedBytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    Uri? fetchedUri;
    Uint8List? savedBytes;
    final service = ReadableImageDownloadService(
      fetchBytes: (uri) async {
        fetchedUri = uri;
        return fetchedBytes;
      },
      saveBytes: ({required fileName, required bytes}) async {
        savedBytes = bytes;
        return '/tmp/$fileName';
      },
    );

    final outcome = await service.save(
      ReadableImageResource.network(
        Uri.parse('https://example.com/assets/cover'),
      ),
    );

    expect(fetchedUri, Uri.parse('https://example.com/assets/cover'));
    expect(savedBytes, fetchedBytes);
    expect(outcome.path, '/tmp/cover.png');
  });

  test('reports canceled save without throwing', () async {
    final service = ReadableImageDownloadService(
      saveBytes: ({required fileName, required bytes}) async => null,
    );

    final outcome = await service.save(
      ReadableImageResource.memory(Uint8List.fromList([1, 2, 3])),
    );

    expect(outcome.canceled, isTrue);
    expect(outcome.path, isNull);
  });

  test('sanitizes unsafe suggested file names', () {
    final name = suggestedImageFileName(
      ReadableImageResource.memory(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        suggestedFileName: 'bad/name:*',
      ),
      Uint8List.fromList([0xFF, 0xD8, 0xFF]),
    );

    expect(name, 'bad-name--.jpg');
  });
}
