import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flow_read_image_viewer/flow_read_image_viewer.dart';

import '../../models/analysis_result.dart';
import '../../models/reading_memory.dart';
import 'package:flow_rss/flow_rss.dart';
import '../../providers/reading/services_provider.dart';
import '../../providers/reading/text_selection_notifier.dart';
import '../../providers/reading/vocabulary_notifier.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import '../../providers/settings_provider.dart';
import '../../services/analysis_service.dart';
import '../../services/app_logger.dart';
import 'package:flow_language/flow_language.dart';
import '../../services/reading_memory/reading_memory_ids.dart';
import '../../services/settings_service.dart';
import '../../services/word_level_service.dart';
import '../flow/flow_components.dart';
import '../reader_text_view.dart';
import '../selected_text_action_toolbar.dart';
import '../selected_text_sheet.dart';
import '../word_bottom_sheet.dart';

enum RssArticleBodyMode { preview, detail, intensive }

class RssArticleBodyView extends riverpod.ConsumerWidget {
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
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
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
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    final vocNotifier = ref.read(vocabularyNotifierProvider.notifier);
    final wordLevelService = ref.read(wordLevelServiceProvider);
    final settings = ref.watch(settingsProvider);
    final result = _analyzeArticleBody(vocNotifier, bodyText, wordLevelService);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBodyBlocks)
          ..._buildBodyBlockWidgets(
            context,
            bodyBlocks,
            result,
            theme,
            lookupState,
            lookupNotifier,
            vocNotifier.activeLanguageModule,
            wordLevelService,
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
            lookupState,
            lookupNotifier,
            vocNotifier.activeLanguageModule,
            wordLevelService,
            settings,
          ),
        ..._buildTrailingImages(article, bodyBlocks),
      ],
    );

    if (mode != RssArticleBodyMode.intensive) {
      return content;
    }

    return SelectedTextActionRegion(
      actionsBuilder: (context, selectedText, closeToolbar) => [
        SelectedTextAction.copy(
          context: context,
          selectedText: selectedText,
          closeToolbar: closeToolbar,
        ),
        SelectedTextAction(
          icon: Icons.segment_outlined,
          tooltip: '解析选中内容',
          enabled: selectedText.trim().isNotEmpty,
          onPressed: () {
            closeToolbar();
            _showSelectedTextSheet(context, ref, selectedText);
          },
        ),
      ],
      child: content,
    );
  }

  AnalysisResult? _analyzeArticleBody(
    VocabularyNotifier vocNotifier,
    String bodyText,
    WordLevelService wordLevelService,
  ) {
    try {
      return AnalysisService.analyzeChapter(
        article.title,
        bodyText,
        vocNotifier.userVocabulary,
        wordLevelService,
        vocNotifier.activeLanguageModule,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.event(
        'rss.article_body_analysis_failed',
        level: AppLogLevel.warning,
        source: 'rss_article_body_view',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<Widget> _buildBodyBlockWidgets(
    BuildContext context,
    List<RssArticleBodyBlock> bodyBlocks,
    AnalysisResult? result,
    ThemeData theme,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    LanguageModule activeLanguageModule,
    WordLevelService wordLevelService,
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
              lookupState,
              lookupNotifier,
              activeLanguageModule,
              wordLevelService,
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
    AnalysisResult? result,
    ThemeData theme,
    WordLookupState lookupState,
    WordLookupNotifier lookupNotifier,
    LanguageModule activeLanguageModule,
    WordLevelService wordLevelService,
    SettingsService settings,
  ) {
    final style = _rssTextStyle(block, theme);
    final richText = result == null
        ? Text(block.text, style: style)
        : Text.rich(
            buildHighlightedParagraph(
                  block.text,
                  result,
                  theme,
                  onWordTapped:
                      (
                        surface,
                        canonical,
                        languageId,
                        contextText, {
                        contextWordStart,
                        contextWordEnd,
                      }) {
                        _showWordSheet(
                          context,
                          lookupNotifier,
                          surface,
                          canonical,
                          languageId,
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
                  lookupHighlightWord: lookupState.selectedWord,
                  wordLevelService: wordLevelService,
                  languageModule: activeLanguageModule,
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
        1 => switch (mode) {
          RssArticleBodyMode.intensive => 25.0,
          RssArticleBodyMode.detail => 24.0,
          RssArticleBodyMode.preview => 17.0,
        },
        2 => switch (mode) {
          RssArticleBodyMode.intensive => 22.0,
          RssArticleBodyMode.detail => 21.0,
          RssArticleBodyMode.preview => 16.0,
        },
        3 => switch (mode) {
          RssArticleBodyMode.intensive => 19.0,
          RssArticleBodyMode.detail => 18.0,
          RssArticleBodyMode.preview => 15.0,
        },
        _ => switch (mode) {
          RssArticleBodyMode.intensive => 18.0,
          RssArticleBodyMode.detail => 17.0,
          RssArticleBodyMode.preview => 14.5,
        },
      },
      _ => switch (mode) {
        RssArticleBodyMode.intensive => 18.0,
        RssArticleBodyMode.detail => 16.0,
        RssArticleBodyMode.preview => 14.0,
      },
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
      return switch (mode) {
        RssArticleBodyMode.intensive => 1.38,
        RssArticleBodyMode.detail => 1.3,
        RssArticleBodyMode.preview => 1.35,
      };
    }
    return switch (mode) {
      RssArticleBodyMode.intensive => 2.0,
      RssArticleBodyMode.detail => 1.75,
      RssArticleBodyMode.preview => 1.7,
    };
  }

  EdgeInsets _rssBlockPadding(RssArticleTextBlock block) {
    final bottom = switch (mode) {
      RssArticleBodyMode.intensive => 18.0,
      RssArticleBodyMode.detail => 14.0,
      RssArticleBodyMode.preview => 10.0,
    };
    return switch (block.type) {
      RssArticleTextBlockType.heading => EdgeInsets.only(
        top: mode == RssArticleBodyMode.preview ? 4 : 12,
        bottom: mode == RssArticleBodyMode.intensive ? 14 : 8,
      ),
      RssArticleTextBlockType.listItem => EdgeInsets.only(
        bottom: mode == RssArticleBodyMode.intensive
            ? 12
            : mode == RssArticleBodyMode.detail
            ? 9
            : 6,
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
    WordLookupNotifier lookupNotifier,
    String word,
    String canonical,
    String languageId,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    lookupNotifier.lookupWord(
      word,
      canonicalForm: canonical,
      languageCode: languageId,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
      memorySourceRef: MemorySourceRef(
        sourceId: ReadingMemoryIds.source(SourceKind.rss, article.id),
        sourceKind: SourceKind.rss,
        sourceTitleSnapshot: article.title,
        locationLocator: article.link,
      ),
    );
    showFlowSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordBottomSheet(word: word),
    ).whenComplete(lookupNotifier.clearWordLookup);
  }

  void _showSelectedTextSheet(
    BuildContext context,
    riverpod.WidgetRef ref,
    String text,
  ) {
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;
    final notifier = ref.read(textSelectionNotifierProvider.notifier);
    notifier.analyzeSelectedText(selectedText);
    final state = ref.watch(textSelectionNotifierProvider);
    showFlowSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SelectedTextSheet(
        selectedText: selectedText,
        analysis: state.selectedAnalysis,
        breakdowns: state.selectedBreakdowns,
        memorySourceRef: MemorySourceRef(
          sourceId: ReadingMemoryIds.source(SourceKind.rss, article.id),
          sourceKind: SourceKind.rss,
          sourceTitleSnapshot: article.title,
          locationLocator: article.link,
        ),
      ),
    );
  }
}
