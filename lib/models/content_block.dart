import 'dart:typed_data';

sealed class CssLength {
  const CssLength();

  static CssLength? parse(String? value, {bool allowUnitlessPx = false}) {
    final text = value?.trim().toLowerCase();
    if (text == null || text.isEmpty) return null;
    if (text == 'auto') return const CssAuto();

    final match = RegExp(r'^(-?\d+(?:\.\d+)?)(px|%|em|rem)?$').firstMatch(text);
    if (match == null) return null;

    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null || !parsed.isFinite) return null;
    final unit = match.group(2);
    return switch (unit) {
      'px' => CssPx(parsed),
      '%' => CssPercent(parsed),
      'em' => CssEm(parsed),
      'rem' => CssRem(parsed),
      null when allowUnitlessPx => CssPx(parsed),
      _ => null,
    };
  }

  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  });
}

class CssPx extends CssLength {
  final double value;

  const CssPx(this.value);

  @override
  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  }) => value;
}

class CssPercent extends CssLength {
  final double value;

  const CssPercent(this.value);

  @override
  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  }) => percentBase * value / 100;
}

class CssEm extends CssLength {
  final double value;

  const CssEm(this.value);

  @override
  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  }) => fontSize * value;
}

class CssRem extends CssLength {
  final double value;

  const CssRem(this.value);

  @override
  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  }) => rootFontSize * value;
}

class CssAuto extends CssLength {
  const CssAuto();

  @override
  double? resolve({
    required double percentBase,
    required double fontSize,
    double rootFontSize = 16,
  }) => null;
}

enum ReaderTextAlign { start, center, end, justify }

class ReaderBlockStyle {
  final ReaderTextAlign? textAlign;
  final CssLength? marginTop;
  final CssLength? marginBottom;
  final CssLength? paddingLeft;
  final CssLength? paddingRight;
  final CssLength? textIndent;
  final double? fontSizeScale;
  final double? lineHeight;

  const ReaderBlockStyle({
    this.textAlign,
    this.marginTop,
    this.marginBottom,
    this.paddingLeft,
    this.paddingRight,
    this.textIndent,
    this.fontSizeScale,
    this.lineHeight,
  });

  ReaderBlockStyle merge(ReaderBlockStyle other) => ReaderBlockStyle(
    textAlign: other.textAlign ?? textAlign,
    marginTop: other.marginTop ?? marginTop,
    marginBottom: other.marginBottom ?? marginBottom,
    paddingLeft: other.paddingLeft ?? paddingLeft,
    paddingRight: other.paddingRight ?? paddingRight,
    textIndent: other.textIndent ?? textIndent,
    fontSizeScale: other.fontSizeScale ?? fontSizeScale,
    lineHeight: other.lineHeight ?? lineHeight,
  );

  static const none = ReaderBlockStyle();
}

class ImageStyleData {
  final CssLength? width;
  final CssLength? height;
  final CssLength? maxWidth;
  final CssLength? maxHeight;
  final CssLength? marginLeft;
  final CssLength? marginRight;
  final ReaderTextAlign? alignment;
  final bool? displayBlock;

  const ImageStyleData({
    this.width,
    this.height,
    this.maxWidth,
    this.maxHeight,
    this.marginLeft,
    this.marginRight,
    this.alignment,
    this.displayBlock,
  });

  ImageStyleData merge(ImageStyleData other) => ImageStyleData(
    width: other.width ?? width,
    height: other.height ?? height,
    maxWidth: other.maxWidth ?? maxWidth,
    maxHeight: other.maxHeight ?? maxHeight,
    marginLeft: other.marginLeft ?? marginLeft,
    marginRight: other.marginRight ?? marginRight,
    alignment: other.alignment ?? alignment,
    displayBlock: other.displayBlock ?? displayBlock,
  );

  static const none = ImageStyleData();
}

class InlineStyle {
  final bool bold;
  final bool italic;

  const InlineStyle({this.bold = false, this.italic = false});

  InlineStyle merge(InlineStyle other) =>
      InlineStyle(bold: bold || other.bold, italic: italic || other.italic);

  static const normal = InlineStyle();
}

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
