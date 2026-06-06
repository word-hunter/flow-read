import 'package:flutter/material.dart';

import '../../models/analysis_result.dart';
import '../../models/content_block.dart';
import '../../providers/reading/current_book_provider.dart';
import '../../providers/reading/reading_config_provider.dart';
import '../../providers/reading/reading_search_provider.dart';
import '../../providers/reading/word_lookup_provider.dart';
import '../../services/settings_service.dart' show VocabularyColorSettings;
import '../reader_text_view.dart';
import '../selected_text_action_toolbar.dart';

class ReaderContentView extends StatelessWidget {
  final List<String> paragraphs;
  final List<ContentBlock> blocks;
  final AnalysisResult result;
  final ThemeData theme;
  final VocabularyColorSettings colorSettings;
  final bool aiFeaturesEnabled;
  final CurrentBookController currentBook;
  final ReadingConfigController config;
  final ReadingSearchFacade search;
  final WordLookupController lookup;
  final ScrollController scrollController;
  final bool isWideScreen;
  final bool sidebarOpen;
  final bool isSearchPanelVisible;
  final GlobalKey Function(int index) contentKeyFor;
  final ValueChanged<int> onVisibleContentCountChanged;
  final WordTapCallback onWordTapped;
  final ValueChanged<String> onAnalyzeSelected;

  const ReaderContentView({
    super.key,
    required this.paragraphs,
    required this.blocks,
    required this.result,
    required this.theme,
    required this.colorSettings,
    required this.aiFeaturesEnabled,
    required this.currentBook,
    required this.config,
    required this.search,
    required this.lookup,
    required this.scrollController,
    required this.isWideScreen,
    required this.sidebarOpen,
    required this.isSearchPanelVisible,
    required this.contentKeyFor,
    required this.onVisibleContentCountChanged,
    required this.onWordTapped,
    required this.onAnalyzeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SelectedTextActionRegion(
      actionsBuilder: (context, selectedText, closeToolbar) =>
          _buildSelectedTextActions(
            context,
            selectedText,
            closeToolbar,
            aiFeaturesEnabled: aiFeaturesEnabled,
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTitleBlock = !currentBook.hasBook;
          final topPadding = showTitleBlock ? 14.0 : 10.0;
          final wide = isWideScreen;
          final compactWide = wide && constraints.maxWidth < 760;
          final leftPadding = wide ? (compactWide ? 48.0 : 80.0) : 18.0;
          final rightPadding = wide
              ? (sidebarOpen ? (compactWide ? 24.0 : 40.0) : leftPadding)
              : 18.0;
          final maxTextWidth = wide ? 720.0 : double.infinity;
          final maxFrameWidth = wide
              ? maxTextWidth + leftPadding + rightPadding
              : double.infinity;
          final useBlocks = blocks.isNotEmpty;
          final contentCount = useBlocks ? blocks.length : paragraphs.length;
          onVisibleContentCountChanged(contentCount);

          return Align(
            alignment: wide && sidebarOpen
                ? Alignment.topLeft
                : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFrameWidth),
              child: SingleChildScrollView(
                key: const ValueKey('reader-scroll-view'),
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  topPadding,
                  rightPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showTitleBlock) _buildTitleBlock(result, theme, config),
                    for (
                      var contentIndex = 0;
                      contentIndex < contentCount;
                      contentIndex += 1
                    )
                      KeyedSubtree(
                        key: contentKeyFor(contentIndex),
                        child: useBlocks
                            ? _buildContentBlock(
                                blocks[contentIndex],
                                isFirstBlock:
                                    contentIndex == 0 && currentBook.hasBook,
                              )
                            : _buildParagraph(
                                paragraphs[contentIndex],
                                isFirstParagraph:
                                    contentIndex == 0 && currentBook.hasBook,
                              ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<SelectedTextAction> _buildSelectedTextActions(
    BuildContext context,
    String selectedText,
    VoidCallback closeToolbar, {
    required bool aiFeaturesEnabled,
  }) {
    return [
      SelectedTextAction.copy(
        context: context,
        selectedText: selectedText,
        closeToolbar: closeToolbar,
      ),
      SelectedTextAction(
        icon: Icons.auto_awesome_rounded,
        tooltip: 'AI 解析',
        enabled: aiFeaturesEnabled && selectedText.trim().isNotEmpty,
        onPressed: () {
          closeToolbar();
          onAnalyzeSelected(selectedText);
        },
      ),
    ];
  }

  Widget _buildContentBlock(
    ContentBlock block, {
    bool isFirstBlock = false,
  }) {
    final searchQuery = _effectiveHighlightQuery(search);
    final lookupHighlightWord = lookup.selectedWord;
    final hasLookupHighlight =
        lookupHighlightWord != null && lookupHighlightWord.trim().isNotEmpty;

    if (isFirstBlock &&
        searchQuery.isEmpty &&
        !hasLookupHighlight &&
        block is TextBlock &&
        block.type == BlockType.paragraph &&
        block.plainText.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(
          block.plainText,
          _buildBaseTextStyle(theme, config),
        ),
      );
    }

    return buildBlockWidget(
      block,
      result,
      theme,
      onWordTapped: onWordTapped,
      fontSize: config.fontSize,
      lineHeight: config.lineHeight,
      fontFamily: config.fontFamily,
      baseTextColor: _readerTextColor(config),
      mutedTextColor: _readerMutedTextColor(config),
      colorSettings: colorSettings,
      searchQuery: searchQuery,
      lookupHighlightWord: lookupHighlightWord,
      wordLevelService: lookup.wordLevelService,
      languageModule: lookup.activeLanguageModule,
    );
  }

  String _effectiveHighlightQuery(ReadingSearchFacade search) {
    return isSearchPanelVisible ? search.query : search.sourceHighlightQuery;
  }

  Widget _buildTitleBlock(
    AnalysisResult result,
    ThemeData theme,
    ReadingConfigController config,
  ) {
    final titleColor = _readerTextColor(config);
    final dividerColor = _isDarkReadingTheme(config)
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFEEEEEE);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
              fontFamily: config.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildParagraph(
    String paragraph, {
    bool isFirstParagraph = false,
  }) {
    final baseStyle = _buildBaseTextStyle(theme, config);
    final searchQuery = _effectiveHighlightQuery(search);
    final lookupHighlightWord = lookup.selectedWord;
    final hasLookupHighlight =
        lookupHighlightWord != null && lookupHighlightWord.trim().isNotEmpty;

    if (isFirstParagraph &&
        paragraph.isNotEmpty &&
        searchQuery.isEmpty &&
        !hasLookupHighlight) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildDropCapParagraph(paragraph, baseStyle),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        buildHighlightedParagraph(
          paragraph,
          result,
          theme,
          onWordTapped: onWordTapped,
          fontSize: config.fontSize,
          lineHeight: config.lineHeight,
          fontFamily: config.fontFamily,
          baseTextColor: _readerTextColor(config),
          colorSettings: colorSettings,
          searchQuery: searchQuery,
          lookupHighlightWord: lookupHighlightWord,
          wordLevelService: lookup.wordLevelService,
          languageModule: lookup.activeLanguageModule,
        ),
        style: baseStyle,
      ),
    );
  }

  Widget _buildDropCapParagraph(String paragraph, TextStyle baseStyle) {
    final firstLetter = paragraph.substring(0, 1).toUpperCase();
    final restText = paragraph.substring(1).trimLeft();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 5),
          child: Text(
            firstLetter,
            style: baseStyle.copyWith(
              fontSize: config.fontSize * 3.05,
              height: 0.84,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            buildHighlightedParagraph(
              restText,
              result,
              theme,
              onWordTapped: onWordTapped,
              fontSize: config.fontSize,
              lineHeight: config.lineHeight,
              fontFamily: config.fontFamily,
              baseTextColor: _readerTextColor(config),
              colorSettings: colorSettings,
              lookupHighlightWord: lookup.selectedWord,
              wordLevelService: lookup.wordLevelService,
              languageModule: lookup.activeLanguageModule,
            ),
            style: baseStyle,
          ),
        ),
      ],
    );
  }
}

Color _readerTextColor(ReadingConfigController config) {
  switch (config.readingTheme) {
    case 'dark':
      return const Color(0xFFE8E2D6);
    case 'sepia':
      return const Color(0xFF30281F);
    default:
      return const Color(0xFF20231F);
  }
}

Color _readerMutedTextColor(ReadingConfigController config) {
  switch (config.readingTheme) {
    case 'dark':
      return const Color(0xFFC8C1B7);
    case 'sepia':
      return const Color(0xFF6F6251);
    default:
      return const Color(0xFF626960);
  }
}

bool _isDarkReadingTheme(ReadingConfigController config) {
  return config.readingTheme == 'dark';
}

TextStyle _buildBaseTextStyle(
  ThemeData theme,
  ReadingConfigController config,
) {
  return (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
    fontSize: config.fontSize,
    height: config.lineHeight,
    letterSpacing: 0.3,
    fontFamily: config.fontFamily,
    color: _readerTextColor(config),
  );
}
