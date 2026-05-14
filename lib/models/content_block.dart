import 'dart:typed_data';

class InlineStyle {
  final bool bold;
  final bool italic;

  const InlineStyle({this.bold = false, this.italic = false});

  InlineStyle merge(InlineStyle other) => InlineStyle(
        bold: bold || other.bold,
        italic: italic || other.italic,
      );

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

  TextBlock({
    required this.type,
    this.headingLevel = 0,
    required this.spans,
    this.indent = 0,
  });

  String get plainText => spans.map((s) => s.text).join();
}

class ImageBlock extends ContentBlock {
  final String src;
  final String? alt;
  final Uint8List? bytes;

  ImageBlock({required this.src, this.alt, this.bytes});
}
