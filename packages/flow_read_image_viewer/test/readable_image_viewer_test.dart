import 'dart:convert';

import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps desktop close button below the window controls area', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showReadableImageViewer(
                    context,
                    resource: ReadableImageResource.memory(_transparentGif),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final closeTop = tester.getTopLeft(find.byTooltip('关闭')).dy;
      expect(closeTop, greaterThanOrEqualTo(36));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

final Uint8List _transparentGif = Uint8List.fromList(
  base64Decode('R0lGODlhAQABAPAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw=='),
);
