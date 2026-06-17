import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/reading_memory.dart';
import '../models/user_vocabulary.dart';
import '../models/word_context_example.dart';
import '../models/word_level.dart';
import '../providers/reading/word_lookup_notifier.dart';
import '../services/external_url_launcher.dart';
import '../services/word_level_service.dart';
import 'flow/flow_components.dart';
import 'imported_word_examples.dart';
import 'markdown_message.dart';
import 'pronunciation_button.dart';
import 'visual_hint_card.dart';

class DictionaryDetailView extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final String? primaryDefinition;
  final bool isLoading;
  final String? contextText;
  final int? contextWordStart;
  final int? contextWordEnd;
  final List<WordContextExample> importedExamples;
  final CompoundAnalysisResult? compoundAnalysis;
  final List<BookContextSnippet> bookContexts;
  final LevelKey? level;
  final bool showWordHeader;
  final bool showContext;
  final SpeakWordCallback? onSpeakWord;
  final ValueChanged<String>? onLookupWord;
  final VoidCallback? onGoBack;
  final bool canGoBack;
  final VisualDefinition? visualDefinition;
  final bool isLoadingVisualHint;
  final bool showVisualHint;
  final WordMemoryCard? wordMemoryCard;
  final bool isLoadingWordMemory;
  final bool canGenerateBookGlossaryExplanation;
  final String? bookGlossaryDraftExplanation;
  final bool isGeneratingBookGlossaryExplanation;
  final bool isSavingBookGlossaryExplanation;
  final String? bookGlossaryError;
  final VoidCallback? onGenerateBookGlossaryExplanation;
  final Future<bool> Function(String explanation)?
  onSaveBookGlossaryExplanation;
  final VoidCallback? onRetryLookup;

  const DictionaryDetailView({
    super.key,
    required this.word,
    required this.entry,
    required this.primaryDefinition,
    required this.isLoading,
    this.contextText,
    this.contextWordStart,
    this.contextWordEnd,
    this.importedExamples = const [],
    this.compoundAnalysis,
    this.bookContexts = const [],
    this.level,
    this.showWordHeader = true,
    this.showContext = false,
    this.onSpeakWord,
    this.onLookupWord,
    this.onGoBack,
    this.canGoBack = false,
    this.visualDefinition,
    this.isLoadingVisualHint = false,
    this.showVisualHint = true,
    this.wordMemoryCard,
    this.isLoadingWordMemory = false,
    this.canGenerateBookGlossaryExplanation = false,
    this.bookGlossaryDraftExplanation,
    this.isGeneratingBookGlossaryExplanation = false,
    this.isSavingBookGlossaryExplanation = false,
    this.bookGlossaryError,
    this.onGenerateBookGlossaryExplanation,
    this.onSaveBookGlossaryExplanation,
    this.onRetryLookup,
  });

  factory DictionaryDetailView.fromWordLookup({
    Key? key,
    required WordLookupState lookupState,
    required WordLookupNotifier lookupNotifier,
    required String word,
    bool showWordHeader = true,
    bool showContext = false,
    bool showVisualHint = true,
    WordLevelService? wordLevelService,
    bool canPronounceWords = false,
  }) {
    LevelKey? level;
    if (wordLevelService != null && wordLevelService.hasWord(word)) {
      level = wordLevelService.getLevel(word);
    }

    return DictionaryDetailView(
      key: key,
      word: word,
      entry: lookupState.selectedWordEntry,
      primaryDefinition: lookupState.selectedWordTranslation,
      isLoading: lookupState.isLoadingWord,
      contextText: lookupState.selectedWordContext,
      contextWordStart: lookupState.selectedWordContextStart,
      contextWordEnd: lookupState.selectedWordContextEnd,
      importedExamples: lookupNotifier.importedExamplesFor(word),
      compoundAnalysis: lookupState.selectedWordLookupResult?.compoundAnalysis,
      bookContexts:
          lookupState.selectedWordLookupResult?.bookContexts ?? const [],
      level: level,
      showWordHeader: showWordHeader,
      showContext: showContext,
      onSpeakWord: canPronounceWords ? lookupNotifier.speakWord : null,
      onLookupWord: lookupNotifier.lookupRelatedWord,
      onGoBack: lookupState.canGoBackWordLookup
          ? lookupNotifier.goBackWordLookup
          : null,
      canGoBack: lookupState.canGoBackWordLookup,
      visualDefinition: lookupState.visualDefinition,
      isLoadingVisualHint: lookupState.isLoadingVisualHint,
      showVisualHint: showVisualHint,
      wordMemoryCard: lookupState.wordMemoryCard,
      isLoadingWordMemory: lookupState.isLoadingWordMemory,
      canGenerateBookGlossaryExplanation:
          lookupNotifier.canGenerateBookGlossaryExplanation,
      bookGlossaryDraftExplanation: lookupState.bookGlossaryDraftExplanation,
      isGeneratingBookGlossaryExplanation:
          lookupState.isGeneratingBookGlossaryExplanation,
      isSavingBookGlossaryExplanation:
          lookupState.isSavingBookGlossaryExplanation,
      bookGlossaryError: lookupState.bookGlossaryError,
      onGenerateBookGlossaryExplanation:
          lookupNotifier.generateBookGlossaryExplanation,
      onSaveBookGlossaryExplanation: (explanation) {
        return lookupNotifier.saveBookGlossaryExplanation(
          explanation: explanation,
        );
      },
      onRetryLookup: lookupNotifier.retryWordLookup,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasEntryContent = entry != null && !entry!.isEmpty;
    final hasPrimaryDefinition =
        primaryDefinition != null && primaryDefinition!.trim().isNotEmpty;
    final hasContent =
        hasEntryContent ||
        hasPrimaryDefinition ||
        importedExamples.isNotEmpty ||
        compoundAnalysis != null ||
        bookContexts.isNotEmpty;
    final hasPersonalMemory =
        isLoadingWordMemory || wordMemoryCard?.hasPersonalMemory == true;
    final hasBookGlossarySuggestion =
        canGenerateBookGlossaryExplanation ||
        isGeneratingBookGlossaryExplanation ||
        (bookGlossaryDraftExplanation?.trim().isNotEmpty ?? false) ||
        (bookGlossaryError?.trim().isNotEmpty ?? false);
    final dictionaryError = entry?.errorMessage?.trim();
    final hasDictionaryError =
        dictionaryError != null && dictionaryError.isNotEmpty;
    final isLocalFallback =
        hasDictionaryError &&
        entry?.sourceName == DictionarySourceType.wordNet.label;

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canGoBack && onGoBack != null) ...[
            SizedBox(
              width: double.infinity,
              child: FlowButton.text(
                onPressed: () => onGoBack?.call(),
                icon: const Icon(Icons.arrow_back, size: 18),
                child: const Text('返回上一个词条'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (showWordHeader) ...[
            _WordHeader(
              word: word,
              entry: entry,
              level: level,
              onSpeakWord: onSpeakWord,
            ),
            const SizedBox(height: 16),
          ],
          if (!hasContent &&
              !hasPersonalMemory &&
              !hasBookGlossarySuggestion &&
              visualDefinition == null &&
              !isLoadingVisualHint)
            _EmptyDictionaryState(
              errorMessage: entry?.errorMessage,
              onRetry: onRetryLookup,
            )
          else ...[
            if (hasContent)
              _CollapsiblePanel(
                icon: Icons.menu_book_outlined,
                title: '词典',
                initiallyExpanded: true,
                children: [
                  if (hasDictionaryError) ...[
                    _DictionaryErrorBlock(
                      message: dictionaryError,
                      onRetry: onRetryLookup,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (hasPrimaryDefinition) ...[
                    _SectionLabel(
                      label: isLocalFallback ? '本地兜底释义' : '释义',
                    ),
                    const SizedBox(height: 6),
                    _PrimaryDefinition(
                      text: primaryDefinition!.trim(),
                      currentWord: word,
                      onLookupWord: onLookupWord,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (entry != null) ...[
                    for (final meaning in entry!.meanings)
                      _MeaningBlock(
                        meaning: meaning,
                        primaryDefinition: primaryDefinition?.trim(),
                        currentWord: word,
                        onLookupWord: onLookupWord,
                      ),
                  ],
                  if (importedExamples.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    ImportedWordExamples(examples: importedExamples),
                  ],
                  if (compoundAnalysis != null || bookContexts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DictionaryFallbackSection(
                      analysis: compoundAnalysis,
                      contexts: bookContexts,
                    ),
                  ],
                ],
              ),
            if (hasBookGlossarySuggestion) ...[
              const SizedBox(height: 6),
              _CollapsiblePanel(
                icon: Icons.auto_awesome_outlined,
                title: '作品术语',
                initiallyExpanded: true,
                children: [
                  _BookGlossarySuggestionSection(
                    draftExplanation: bookGlossaryDraftExplanation,
                    isGenerating: isGeneratingBookGlossaryExplanation,
                    isSaving: isSavingBookGlossaryExplanation,
                    error: bookGlossaryError,
                    onGenerate: onGenerateBookGlossaryExplanation,
                    onSave: onSaveBookGlossaryExplanation,
                  ),
                ],
              ),
            ],
            if (hasPersonalMemory) ...[
              const SizedBox(height: 6),
              _CollapsiblePanel(
                icon: Icons.history_edu_outlined,
                title: '个人记忆',
                initiallyExpanded: true,
                children: [
                  if (isLoadingWordMemory)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else if (wordMemoryCard != null)
                    _WordMemorySection(card: wordMemoryCard!),
                ],
              ),
            ],
            if (showVisualHint &&
                (visualDefinition != null || isLoadingVisualHint)) ...[
              const SizedBox(height: 6),
              _CollapsiblePanel(
                icon: Icons.image_outlined,
                title: '图片',
                initiallyExpanded: true,
                children: [
                  if (visualDefinition != null)
                    VisualHintCard(definition: visualDefinition!)
                  else
                    const VisualHintLoadingIndicator(),
                ],
              ),
            ],
          ],
          if (showContext) ...[
            const SizedBox(height: 18),
            DictionaryContextBlock(
              word: word,
              contextText: contextText,
              contextWordStart: contextWordStart,
              contextWordEnd: contextWordEnd,
            ),
          ],
        ],
      ),
    );
  }
}

class _WordHeader extends StatelessWidget {
  final String word;
  final DictionaryEntry? entry;
  final LevelKey? level;
  final SpeakWordCallback? onSpeakWord;

  const _WordHeader({
    required this.word,
    required this.entry,
    required this.level,
    required this.onSpeakWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceName = entry?.sourceName;
    final phonetic = entry?.phonetic?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Serif',
                  color: theme.colorScheme.onSurface,
                  height: 1.05,
                ),
              ),
            ),
            if (onSpeakWord != null) ...[
              const SizedBox(width: 8),
              PronunciationButton(word: word, onSpeakWord: onSpeakWord),
            ],
          ],
        ),
        if (phonetic != null && phonetic.isNotEmpty) ...[
          const SizedBox(height: 6),
          DictionaryPhoneticText(text: phonetic),
        ],
        if (level != null || sourceName != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (level != null)
                _MetaChip(
                  label: '${level!.shortLabel} ${level!.label}',
                  color: _levelColor(level!),
                ),
              if (sourceName != null) DictionarySourceBadge(entry: entry!),
            ],
          ),
        ],
      ],
    );
  }

  static const _levelColors = [
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.grey,
  ];

  Color _levelColor(LevelKey level) {
    final index = (level.difficultyScore - 1).clamp(0, _levelColors.length - 1);
    return _levelColors[index];
  }
}

class DictionaryPhoneticText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const DictionaryPhoneticText({super.key, required this.text, this.style});

  static const _fontFamilyFallback = [
    'Lucida Grande',
    'Helvetica Neue',
    'Arial Unicode MS',
    'Noto Sans',
    'DejaVu Sans',
    'Segoe UI',
    'Arial',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
        color: style?.color ?? theme.colorScheme.onSurfaceVariant,
        fontFamily: 'Lucida Grande',
        fontFamilyFallback: _fontFamilyFallback,
        fontStyle: FontStyle.normal,
        letterSpacing: 0,
      ),
    );
  }
}

class DictionarySourceBadge extends StatelessWidget {
  final DictionaryEntry entry;

  const DictionarySourceBadge({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = entry.fromCache
        ? '${entry.sourceName ?? '词典'} · 缓存'
        : entry.sourceName ?? '词典';
    final color = theme.colorScheme.onSurfaceVariant;
    final sourceUrl = entry.sourceUrl;

    if (sourceUrl == null || sourceUrl.isEmpty) {
      return _MetaChip(label: label, color: color);
    }

    return _SourceLinkChip(label: label, color: color, sourceUrl: sourceUrl);
  }
}

class _SourceLinkChip extends StatefulWidget {
  final String label;
  final Color color;
  final String sourceUrl;

  const _SourceLinkChip({
    required this.label,
    required this.color,
    required this.sourceUrl,
  });

  @override
  State<_SourceLinkChip> createState() => _SourceLinkChipState();
}

class _SourceLinkChipState extends State<_SourceLinkChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          try {
            await const ExternalUrlLauncher().open(Uri.parse(widget.sourceUrl));
          } on ExternalUrlOpenException {
            // silently ignore
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: _hovered ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 12, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WordMemorySection extends StatelessWidget {
  const _WordMemorySection({required this.card});

  final WordMemoryCard card;

  @override
  Widget build(BuildContext context) {
    final explanations = card.savedExplanations
        .where((item) => item.explanation.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
    final examples = _examples().take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (card.userStatus != null)
              _MetaChip(
                label: _statusLabel(card.userStatus!),
                color: _statusColor(context, card.userStatus!),
              ),
            if (card.lookupCount > 0)
              _MetaChip(
                label: '查词 ${card.lookupCount} 次',
                color: Theme.of(context).colorScheme.primary,
              ),
            if (card.evidences.isNotEmpty)
              _MetaChip(
                label: '例句 ${card.evidences.length} 条',
                color: Theme.of(context).colorScheme.tertiary,
              ),
          ],
        ),
        if (explanations.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionLabel(label: '保存解释'),
          const SizedBox(height: 6),
          for (final explanation in explanations)
            _MemorySnippet(text: explanation.explanation.trim()),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: '历史例句'),
          const SizedBox(height: 6),
          for (final example in examples)
            _MemorySnippet(text: example.text, source: example.source),
        ],
      ],
    );
  }

  Iterable<({String text, String? source})> _examples() sync* {
    final seen = <String>{};
    for (final example in card.contextExamples) {
      final text = example.text.trim();
      if (text.isEmpty || !seen.add(text)) continue;
      final source = example.title.trim();
      yield (text: text, source: source.isEmpty ? null : source);
    }
    for (final evidence in card.evidences) {
      final text = evidence.shortExcerpt.trim();
      if (text.isEmpty || !seen.add(text)) continue;
      yield (text: text, source: _evidenceSourceLabel(evidence));
    }
  }

  String _statusLabel(UserWordStatus status) {
    return switch (status) {
      UserWordStatus.learning => '学习中',
      UserWordStatus.known => '已掌握',
    };
  }

  Color _statusColor(BuildContext context, UserWordStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      UserWordStatus.learning => scheme.secondary,
      UserWordStatus.known => scheme.tertiary,
    };
  }

  String? _evidenceSourceLabel(MemoryKnowledgeEvidence evidence) {
    final title = evidence.sourceTitleSnapshot.trim();
    if (title.isEmpty) return null;
    return switch (evidence.sourceAvailability) {
      SourceAvailability.available => title,
      SourceAvailability.archived => '$title · 已归档',
      SourceAvailability.deleted => '$title · 已删除',
    };
  }
}

class _MemorySnippet extends StatelessWidget {
  const _MemorySnippet({required this.text, this.source});

  final String text;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          if (source != null && source!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              source!.trim(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollapsiblePanel extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CollapsiblePanel({
    required this.icon,
    required this.title,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  State<_CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<_CollapsiblePanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 18, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PrimaryDefinition extends StatelessWidget {
  final String text;
  final String currentWord;
  final ValueChanged<String>? onLookupWord;

  const _PrimaryDefinition({
    required this.text,
    required this.currentWord,
    required this.onLookupWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBackground = _tintedDictionarySurface(
      tint: theme.colorScheme.primary,
      surface: theme.colorScheme.surface,
      alpha: theme.colorScheme.surface.computeLuminance() < 0.45 ? 0.18 : 0.10,
    );
    final cardForeground = _readableDictionaryColorFor(
      cardBackground,
      preferred: theme.colorScheme.onSurface,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: FlowMarkdownMessage(
        text: text,
        currentWord: currentWord,
        onLookupWord: onLookupWord,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: cardForeground,
          height: 1.45,
        ),
      ),
    );
  }
}

Color _tintedDictionarySurface({
  required Color tint,
  required Color surface,
  required double alpha,
}) {
  return Color.alphaBlend(tint.withValues(alpha: alpha), surface);
}

Color _readableDictionaryColorFor(
  Color background, {
  required Color preferred,
}) {
  if (_dictionaryContrastRatio(background, preferred) >= 4.5) {
    return preferred;
  }

  final whiteContrast = _dictionaryContrastRatio(background, Colors.white);
  final blackContrast = _dictionaryContrastRatio(background, Colors.black);
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}

double _dictionaryContrastRatio(Color a, Color b) {
  final aLum = a.computeLuminance();
  final bLum = b.computeLuminance();
  final lighter = aLum > bLum ? aLum : bLum;
  final darker = aLum > bLum ? bLum : aLum;
  return (lighter + 0.05) / (darker + 0.05);
}

class _MeaningBlock extends StatelessWidget {
  final Meaning meaning;
  final String? primaryDefinition;
  final String currentWord;
  final ValueChanged<String>? onLookupWord;

  const _MeaningBlock({
    required this.meaning,
    required this.currentWord,
    required this.onLookupWord,
    this.primaryDefinition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legacyExamples = meaning.definitions
        .where((definition) => definition.startsWith('Example:'))
        .map((definition) => definition.replaceFirst('Example:', '').trim())
        .where((definition) => definition.isNotEmpty)
        .toList();
    final definitions = meaning.definitions
        .where((definition) => !definition.startsWith('Example:'))
        .where((definition) => definition.trim() != primaryDefinition)
        .toList();
    final examples = [...meaning.examples, ...legacyExamples];

    if (definitions.isEmpty &&
        examples.isEmpty &&
        meaning.partOfSpeech.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meaning.partOfSpeech.isNotEmpty)
            _PartOfSpeechChip(label: meaning.partOfSpeech),
          if (definitions.isNotEmpty) const SizedBox(height: 6),
          for (final item in definitions.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _InteractiveDictionaryText(
                text: '${item.key + 1}. ${item.value}',
                currentWord: currentWord,
                onLookupWord: onLookupWord,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          if (examples.isNotEmpty) ...[
            if (definitions.isNotEmpty) const SizedBox(height: 4),
            DictionaryExamplesSection(
              examples: examples,
              currentWord: currentWord,
              onLookupWord: onLookupWord,
            ),
          ],
        ],
      ),
    );
  }
}

class _PartOfSpeechChip extends StatelessWidget {
  final String label;

  const _PartOfSpeechChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DictionaryExamplesSection extends StatelessWidget {
  final List<String> examples;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;

  const DictionaryExamplesSection({
    super.key,
    required this.examples,
    this.currentWord,
    this.onLookupWord,
  });

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final visible = examples.take(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final example in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _InteractiveDictionaryText(
              text: example,
              currentWord: currentWord,
              onLookupWord: onLookupWord,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}

class _InteractiveDictionaryText extends StatefulWidget {
  const _InteractiveDictionaryText({
    required this.text,
    required this.style,
    this.currentWord,
    this.onLookupWord,
  });

  final String text;
  final TextStyle? style;
  final String? currentWord;
  final ValueChanged<String>? onLookupWord;

  @override
  State<_InteractiveDictionaryText> createState() =>
      _InteractiveDictionaryTextState();
}

class _InteractiveDictionaryTextState
    extends State<_InteractiveDictionaryText> {
  static const _tapSlop = 6.0;

  final GlobalKey _textKey = GlobalKey();
  int? _hoveredTokenStart;
  int? _pendingHoveredTokenStart;
  int? _activePointer;
  Offset? _pointerDownPosition;
  bool _pointerMoved = false;
  bool _hoverUpdateScheduled = false;
  int _hoverUpdateGeneration = 0;

  @override
  void dispose() {
    _hoverUpdateGeneration += 1;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InteractiveDictionaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.currentWord != widget.currentWord) {
      _hoveredTokenStart = null;
      _pendingHoveredTokenStart = null;
      _hoverUpdateGeneration += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerCancel: (_) => _clearPointerTracking(),
      onPointerUp: _handlePointerUp,
      child: Text.rich(
        key: _textKey,
        TextSpan(style: widget.style, children: _buildSpans(context)),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final callback = widget.onLookupWord;
    if (callback == null) {
      return [TextSpan(text: widget.text)];
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(r"[A-Za-z][A-Za-z'-]*");
    var cursor = 0;
    for (final match in pattern.allMatches(widget.text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }

      final token = widget.text.substring(match.start, match.end);
      if (_isLookupCandidate(token)) {
        final tokenStart = match.start;
        final hovered = _hoveredTokenStart == tokenStart;
        spans.add(
          TextSpan(
            text: token,
            mouseCursor: SystemMouseCursors.click,
            onEnter: (_) => _scheduleHoveredToken(tokenStart),
            onExit: (_) {
              if (_hoveredTokenStart == tokenStart ||
                  _pendingHoveredTokenStart == tokenStart) {
                _scheduleHoveredToken(null);
              }
            },
            style: hovered
                ? TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  )
                : null,
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }
      cursor = match.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    return spans;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton || widget.onLookupWord == null) {
      _clearPointerTracking();
      return;
    }

    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
    _pointerMoved = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    final start = _pointerDownPosition;
    if (start == null) return;
    if ((event.position - start).distance > _tapSlop) {
      _pointerMoved = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerDownPosition;
    final isTrackedTap =
        event.pointer == _activePointer &&
        start != null &&
        !_pointerMoved &&
        (event.position - start).distance <= _tapSlop;
    _clearPointerTracking();

    if (!isTrackedTap) return;
    final token = _lookupTokenAt(event.position);
    if (token == null) return;
    widget.onLookupWord?.call(token);
  }

  void _clearPointerTracking() {
    _activePointer = null;
    _pointerDownPosition = null;
    _pointerMoved = false;
  }

  String? _lookupTokenAt(Offset globalPosition) {
    if (widget.onLookupWord == null) return null;

    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final localPosition = renderObject.globalToLocal(globalPosition);
    if (!(Offset.zero & renderObject.size).contains(localPosition)) {
      return null;
    }

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: renderObject.size.width);

    final pattern = RegExp(r"[A-Za-z][A-Za-z'-]*");
    for (final match in pattern.allMatches(widget.text)) {
      final token = widget.text.substring(match.start, match.end);
      if (!_isLookupCandidate(token)) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: match.start, extentOffset: match.end),
      );
      for (final box in boxes) {
        if (box.toRect().inflate(2).contains(localPosition)) {
          return _normalizeLookupToken(token);
        }
      }
    }

    return null;
  }

  void _scheduleHoveredToken(int? tokenStart) {
    _pendingHoveredTokenStart = tokenStart;
    if (_hoverUpdateScheduled) return;

    _hoverUpdateScheduled = true;
    final generation = _hoverUpdateGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoverUpdateScheduled = false;
      if (!mounted || generation != _hoverUpdateGeneration) return;
      final nextHoveredTokenStart = _pendingHoveredTokenStart;
      if (_hoveredTokenStart == nextHoveredTokenStart) return;
      setState(() => _hoveredTokenStart = nextHoveredTokenStart);
    });
  }

  bool _isLookupCandidate(String token) {
    final normalized = _normalizeLookupToken(token);
    if (normalized.length < 2) return false;
    final current = widget.currentWord?.trim().toLowerCase();
    return current == null || current != normalized;
  }

  String _normalizeLookupToken(String token) {
    return token
        .replaceAll(RegExp(r"(^[^A-Za-z]+|[^A-Za-z]+$)"), '')
        .toLowerCase();
  }
}

class _DictionaryFallbackSection extends StatelessWidget {
  const _DictionaryFallbackSection({
    required this.analysis,
    required this.contexts,
  });

  final CompoundAnalysisResult? analysis;
  final List<BookContextSnippet> contexts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnalysis = analysis != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusHint(
          icon: hasAnalysis
              ? Icons.manage_search_outlined
              : Icons.auto_awesome_outlined,
          text: hasAnalysis ? '通用词典未命中，以下为规则推测结果。' : '通用词典未命中，可通过 AI 详解此词。',
          color: hasAnalysis
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.tertiary,
        ),
        if (hasAnalysis) ...[
          const SizedBox(height: 12),
          _CompoundAnalysisBlock(analysis: analysis!),
        ],
        if (contexts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _BookContextsBlock(contexts: contexts),
        ],
      ],
    );
  }
}

class _BookGlossarySuggestionSection extends StatefulWidget {
  const _BookGlossarySuggestionSection({
    required this.draftExplanation,
    required this.isGenerating,
    required this.isSaving,
    required this.error,
    required this.onGenerate,
    required this.onSave,
  });

  final String? draftExplanation;
  final bool isGenerating;
  final bool isSaving;
  final String? error;
  final VoidCallback? onGenerate;
  final Future<bool> Function(String explanation)? onSave;

  @override
  State<_BookGlossarySuggestionSection> createState() =>
      _BookGlossarySuggestionSectionState();
}

class _BookGlossarySuggestionSectionState
    extends State<_BookGlossarySuggestionSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.draftExplanation?.trim() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _BookGlossarySuggestionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.draftExplanation?.trim() ?? '';
    if (nextText != oldWidget.draftExplanation?.trim() &&
        nextText != _controller.text) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDraft = widget.draftExplanation?.trim().isNotEmpty ?? false;
    final error = widget.error?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasDraft
              ? '根据已读上下文生成的术语解释，可编辑后保存到本书术语表。'
              : '词典未命中时，可以根据已读上下文推测它在本书里的含义。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (widget.isGenerating) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (hasDraft) ...[
          const SizedBox(height: 12),
          FlowTextField(
            controller: _controller,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '术语解释',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (error != null && error.isNotEmpty) ...[
          const SizedBox(height: 10),
          _StatusHint(
            icon: Icons.warning_amber_rounded,
            text: error,
            color: theme.colorScheme.error,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            FlowButton.secondary(
              onPressed: widget.isGenerating || widget.isSaving
                  ? null
                  : widget.onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 16),
              child: Text(hasDraft ? '重新推测' : 'AI 推测术语'),
            ),
            if (hasDraft) ...[
              const SizedBox(width: 8),
              FlowButton.primary(
                onPressed: widget.isGenerating || widget.isSaving
                    ? null
                    : () async {
                        final saved = await widget.onSave?.call(
                          _controller.text,
                        );
                        if (!context.mounted || saved != true) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已保存到本书术语表'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                child: const Text('保存'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CompoundAnalysisBlock extends StatelessWidget {
  const _CompoundAnalysisBlock({required this.analysis});

  final CompoundAnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 17,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '构词分析',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.components.join(' + '),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in analysis.components.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                _componentText(
                  item.value,
                  analysis.componentMeanings.elementAtOrNull(item.key),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _componentText(String component, String? meaning) {
    final text = component.trim();
    final definition = meaning?.trim();
    if (definition == null || definition.isEmpty) return text;
    return '$text: $definition';
  }
}

class _BookContextsBlock extends StatelessWidget {
  const _BookContextsBlock({required this.contexts});

  final List<BookContextSnippet> contexts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 17,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '在本书中出现',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final contextSnippet in contexts.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.32,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.42,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contextSnippet.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contextSnippet.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.38),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DictionaryContextBlock extends StatelessWidget {
  static const _maxContextLines = 4;
  static const _maxContextCharacters = 150;
  static const _contextLeadCharacters = 52;

  final String word;
  final String? contextText;
  final int? contextWordStart;
  final int? contextWordEnd;
  final Widget? trailing;
  final LanguageModule? languageModule;

  const DictionaryContextBlock({
    super.key,
    required this.word,
    this.contextText,
    this.contextWordStart,
    this.contextWordEnd,
    this.languageModule,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = contextText?.trim();
    final excerpt = text == null || text.isEmpty ? null : _contextExcerpt(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: '原文语境'),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: text == null || text.isEmpty
              ? Text(
                  '暂无原文语境',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Text.rich(
                  _highlightContext(theme, excerpt!),
                  maxLines: _maxContextLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
        ),
      ],
    );
  }

  String _contextExcerpt(String text) {
    final normalized = text.trim();
    if (normalized.length <= _maxContextCharacters) return normalized;

    final wordMatch =
        _findAnchoredContextWordMatch(normalized) ??
        _findFirstContextWordMatch(normalized);

    if (wordMatch == null) {
      final excerpt = normalized
          .substring(0, _maxContextCharacters)
          .trimRight();
      return '$excerpt...';
    }

    final start = (wordMatch.start - _contextLeadCharacters).clamp(
      0,
      normalized.length,
    );
    final end = (start + _maxContextCharacters).clamp(0, normalized.length);

    final prefix = start > 0 ? '...' : '';
    final suffix = end < normalized.length ? '...' : '';
    return '$prefix${normalized.substring(start, end).trim()}$suffix';
  }

  TextSpan _highlightContext(ThemeData theme, String text) {
    final wordMatches = _findContextWordMatches(text);
    if (wordMatches.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(color: theme.colorScheme.onSurface),
      );
    }

    final children = <TextSpan>[];
    var lastIndex = 0;
    for (final wordMatch in wordMatches) {
      if (wordMatch.start > lastIndex) {
        children.add(
          TextSpan(text: text.substring(lastIndex, wordMatch.start)),
        );
      }
      children.add(
        TextSpan(
          text: text.substring(wordMatch.start, wordMatch.end),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      lastIndex = wordMatch.end;
    }
    if (lastIndex < text.length) {
      children.add(TextSpan(text: text.substring(lastIndex)));
    }

    return TextSpan(
      style: TextStyle(color: theme.colorScheme.onSurface),
      children: children,
    );
  }

  RegExpMatch? _findAnchoredContextWordMatch(String text) {
    final start = contextWordStart;
    final end = contextWordEnd;
    if (start == null || end == null) return null;

    for (final match in _findContextWordMatches(text)) {
      if (match.start == start && match.end == end) return match;
    }

    return null;
  }

  RegExpMatch? _findFirstContextWordMatch(String text) {
    return _findContextWordMatches(text).firstOrNull;
  }

  List<RegExpMatch> _findContextWordMatches(String text) {
    final target =
        languageModule?.canonicalize(word) ?? word.toLowerCase().trim();
    if (target.isEmpty) return const [];

    final pattern = languageModule?.wordPattern ?? RegExp(r"[\w']+");
    return pattern.allMatches(text).where((match) {
      final token =
          languageModule?.canonicalize(match.group(0)!) ??
          match.group(0)!.toLowerCase();
      return token == target;
    }).toList();
  }
}

class _StatusHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusHint({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _DictionaryErrorBlock extends StatelessWidget {
  const _DictionaryErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusHint(
          icon: Icons.warning_amber_rounded,
          text: message,
          color: theme.colorScheme.error,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 10),
          FlowButton.secondary(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            child: const Text('重试'),
          ),
        ],
      ],
    );
  }
}

class _EmptyDictionaryState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _EmptyDictionaryState({this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = errorMessage?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未找到释义',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message == null || message.isEmpty ? '请检查拼写或网络连接。' : message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: message == null || message.isEmpty
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                : theme.colorScheme.error,
          ),
        ),
        if (message != null && message.isNotEmpty && onRetry != null) ...[
          const SizedBox(height: 10),
          FlowButton.secondary(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            child: const Text('重试'),
          ),
        ],
      ],
    );
  }
}
