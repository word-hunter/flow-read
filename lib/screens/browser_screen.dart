import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../providers/reading_provider.dart';
import '../services/analysis_service.dart';
import '../services/llm_client.dart';
import '../services/reading_assistant_agent.dart';
import '../services/settings_service.dart';
import '../services/web_content_service.dart';
import '../theme/app_constants.dart';
import '../widgets/selected_text_action_toolbar.dart';
import '../widgets/reader_text_view.dart';
import '../widgets/selected_text_sheet.dart';
import '../widgets/word_bottom_sheet.dart';

class BrowserScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;

  const BrowserScreen({super.key, this.initialUrl, this.initialTitle});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _webContentService = WebContentService();
  final _addressController = TextEditingController();
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  WebPageContent? _page;
  AnalysisResult? _analysis;
  bool _isLoading = false;
  String? _error;
  bool _assistantOpen = false;
  bool _assistantBusy = false;
  String? _assistantOutput;
  String? _assistantError;

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
    _webContentService.close();
    _addressController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl([String? value]) async {
    final input = (value ?? _addressController.text).trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _assistantOutput = null;
      _assistantError = null;
    });

    try {
      final page = await _webContentService.fetch(input);
      if (!mounted) return;
      final readingProvider = context.read<ReadingProvider>();
      final analysis = AnalysisService.analyzeChapter(
        page.title,
        page.plainText,
        readingProvider.userVocabulary,
        readingProvider.wordLevelService,
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

  void _onWordTapped(String word, String contextText) {
    final provider = context.read<ReadingProvider>();
    provider.lookupWord(word, contextText: contextText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordBottomSheet(word: word),
    ).whenComplete(provider.clearWordLookup);
  }

  void _analyzeSelected(String text) {
    final settings = context.read<SettingsService>();
    if (!settings.aiFeaturesEnabled) return;
    final selectedText = text.trim();
    if (selectedText.isEmpty) return;
    final pageText = _page?.plainText ?? '';
    final index = pageText.indexOf(selectedText);
    final beforeStart = index < 0 ? 0 : (index - 240).clamp(0, index);
    final afterEnd = index < 0
        ? 0
        : (index + selectedText.length + 240).clamp(0, pageText.length);
    final before = index < 0 ? '' : pageText.substring(beforeStart, index);
    final after = index < 0
        ? ''
        : pageText.substring(index + selectedText.length, afterEnd);
    final provider = context.read<ReadingProvider>();
    provider.analyzeSelectedTextAI(selectedText, before, after);
    _showSelectedTextSheet(selectedText);
  }

  void _showSelectedTextSheet(String selectedText) {
    final analyzerName =
        '${context.read<SettingsService>().aiProvider.label} AI';
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

  Future<void> _summarizePage() async {
    final settings = context.read<SettingsService>();
    if (!settings.aiFeaturesEnabled) return;
    final page = _page;
    if (page == null || page.plainText.trim().isEmpty) return;
    await _runAssistant(() {
      return ReadingAssistantAgent(LLMClient(settings)).summarize(
        ReadingAssistantContext(
          surface: ReadingAssistantSurface.browser,
          title: page.title,
          text: page.plainText,
          url: page.url.toString(),
        ),
      );
    });
  }

  Future<void> _askQuestion() async {
    final settings = context.read<SettingsService>();
    if (!settings.aiFeaturesEnabled) return;
    final page = _page;
    final question = _questionController.text.trim();
    if (page == null || page.plainText.trim().isEmpty || question.isEmpty) {
      return;
    }
    await _runAssistant(() {
      return ReadingAssistantAgent(LLMClient(settings)).answer(
        context: ReadingAssistantContext(
          surface: ReadingAssistantSurface.browser,
          title: page.title,
          text: page.plainText,
          url: page.url.toString(),
        ),
        question: question,
      );
    });
  }

  Future<void> _runAssistant(Future<String> Function() task) async {
    setState(() {
      _assistantOpen = true;
      _assistantBusy = true;
      _assistantError = null;
    });
    try {
      final output = await task();
      if (!mounted) return;
      setState(() {
        _assistantOutput = output.trim();
        _assistantBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assistantError = '$e';
        _assistantBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();

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
                            if (_assistantOpen) ...[
                              VerticalDivider(
                                width: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              SizedBox(
                                width: 340,
                                child: _buildAssistantPanel(theme, settings),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: _buildPageBody(theme)),
                            if (_assistantOpen)
                              SizedBox(
                                height: 320,
                                child: _buildAssistantPanel(theme, settings),
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
              _assistantOpen ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            ),
            tooltip: settings.aiFeaturesEnabled
                ? 'AI 助手'
                : settings.aiFeatureDisabledReason,
            onPressed: settings.aiFeaturesEnabled
                ? () => setState(() => _assistantOpen = !_assistantOpen)
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
    final readingProvider = context.watch<ReadingProvider>();
    final settings = context.watch<SettingsService>();

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
                        lookupHighlightWord: readingProvider.selectedWord,
                        wordLevelService: readingProvider.wordLevelService,
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

  Widget _buildAssistantPanel(ThemeData theme, SettingsService settings) {
    final aiFeaturesEnabled = settings.aiFeaturesEnabled;
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 助手',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: '关闭',
                onPressed: () => setState(() => _assistantOpen = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _page == null || _assistantBusy || !aiFeaturesEnabled
                  ? null
                  : _summarizePage,
              icon: _assistantBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.summarize_outlined),
              label: Text(_assistantBusy ? '处理中...' : '总结当前文章'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '询问当前文章',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _assistantBusy || !aiFeaturesEnabled
                  ? null
                  : _askQuestion,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('提问'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child: _assistantBusy
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Text(
                        _assistantError ??
                            _assistantOutput ??
                            (aiFeaturesEnabled
                                ? '等待提问或总结'
                                : settings.aiFeatureDisabledReason),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: _assistantError == null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
            ),
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
