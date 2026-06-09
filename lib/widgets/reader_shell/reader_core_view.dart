import 'package:flow_language/flow_language.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../models/analysis_result.dart';
import '../../models/content_block.dart';
import '../../providers/reading/current_book_notifier.dart';
import '../../providers/reading/reading_config_notifier.dart';
import '../../providers/reading/reading_search_notifier.dart';
import '../../providers/reading/word_lookup_notifier.dart';
import '../../services/settings_service.dart' show VocabularyColorSettings;
import '../../services/word_level_service.dart';
import '../reader/reader_content_view.dart';
import '../reader_text_view.dart' show WordTapCallback;
import '../selected_text_action_toolbar.dart'
    show SelectedTextActionRegionState;

class ReaderCoreView extends StatefulWidget {
  final List<String> paragraphs;
  final List<ContentBlock> blocks;
  final AnalysisResult result;
  final ThemeData theme;
  final VocabularyColorSettings colorSettings;
  final bool aiFeaturesEnabled;
  final CurrentBookNotifier currentBook;
  final ReadingConfigState config;
  final ReadingSearchState search;
  final WordLookupState lookupState;
  final WordLevelService? wordLevelService;
  final LanguageModule? activeLanguageModule;
  final GlobalKey<SelectionAreaState> readerSelectionAreaKey;
  final GlobalKey<SelectedTextActionRegionState> actionRegionKey;
  final bool isWideScreen;
  final bool sidebarOpen;
  final bool isSearchPanelVisible;
  final WordTapCallback onWordTapped;
  final ValueChanged<String> onAnalyzeSelected;
  final ValueListenable<double> progressListenable;
  final ScrollController scrollController;
  final GlobalKey Function(int index) contentKeyFor;
  final ValueChanged<int> onVisibleContentCountChanged;

  const ReaderCoreView({
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
    required this.lookupState,
    required this.wordLevelService,
    required this.activeLanguageModule,
    required this.readerSelectionAreaKey,
    required this.actionRegionKey,
    required this.isWideScreen,
    required this.sidebarOpen,
    required this.isSearchPanelVisible,
    required this.onWordTapped,
    required this.onAnalyzeSelected,
    required this.progressListenable,
    required this.scrollController,
    required this.contentKeyFor,
    required this.onVisibleContentCountChanged,
  });

  @override
  State<ReaderCoreView> createState() => _ReaderCoreViewState();
}

class _ReaderCoreViewState extends State<ReaderCoreView> {
  @override
  Widget build(BuildContext context) {
    return ReaderContentView(
      paragraphs: widget.paragraphs,
      blocks: widget.blocks,
      result: widget.result,
      theme: widget.theme,
      colorSettings: widget.colorSettings,
      aiFeaturesEnabled: widget.aiFeaturesEnabled,
      currentBook: widget.currentBook,
      config: widget.config,
      search: widget.search,
      lookupState: widget.lookupState,
      wordLevelService: widget.wordLevelService,
      activeLanguageModule: widget.activeLanguageModule,
      readerSelectionAreaKey: widget.readerSelectionAreaKey,
      actionRegionKey: widget.actionRegionKey,
      scrollController: widget.scrollController,
      isWideScreen: widget.isWideScreen,
      sidebarOpen: widget.sidebarOpen,
      isSearchPanelVisible: widget.isSearchPanelVisible,
      contentKeyFor: widget.contentKeyFor,
      onVisibleContentCountChanged: widget.onVisibleContentCountChanged,
      onWordTapped: widget.onWordTapped,
      onAnalyzeSelected: widget.onAnalyzeSelected,
    );
  }
}
