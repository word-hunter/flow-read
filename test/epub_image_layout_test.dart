import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/widgets/reader/epub_image_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const contentWidth = 240.0;
  const naturalSize = Size(800, 400);

  test('resolves width 100 percent to content width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: const CssPercent(100),
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 240);
    expect(layout.height, 120);
  });

  test('resolves width 50 percent against content width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: const CssPercent(50),
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 120);
    expect(layout.height, 60);
  });

  test('clamps css pixel width to content width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: const CssPx(300),
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 240);
    expect(layout.height, 120);
  });

  test('keeps natural size when it is smaller than content width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: const Size(120, 60),
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: null,
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 120);
    expect(layout.height, 60);
  });

  test('scales natural size down when it is wider than content width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: null,
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 240);
    expect(layout.height, 120);
  });

  test('keeps natural aspect ratio when declared dimensions conflict', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: 200,
      declaredHeight: 200,
      cssWidth: null,
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 200);
    expect(layout.height, 100);
  });

  test('uses content width and automatic height without natural size', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: null,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: null,
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
    );

    expect(layout.width, 240);
    expect(layout.height, isNull);
  });

  test('applies maxImageWidthRatio after resolving width', () {
    final layout = resolveImageLayout(
      contentWidth: contentWidth,
      naturalSize: naturalSize,
      declaredWidth: null,
      declaredHeight: null,
      cssWidth: null,
      cssHeight: null,
      cssMaxWidth: null,
      cssMaxHeight: null,
      maxImageWidthRatio: 0.8,
    );

    expect(layout.width, 192);
    expect(layout.height, 96);
  });
}
