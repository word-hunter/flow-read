import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/pages/reader_page.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flutter/material.dart';
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

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.textContaining('第一章顶部标记00'), findsNothing);

    await provider.goToChapter(1);
    await tester.pumpAndSettle();

    expect(find.textContaining('第二章顶部标记00'), findsOneWidget);
  });
}

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider()
    : _book = Book(
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

  final Book _book;
  int _currentChapter = 0;
  double _readingProgress = 0.0;

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
