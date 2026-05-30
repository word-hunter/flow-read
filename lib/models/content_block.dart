import 'dart:typed_data';

import 'package:epub_reader_core/epub_reader_core.dart'
    show ImageStyleData, InlineStyle, ReaderBlockStyle;

export 'package:epub_reader_core/epub_reader_core.dart'
    show
        CssAuto,
        CssEm,
        CssLength,
        CssPercent,
        CssPx,
        CssRem,
        ImageStyleData,
        InlineStyle,
        ReaderBlockStyle,
        ReaderTextAlign;

class StyledText {
  final String text;
  final InlineStyle style;

  const StyledText(this.text, [this.style = InlineStyle.normal]);
}

enum BlockType { paragraph, heading, listItem, blockquote }

sealed class ContentBlock {}

class TextBlock extends ContentBlock {
  final BlockType type;
  final int headingLevel;
  final List<StyledText> spans;
  final int indent;
  final ReaderBlockStyle style;

  TextBlock({
    required this.type,
    this.headingLevel = 0,
    required this.spans,
    this.indent = 0,
    this.style = ReaderBlockStyle.none,
  });

  String get plainText => spans.map((s) => s.text).join();
}

class ImageBlock extends ContentBlock {
  final String src;
  final String? alt;
  final Uint8List? bytes;
  final double? declaredWidth;
  final double? declaredHeight;
  final double? naturalWidth;
  final double? naturalHeight;
  final ImageStyleData style;
  final String? caption;

  ImageBlock({
    required this.src,
    this.alt,
    this.bytes,
    int? width,
    int? height,
    this.declaredWidth,
    this.declaredHeight,
    double? naturalWidth,
    double? naturalHeight,
    this.style = ImageStyleData.none,
    this.caption,
  }) : naturalWidth = naturalWidth ?? width?.toDouble(),
       naturalHeight = naturalHeight ?? height?.toDouble();

  int? get width => (declaredWidth ?? naturalWidth)?.round();

  int? get height => (declaredHeight ?? naturalHeight)?.round();

  double? get aspectRatio {
    final imageWidth = naturalWidth ?? declaredWidth;
    final imageHeight = naturalHeight ?? declaredHeight;
    if (imageWidth == null || imageHeight == null || imageHeight <= 0) {
      return null;
    }
    return imageWidth / imageHeight;
  }
}
