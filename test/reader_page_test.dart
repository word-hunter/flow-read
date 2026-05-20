import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/pages/reader_page.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/screens/reading_desk_screen.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/dictionary/word_repository.dart';
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
    );

    expect(provider.selectedWord, 'avoidance');
    expect(
      provider.selectedWordContext,
      'strategic avoidance and social discomfort',
    );
    expect(provider.selectedWordTranslation, 'deliberately avoiding');

    provider.clearWordLookup();
    expect(provider.selectedWordContext, isNull);
  });
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider({bool isReading = false}) : _isReading = isReading;

  final bool _isReading;
  final Book _book = Book(
    title: 'Test Book',
    author: 'Tester',
    chapters: [
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
    ],
  );
  int _todaySeconds = 0;
  int _goalSeconds = 3600;
  int _currentChapter = 0;
  double _readingProgress = 0.0;

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
    notifyListeners();
  }

  @override
  void updateReadingProgress(double progress) {
    _readingProgress = progress.clamp(0.0, 1.0);
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
