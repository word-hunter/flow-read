import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../models/ai_context_snapshot.dart';
import '../models/analysis_result.dart';
import '../providers/reading/ai_notifier.dart';
import '../providers/reading/services_provider.dart';
import '../providers/reading/vocabulary_notifier.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../providers/settings_provider.dart';
import '../services/analysis_service.dart';
import '../services/settings_service.dart';
import '../services/web_content_service.dart';
import '../theme/app_constants.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/selected_text_action_toolbar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

/// INTERNAL SUBSTRATE - not exposed as a standalone app surface.
///
/// Browser is used by RSS to show original article pages. Keep the legal entry
/// points limited to RSS article actions; do not add a home tab, settings entry,
/// or named route for this screen.
class BrowserScreen extends riverpod.ConsumerStatefulWidget {
  final String? initialUrl;
  final String? initialTitle;

  const BrowserScreen({super.key, this.initialUrl, this.initialTitle});

  @override
  riverpod.ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends riverpod.ConsumerState<BrowserScreen> {
  final _webContentService = WebContentService();
  final _addressController = TextEditingController();
  final _scrollController = ScrollController();

  WebPageContent? _page;
  AnalysisResult? _analysis;
  bool _isLoading = false;
  String? _error;
  bool _showAssistant = false;

  @override
  void initState() {
    super.initState();
    final initialUrl = widget.initialUrl?.trim();
    if (initialUrl != null && initialUrl.isNotEmpty) {
      _addressController.text = initialUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadUrl(initialUrl));
      });
    }
  }

  @override
  void dispose() {
    ref.read(aiAssistantControllerProvider).clear();
    _webContentService.close();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl([String? value]) async {
    final input = (value ?? _addressController.text).trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    ref.read(aiAssistantControllerProvider).clear();

    try {
      final page = await _webContentService.fetch(input);
      if (!mounted) return;
      final vocNotifier = ref.read(vocabularyNotifierProvider.notifier);
      final analysis = AnalysisService.analyzeChapter(
        page.title,
        page.plainText,
        vocNotifier.userVocabulary,
        ref.read(wordLevelServiceProvider),
        vocNotifier.activeLanguageModule,
      );
      setState(() {
        _page = page;
        _analysis = analysis;
        _addressController.text = page.url.toString();
        _isLoading = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  void _onWordTapped(
    String surface,
    String canonical,
    String languageId,
    String contextText, {
    int? contextWordStart,
    int? contextWordEnd,
  }) {
    final lookupNotifier = ref.read(wordLookupNotifierProvider.notifier);
    lookupNotifier.lookupWord(
      surface,
      canonicalForm: canonical,
      languageCode: languageId,
      contextText: contextText,
      contextWordStart: contextWordStart,
      contextWordEnd: contextWordEnd,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordBottomSheet(word: surface),
    ).whenComplete(lookupNotifier.clearWordLookup);
  }

  void _analyzeSelected(String text) {
    final settings = ref.read(settingsProvider);
    if (!settings.aiFeaturesEnabled) return;
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;
    final pageText = _page?.plainText ?? '';
    ref
        .read(aiNotifierProvider.notifier)
        .analyzeSelectedTextAI(selectedText, sourceText: pageText);
    _showSelectedTextSheet(selectedText);
  }

  void _showSelectedTextSheet(String selectedText) {
    final analyzerName = '${ref.read(settingsProvider).aiProvider.label} AI';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectedTextSheet(
        selectedText: selectedText,
        analysis: null,
        analyzerName: analyzerName,
      ),
    );
  }

  void _openAssistant() {
    if (!ref.read(settingsProvider).aiFeaturesEnabled) return;
    final page = _page;
    if (page == null || page.plainText.trim().isEmpty) return;

    final assistant = ref.read(aiAssistantControllerProvider);
    assistant.setContext(
      AIContextSnapshot(
        source: AIContextSource.rssArticle,
        articleTitle: page.title,
        articleContent: page.plainText,
        articleUrl: page.url.toString(),
      ),
    );
    setState(() => _showAssistant = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppConstants.wideBreakpoint;
            return Column(
              children: [
                _buildToolbar(theme, settings),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildPageBody(theme)),
                            if (_showAssistant) ...[
                              VerticalDivider(
                                width: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              SizedBox(
                                width: 340,
                                child: AIAssistantPanel(
                                  controller: ref.read(
                                    aiAssistantControllerProvider,
                                  ),
                                  onClose: () =>
                                      setState(() => _showAssistant = false),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: _buildPageBody(theme)),
                            if (_showAssistant)
                              SizedBox(
                                height: 320,
                                child: AIAssistantPanel(
                                  controller: ref.read(
                                    aiAssistantControllerProvider,
                                  ),
                                  onClose: () =>
                                      setState(() => _showAssistant = false),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, SettingsService settings) {
    final canRefresh = _page != null && !_isLoading;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: '返回',
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            ),
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _addressController,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  hintText: '输入 URL',
                  prefixIcon: const Icon(Icons.language_outlined, size: 18),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          tooltip: '打开',
                          onPressed: _loadUrl,
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) => unawaited(_loadUrl(value)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: canRefresh ? () => unawaited(_loadUrl()) : null,
          ),
          IconButton(
            icon: Icon(
              _showAssistant ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            ),
            tooltip: settings.aiFeaturesEnabled
                ? 'AI 助手'
                : settings.aiFeatureDisabledReason,
            onPressed: settings.aiFeaturesEnabled
                ? () {
                    if (!_showAssistant) _openAssistant();
                    setState(() => _showAssistant = !_showAssistant);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageBody(ThemeData theme) {
    if (_isLoading && _page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _page == null) {
      return _buildMessageState(
        theme,
        icon: Icons.error_outline,
        title: '网页加载失败',
        message: _error!,
      );
    }
    if (_page == null || _analysis == null) {
      return _buildMessageState(
        theme,
        icon: Icons.language_outlined,
        title: widget.initialTitle ?? '浏览器',
        message: '输入网页地址后开始阅读',
      );
    }

    final page = _page!;
    final analysis = _analysis!;
    final lookupState = ref.watch(wordLookupNotifierProvider);
    final settings = ref.watch(settingsProvider);
    return SelectedTextActionRegion(
      actionsBuilder: (context, selectedText, closeToolbar) => [
        SelectedTextAction.copy(
          context: context,
          selectedText: selectedText,
          closeToolbar: closeToolbar,
        ),
        SelectedTextAction(
          icon: Icons.auto_awesome_rounded,
          tooltip: 'AI 解析',
          enabled: settings.aiFeaturesEnabled && selectedText.trim().isNotEmpty,
          onPressed: () {
            closeToolbar();
            _analyzeSelected(selectedText);
          },
        ),
      ],
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  _buildInlineError(theme, _error!),
                  const SizedBox(height: 16),
                ],
                Text(
                  page.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  page.url.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                for (final paragraph in page.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text.rich(
                      buildHighlightedParagraph(
                        paragraph,
                        analysis,
                        theme,
                        onWordTapped: _onWordTapped,
                        fontSize: 16,
                        lineHeight: 1.75,
                        fontFamily: 'Serif',
                        colorSettings: settings.colors,
                        lookupHighlightWord: lookupState.selectedWord,
                        wordLevelService: ref.read(wordLevelServiceProvider),
                        languageModule: ref.read(vocabularyNotifierProvider.notifier).activeLanguageModule,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.75,
                        fontSize: 16,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
            tooltip: '关闭',
            onPressed: () => setState(() => _error = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 54,
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
