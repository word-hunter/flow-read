import 'dart:ui' show PointerDeviceKind;

import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/content_block.dart';
import 'package:flow_read/pages/reader_page.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/reading_desk_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/dictionary/word_repository.dart';
import 'package:flow_read/widgets/toc_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('resets reading scroll position after changing chapter', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    expect(find.textContaining('第一章顶部标记00'), findsOneWidget);
    expect(find.text('位置 1 / 2 · 0%'), findsOneWidget);
    expect(find.byTooltip('上一页'), findsNothing);
    expect(find.byTooltip('下一页'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.textContaining('第一章顶部标记00'), findsNothing);

    await provider.goToChapter(1);
    await tester.pumpAndSettle();

    expect(find.textContaining('第二章顶部标记00'), findsOneWidget);
  });

  testWidgets('restores saved reading scroll position when reopening', (
    tester,
  ) async {
    final provider = _FakeReadingProvider(initialProgress: 0.6);
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('位置 1 / 2 · 60%'), findsOneWidget);
    expect(find.textContaining('第一章顶部标记00'), findsNothing);
  });

  testWidgets('uses saved scroll offset when reopening', (tester) async {
    final provider = _FakeReadingProvider(
      initialProgress: 0.12,
      initialScrollOffset: 900,
    );
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1));
    await tester.pump();

    expect(provider.readingScrollOffset, greaterThan(800));
  });

  testWidgets('supports arrow keys for scrolling and chapter navigation', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );
    await tester.pump();

    expect(provider.currentChapter, 0);
    expect(provider.readingProgress, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(provider.currentChapter, 0);
    expect(provider.readingProgress, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(provider.currentChapter, 1);
    expect(find.textContaining('第二章顶部标记00'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(provider.currentChapter, 0);
    expect(find.textContaining('第一章顶部标记00'), findsOneWidget);
  });

  testWidgets('uses a bottom sheet table of contents on compact reader', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.tap(find.byTooltip('目录'));
    await tester.pumpAndSettle();

    expect(find.byType(TocBottomSheet), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('共 2 节 · 当前第 1 节'), findsOneWidget);
    expect(find.text('2 项'), findsNothing);
    expect(find.text('Chapter Two'), findsOneWidget);
  });

  testWidgets('uses an anchored table of contents menu on wide reader', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.tap(find.byTooltip('目录'));
    await tester.pumpAndSettle();

    expect(find.byType(TocDropdownPanel), findsOneWidget);
    expect(find.byType(TocBottomSheet), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.text('共 2 节 · 当前第 1 节'), findsOneWidget);

    await tester.tap(find.text('Chapter Two'));
    await tester.pumpAndSettle();

    expect(provider.currentChapter, 1);
    expect(find.byType(TocDropdownPanel), findsNothing);
  });

  testWidgets('reader toolbar buttons expose hover styling on desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    for (final icon in [
      Icons.arrow_back,
      Icons.menu,
      Icons.chevron_right,
      Icons.vertical_split_outlined,
      Icons.search,
      Icons.text_fields,
      Icons.bookmark_outline,
    ]) {
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icon).first,
      );
      final hoverColor = button.style?.backgroundColor?.resolve({
        WidgetState.hovered,
      });
      expect(hoverColor, isNotNull, reason: '$icon has no hover background');
      expect(
        hoverColor,
        isNot(Colors.transparent),
        reason: '$icon hover is transparent',
      );
    }

    final moreButton = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    final moreHoverColor = moreButton.style?.backgroundColor?.resolve({
      WidgetState.hovered,
    });
    expect(moreHoverColor, isNotNull);
    expect(moreHoverColor, isNot(Colors.transparent));
  });

  testWidgets('table of contents items show a desktop hover state', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.tap(find.byTooltip('目录'));
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('toc-chapter-tile-1'));
    final hoverOverlay = find.byKey(
      const ValueKey('toc-chapter-hover-overlay-1'),
    );
    expect(tester.widget<AnimatedOpacity>(hoverOverlay).opacity, 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 160));

    expect(tester.widget<AnimatedOpacity>(hoverOverlay).opacity, 1);

    await mouse.removePointer();
  });

  testWidgets('opening anchored table of contents preserves reader scroll', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    expect(find.textContaining('第一章顶部标记00'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.textContaining('第一章顶部标记00'), findsNothing);
    expect(provider.readingScrollOffset, greaterThan(0));

    await tester.tap(find.byTooltip('目录'));
    await tester.pumpAndSettle();

    expect(find.byType(TocDropdownPanel), findsOneWidget);
    expect(find.textContaining('第一章顶部标记00'), findsNothing);
    expect(provider.readingScrollOffset, greaterThan(0));
  });

  testWidgets('opens table of contents near the current chapter', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider(
      chapters: _manyChapters(30),
      initialChapter: 17,
    );
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.tap(find.byTooltip('目录'));
    await tester.pumpAndSettle();

    final dropdown = find.byType(TocDropdownPanel);
    expect(find.text('共 30 节 · 当前第 18 节'), findsOneWidget);
    expect(
      find.descendant(of: dropdown, matching: find.text('Chapter 18')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dropdown, matching: find.text('Chapter 1')),
      findsNothing,
    );
  });

  testWidgets(
    'uses an opening snippet when table of contents titles are generic',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 760);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = _FakeReadingProvider(
        chapters: const [
          Chapter(
            title: 'Section 1',
            plainText:
                'Well, go straight to the office then, Elizabeth said. I will give you your room number.',
            rawHtml: '',
          ),
          Chapter(
            title: 'Section 2',
            plainText: 'Trouble at school arrived before lunch.',
            rawHtml: '',
          ),
        ],
      );
      final settings = SettingsService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReadingProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: const MaterialApp(home: Scaffold(body: ReaderPage())),
        ),
      );

      await tester.tap(find.byTooltip('目录'));
      await tester.pumpAndSettle();

      expect(
        find.text('Well, go straight to the office then, Elizabeth...'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TocDropdownPanel),
          matching: find.text('Section 1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'skips leading image placeholders in generic table of contents titles',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 760);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = _FakeReadingProvider(
        chapters: [
          Chapter(
            title: 'Section 1',
            plainText:
                'image Kirby had always danced. She could not remember standing still.',
            rawHtml: '',
            blocks: [
              ImageBlock(src: 'chapter-1.jpg', alt: 'image'),
              TextBlock(
                type: BlockType.paragraph,
                spans: const [
                  StyledText(
                    'Kirby had always danced. She could not remember standing still.',
                  ),
                ],
              ),
            ],
          ),
          const Chapter(
            title: 'Section 2',
            plainText: 'image Trouble arrived before lunch.',
            rawHtml: '',
          ),
        ],
      );
      final settings = SettingsService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReadingProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: const MaterialApp(home: Scaffold(body: ReaderPage())),
        ),
      );

      await tester.tap(find.byTooltip('目录'));
      await tester.pumpAndSettle();

      final dropdown = find.byType(TocDropdownPanel);
      expect(
        find.descendant(
          of: dropdown,
          matching: find.text(
            'Kirby had always danced. She could not remember...',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dropdown,
          matching: find.textContaining('image Kirby'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('shows the full reader more menu', (tester) async {
    final provider = _FakeReadingProvider();
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    final previousItem = find.text('上一个目录项');
    expect(previousItem, findsOneWidget);
    expect(tester.getSize(previousItem).width, greaterThan(70));
    expect(find.text('AI 总结当前内容'), findsNothing);
    expect(find.text('生成练习题'), findsNothing);
    expect(find.text('历史书签'), findsOneWidget);
  });

  testWidgets('shows a prompt when the daily reading goal is reached', (
    tester,
  ) async {
    final provider = _FakeReadingProvider(isReading: true)
      ..setDailyGoalState(todaySeconds: 55, goalSeconds: 60);
    final settings = SettingsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: ReaderPage())),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.textContaining('今日阅读目标已达成'), findsNothing);

    provider.setDailyGoalState(todaySeconds: 60, goalSeconds: 60);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    expect(find.text('今日阅读目标已达成：1 分钟'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('reading desk navigation is localized and theme-aware', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();
    final settings = SettingsService();
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReadingProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: const ReadingDeskScreen(),
        ),
      ),
    );

    expect(find.text('阅读'), findsOneWidget);
    expect(find.text('词汇'), findsOneWidget);
    expect(find.text('训练'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('Reader'), findsNothing);
    expect(find.text('Vocab'), findsNothing);
    expect(find.text('Training'), findsNothing);
    expect(find.text('Stats'), findsNothing);

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.indicatorColor, colorScheme.primary.withValues(alpha: 0.14));
    final navTheme = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    expect(
      navTheme.data.iconTheme?.resolve({WidgetState.selected})?.color,
      colorScheme.primary,
    );
    expect(
      nav.labelTextStyle?.resolve({WidgetState.selected})?.color,
      colorScheme.primary,
    );
  });

  test('lookupWord keeps source context for the learning panel', () async {
    final provider = ReadingProvider()
      ..setWordRepository(const _FakeWordRepository());

    await provider.lookupWord(
      'avoidance',
      contextText: 'strategic avoidance and social discomfort',
      contextWordStart: 10,
      contextWordEnd: 19,
    );

    expect(provider.selectedWord, 'avoidance');
    expect(
      provider.selectedWordContext,
      'strategic avoidance and social discomfort',
    );
    expect(provider.selectedWordContextStart, 10);
    expect(provider.selectedWordContextEnd, 19);
    expect(provider.selectedWordTranslation, 'deliberately avoiding');

    provider.clearWordLookup();
    expect(provider.selectedWordContext, isNull);
    expect(provider.selectedWordContextStart, isNull);
    expect(provider.selectedWordContextEnd, isNull);
  });
}

List<Chapter> _manyChapters(int count) {
  return List.generate(
    count,
    (index) => Chapter(
      title: 'Chapter ${index + 1}',
      plainText: 'Opening line for chapter ${index + 1}.',
      rawHtml: '',
    ),
  );
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider({
    bool isReading = false,
    double initialProgress = 0.0,
    double? initialScrollOffset,
    List<Chapter>? chapters,
    int initialChapter = 0,
  }) : _isReading = isReading,
       _readingProgress = initialProgress.clamp(0.0, 1.0),
       _readingScrollOffset = initialScrollOffset {
    _book = Book(
      title: 'Test Book',
      author: 'Tester',
      chapters: chapters ?? _defaultChapters(),
    );
    if (_book.chapters.isNotEmpty) {
      _currentChapter = initialChapter.clamp(0, _book.chapters.length - 1);
    }
  }

  final bool _isReading;
  late final Book _book;
  int _todaySeconds = 0;
  int _goalSeconds = 3600;
  int _currentChapter = 0;
  double _readingProgress = 0.0;
  double? _readingScrollOffset;

  static List<Chapter> _defaultChapters() {
    return [
      Chapter(
        title: 'Chapter One',
        plainText: _chapterText('第一章顶部标记'),
        rawHtml: '',
      ),
      Chapter(
        title: 'Chapter Two',
        plainText: _chapterText('第二章顶部标记'),
        rawHtml: '',
      ),
    ];
  }

  void setDailyGoalState({
    required int todaySeconds,
    required int goalSeconds,
  }) {
    _todaySeconds = todaySeconds;
    _goalSeconds = goalSeconds;
  }

  @override
  Book? get book => _book;

  @override
  String? get activeBookId => 'test-book';

  @override
  AnalysisResult? get result => _analysisFor(_book.chapters[_currentChapter]);

  @override
  int get currentChapter => _currentChapter;

  @override
  double get readingProgress => _readingProgress;

  @override
  double? get readingScrollOffset => _readingScrollOffset;

  @override
  bool get hasBook => true;

  @override
  bool get isReading => _isReading;

  @override
  int get todayReadingTimeSeconds => _todaySeconds;

  @override
  int get dailyReadingGoalSeconds => _goalSeconds;

  @override
  int get chapterCount => _book.chapters.length;

  @override
  double get fontSize => 16;

  @override
  double get lineHeight => 1.5;

  @override
  String get fontFamily => 'Serif';

  @override
  String get readingTheme => 'light';

  @override
  String get searchQuery => '';

  @override
  Future<void> goToChapter(int index) async {
    _currentChapter = index;
    _readingProgress = 0.0;
    _readingScrollOffset = 0.0;
    notifyListeners();
  }

  @override
  void updateReadingProgress(double progress, {double? scrollOffset}) {
    _readingProgress = progress.clamp(0.0, 1.0);
    if (scrollOffset != null) {
      _readingScrollOffset = scrollOffset;
    }
  }

  @override
  bool isCurrentPositionBookmarked() => false;

  static String _chapterText(String marker) {
    final filler = List.filled(120, '内容').join();
    return List.generate(
      45,
      (index) => '0 $marker${index.toString().padLeft(2, '0')} $filler',
    ).join('\n\n');
  }

  static AnalysisResult _analysisFor(Chapter chapter) {
    return AnalysisResult(
      passageText: chapter.plainText,
      title: chapter.title,
      vocabulary: const [],
      knownWords: const {},
      learningWords: const {},
      syntaxPatterns: const [],
      comprehension: const Comprehension(
        whatHappened: '',
        whyHappened: '',
        implicitMeaning: '',
      ),
      practice: const [],
      difficulty: const Difficulty(
        vocab: 0,
        syntax: 0,
        inference: 0,
        explanation: '',
      ),
    );
  }
}

class _FakeWordRepository implements WordRepository {
  const _FakeWordRepository();

  @override
  Future<DictionaryEntry?> lookup(String word) async {
    return DictionaryEntry(
      word: word,
      phonetic: "/əˈvɔɪdəns/",
      meanings: const [
        Meaning(partOfSpeech: 'n.', definitions: ['deliberately avoiding']),
      ],
      sourceName: 'Fixture',
    );
  }
}
