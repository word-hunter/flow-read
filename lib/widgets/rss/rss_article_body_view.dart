import 'package:flutter/material.dart';
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';
import 'package:provider/provider.dart';

import '../../models/analysis_result.dart';
import '../../models/rss_models.dart';
import '../../providers/reading_provider.dart';
import '../../services/analysis_service.dart';
import '../../services/settings_service.dart';
import '../reader_text_view.dart';
import '../word_bottom_sheet.dart';

enum RssArticleBodyMode { preview, detail }

class RssArticleBodyView extends StatelessWidget {
  final RssArticle article;
  final String searchQuery;
  final RssArticleBodyMode mode;
  final double maxImageHeight;
  final double maxImageWidth;

  const RssArticleBodyView({
    super.key,
    required this.article,
    this.searchQuery = '',
    this.mode = RssArticleBodyMode.preview,
    this.maxImageHeight = 320,
    this.maxImageWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyBlocks = article.bodyBlocks;
    final text =
        (article.content?.isNotEmpty == true
                ? article.content
                : article.description)
            ?.trim();
    final hasBodyBlocks = bodyBlocks.isNotEmpty;
    if (!hasBodyBlocks &&
        (text == null || text.isEmpty) &&
        article.images.isEmpty) {
      return const SizedBox.shrink();
    }

    if ((text == null || text.isEmpty) &&
        bodyBlocks.whereType<RssArticleTextBlock>().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildImageOnlyBody(article, bodyBlocks),
      );
    }

    final bodyText = text ?? _textFromBodyBlocks(bodyBlocks) ?? '';
    final readingProvider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();
    final result = AnalysisService.analyzeChapter(
      article.title,
      bodyText,
      readingProvider.userVocabulary,
      readingProvider.wordLevelService,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBodyBlocks)
          ..._buildBodyBlockWidgets(
            context,
            bodyBlocks,
            result,
            theme,
            readingProvider,
            settings,
          )
        else
          _buildTextBlock(
            context,
            RssArticleTextBlock(
              type: RssArticleTextBlockType.paragraph,
              text: bodyText,
            ),
            result,
            theme,
            readingProvider,
            settings,
          ),
        ..._buildTrailingImages(article, bodyBlocks),
      ],
    );
  }

  List<Widget> _buildBodyBlockWidgets(
    BuildContext context,
    List<RssArticleBodyBlock> bodyBlocks,
    AnalysisResult result,
    ThemeData theme,
    ReadingProvider readingProvider,
    SettingsService settings,
  ) {
    return bodyBlocks
        .map((block) {
          return switch (block) {
            RssArticleTextBlock() => _buildTextBlock(
              context,
              block,
              result,
              theme,
              readingProvider,
              settings,
            ),
            RssArticleImageBlock() => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArticleImage(block.image),
            ),
          };
        })
        .toList(growable: false);
  }

  String? _textFromBodyBlocks(List<RssArticleBodyBlock> bodyBlocks) {
    final parts = bodyBlocks
        .whereType<RssArticleTextBlock>()
        .map((block) => block.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  Widget _buildTextBlock(
    BuildContext context,
    RssArticleTextBlock block,
    AnalysisResult result,
    ThemeData theme,
    ReadingProvider readingProvider,
    SettingsService settings,
  ) {
    final style = _rssTextStyle(block, theme);
    final richText = Text.rich(
      buildHighlightedParagraph(
            block.text,
            result,
            theme,
            onWordTapped:
                (word, contextText, {contextWordStart, contextWordEnd}) {
                  _showWordSheet(
                    context,
                    word,
                    contextText,
                    contextWordStart: contextWordStart,
                    contextWordEnd: contextWordEnd,
                  );
                },
            fontSize: style.fontSize ?? 14,
            lineHeight: _rssLineHeight(block),
            fontFamily: style.fontFamily ?? 'Serif',
            baseTextColor: style.color,
            colorSettings: settings.colors,
            searchQuery: searchQuery,
            lookupHighlightWord: readingProvider.selectedWord,
            wordLevelService: readingProvider.wordLevelService,
          )
          as TextSpan,
      style: style,
    );

    final content = switch (block.type) {
      RssArticleTextBlockType.listItem => Padding(
        padding: EdgeInsets.only(left: (block.indent - 1).clamp(0, 4) * 18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 8),
              child: Text(
                '•',
                style: style.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: richText),
          ],
        ),
      ),
      RssArticleTextBlockType.blockquote => Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outlineVariant, width: 3),
          ),
        ),
        child: richText,
      ),
      _ => richText,
    };

    return Padding(padding: _rssBlockPadding(block), child: content);
  }

  TextStyle _rssTextStyle(RssArticleTextBlock block, ThemeData theme) {
    final color = block.type == RssArticleTextBlockType.blockquote
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final fontSize = switch (block.type) {
      RssArticleTextBlockType.heading => switch (block.headingLevel) {
        1 => mode == RssArticleBodyMode.detail ? 24.0 : 17.0,
        2 => mode == RssArticleBodyMode.detail ? 21.0 : 16.0,
        3 => mode == RssArticleBodyMode.detail ? 18.0 : 15.0,
        _ => mode == RssArticleBodyMode.detail ? 17.0 : 14.5,
      },
      _ => mode == RssArticleBodyMode.detail ? 16.0 : 14.0,
    };
    return base.copyWith(
      height: _rssLineHeight(block),
      fontFamily: 'Serif',
      fontSize: fontSize,
      fontWeight: block.type == RssArticleTextBlockType.heading
          ? FontWeight.w700
          : null,
      fontStyle: block.type == RssArticleTextBlockType.blockquote
          ? FontStyle.italic
          : null,
      color: color,
    );
  }

  double _rssLineHeight(RssArticleTextBlock block) {
    if (block.type == RssArticleTextBlockType.heading) {
      return mode == RssArticleBodyMode.detail ? 1.3 : 1.35;
    }
    return mode == RssArticleBodyMode.detail ? 1.75 : 1.7;
  }

  EdgeInsets _rssBlockPadding(RssArticleTextBlock block) {
    final bottom = mode == RssArticleBodyMode.detail ? 14.0 : 10.0;
    return switch (block.type) {
      RssArticleTextBlockType.heading => EdgeInsets.only(
        top: mode == RssArticleBodyMode.detail ? 12 : 4,
        bottom: mode == RssArticleBodyMode.detail ? 12 : 8,
      ),
      RssArticleTextBlockType.listItem => EdgeInsets.only(
        bottom: mode == RssArticleBodyMode.detail ? 9 : 6,
      ),
      _ => EdgeInsets.only(bottom: bottom),
    };
  }

  List<Widget> _buildImageOnlyBody(
    RssArticle article,
    List<RssArticleBodyBlock> bodyBlocks,
  ) {
    return [
      ...bodyBlocks.whereType<RssArticleImageBlock>().map(
        (block) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildArticleImage(block.image),
        ),
      ),
      ..._buildTrailingImages(article, bodyBlocks),
    ];
  }

  List<Widget> _buildTrailingImages(
    RssArticle article,
    List<RssArticleBodyBlock> bodyBlocks,
  ) {
    final inlineUrls = bodyBlocks
        .whereType<RssArticleImageBlock>()
        .map((block) => block.image.url)
        .toSet();
    return article.images
        .where((image) => !inlineUrls.contains(image.url))
        .map(
          (image) => Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: _buildArticleImage(image),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildArticleImage(RssArticleImage image) {
    final uri = Uri.tryParse(image.url);
    if (uri == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: ReadableImagePreview(
        resource: ReadableImageResource.network(
          uri,
          alt: image.alt,
          suggestedFileName: uri.pathSegments
              .where((segment) => segment.trim().isNotEmpty)
              .lastOrNull,
          width: image.width?.toDouble(),
          height: image.height?.toDouble(),
        ),
        maxHeight: maxImageHeight,
        maxWidth: maxImageWidth,
      ),
    );
  }

  void _showWordSheet(
    BuildContext context,
    String word,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    final provider = context.read<ReadingProvider>();
    provider.lookupWord(
      word,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordBottomSheet(word: word),
    ).whenComplete(provider.clearWordLookup);
  }
}
