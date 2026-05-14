import 'content_block.dart';

class Chapter {
  final String title;
  final String plainText;
  final String rawHtml;
  final List<ContentBlock> blocks;

  const Chapter({
    required this.title,
    required this.plainText,
    required this.rawHtml,
    this.blocks = const [],
  });
}
