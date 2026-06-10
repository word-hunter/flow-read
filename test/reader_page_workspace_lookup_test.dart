import 'package:epub_reader_core/epub_reader_core.dart';
import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flow_read/models/analysis_result.dart';
import 'package:flow_read/models/book.dart';
import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/chapter.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/user_vocabulary.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/pages/reader_page.dart';
import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flow_read/providers/reading/services_provider.dart';
import 'package:flow_read/providers/settings_provider.dart';
import 'package:flow_read/services/book_service.dart';
import 'package:flow_read/services/learning_analytics_service.dart';
import 'package:flow_read/services/learning_item_service.dart';
import 'package:flow_read/services/reading_config_service.dart';
import 'package:flow_read/services/reading_time_service.dart';
import 'package:flow_read/services/settings_service.dart';
import 'package:flow_read/services/user_vocabulary_service.dart';
import 'package:flow_read/services/word_context_service.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/database/dao/settings_dao.dart';
import 'package:flow_read/storage/repositories/learning_analytics_repository.dart';
import 'package:flow_read/storage/repositories/learning_item_repository.dart';
import 'package:flow_read/storage/repositories/reading_config_repository.dart';
import 'package:flow_read/storage/repositories/reading_time_repository.dart';
import 'package:flow_read/storage/repositories/user_vocabulary_repository.dart';
import 'package:flow_read/storage/repositories/word_context_repository.dart';
import 'package:flow_read/storage/repositories/word_level_repository.dart';
import 'package:flow_read/widgets/reader/reader_word_sidebar.dart';
import 'package:flow_read/widgets/reader_shell/reader_left_workspace_panel.dart';
import 'package:flow_read/widgets/reader_shell/reader_right_assistant_panel.dart';
import 'package:flow_read/widgets/toc_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop workspace opens dictionary panel when word is tapped', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    try {
      await _pumpWorkspaceReader(
        tester,
        bookshelf: _EmptyBookshelfNotifier.new,
      );

      expect(find.byType(ReaderRightAssistantPanel), findsNothing);

      _tapRichTextSpan(tester, 'river');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(ReaderRightAssistantPanel), findsOneWidget);
      expect(find.byType(ReaderWordSidebar), findsOneWidget);
      expect(find.text('词典'), findsWidgets);
      expect(find.text('river'), findsWidgets);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets(
    'desktop workspace toc button reopens left panel without dropdown',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      try {
        await _pumpWorkspaceReader(
          tester,
          bookshelf: () => _ReaderTestBookshelfNotifier(_bookWithToc()),
        );

        final leftPanel = find.byType(ReaderLeftWorkspacePanel);
        expect(tester.getSize(leftPanel).width, greaterThan(0));
        expect(find.byType(TocDropdownPanel), findsNothing);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 220));

        expect(tester.getSize(leftPanel).width, 0);
        expect(find.byType(TocDropdownPanel), findsNothing);

        await tester.tap(find.byKey(const ValueKey('reader-toolbar-toc')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));

        expect(tester.getSize(leftPanel).width, greaterThan(0));
        expect(find.byType(TocDropdownPanel), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets(
    'desktop workspace keeps side panels during uncached chapter load',
    (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      try {
        await _pumpWorkspaceReader(
          tester,
          bookshelf: () => _ReaderTestBookshelfNotifier(_bookWithToc()),
        );

        _tapRichTextSpan(tester, 'river');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(find.byType(ReaderRightAssistantPanel), findsOneWidget);
        expect(find.byType(ReaderWordSidebar), findsOneWidget);

        await tester.tap(find.byTooltip('下一个目录项'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(ReaderLeftWorkspacePanel), findsOneWidget);
        expect(find.byType(ReaderRightAssistantPanel), findsOneWidget);
        expect(find.byType(ReaderWordSidebar), findsOneWidget);
        expect(find.text('词典'), findsWidgets);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}

Future<void> _pumpWorkspaceReader(
  WidgetTester tester, {
  required BookshelfNotifier Function() bookshelf,
  AnalysisResult? analysis,
}) async {
  final settings = SettingsService(_MemorySettingsDao());
  await settings.init();
  final readingConfig = ReadingConfigService(
    repository: _MemoryReadingConfigRepository(),
  );
  await readingConfig.init();
  final readingTime = ReadingTimeService(
    repository: _MemoryReadingTimeRepository(),
  );
  await readingTime.init();
  final userVocabulary = UserVocabularyService(
    repository: _MemoryUserVocabularyRepository(),
  );
  await userVocabulary.init();
  final wordLevel = WordLevelService(
    repository: _MemoryWordLevelRepository(),
  );
  await wordLevel.init();

  await tester.pumpWidget(
    riverpod.ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        bookshelfNotifierProvider.overrideWith(bookshelf),
        currentBookNotifierProvider.overrideWith(
          () => _ReaderTestCurrentBookNotifier(analysis ?? _analysis()),
        ),
        bookServiceProvider.overrideWithValue(_NoopBookService()),
        readingConfigServiceProvider.overrideWithValue(readingConfig),
        readingTimeServiceProvider.overrideWithValue(readingTime),
        userVocabularyServiceProvider.overrideWithValue(userVocabulary),
        wordLevelServiceProvider.overrideWithValue(wordLevel),
        wordRepositoryProvider.overrideWithValue(_MemoryWordRepository()),
        wordContextServiceProvider.overrideWithValue(
          WordContextService(repository: _MemoryWordContextRepository()),
        ),
        learningAnalyticsServiceProvider.overrideWithValue(
          LearningAnalyticsService(
            repository: _MemoryLearningAnalyticsRepository(),
          ),
        ),
        learningItemServiceProvider.overrideWithValue(
          LearningItemService(repository: _MemoryLearningItemRepository()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const ReaderPage(),
      ),
    ),
  );
  await tester.pump();
}

AnalysisResult _analysis() {
  return const AnalysisResult(
    title: 'Chapter I',
    passageText: 'The river runs through the quiet valley.',
    vocabulary: [
      Vocabulary(
        word: 'river',
        meaning: '河流',
        context: 'The river runs through the quiet valley.',
        familiarity: 0.2,
      ),
    ],
    syntaxPatterns: [],
    comprehension: Comprehension(
      whatHappened: '',
      whyHappened: '',
      implicitMeaning: '',
    ),
    practice: [],
    difficulty: Difficulty(
      vocab: 1,
      syntax: 1,
      inference: 1,
      explanation: '',
    ),
  );
}

Book _bookWithToc() {
  return const Book(
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    chapters: [
      Chapter(
        title: 'Chapter I',
        plainText: 'The river runs through the quiet valley.',
        rawHtml: '',
        href: 'Text/chapter1.xhtml',
      ),
      Chapter(
        title: 'Chapter II',
        plainText: 'The road bends through the city.',
        rawHtml: '',
        href: 'Text/chapter2.xhtml',
      ),
    ],
    toc: [
      EpubTocEntry(
        label: 'Chapter I',
        href: 'Text/chapter1.xhtml',
        playOrder: 1,
      ),
      EpubTocEntry(
        label: 'Chapter II',
        href: 'Text/chapter2.xhtml',
        playOrder: 2,
      ),
    ],
  );
}

class _ReaderTestBookshelfNotifier extends BookshelfNotifier {
  _ReaderTestBookshelfNotifier(this._book);

  final Book _book;

  @override
  BookshelfState build() => BookshelfState(
    activeBookId: 'book-1',
    book: _book,
    books: [
      BookMetadata(
        id: 'book-1',
        title: _book.title,
        author: _book.author,
        sourcePath: 'fixture.epub',
        totalChapters: _book.chapters.length,
      ),
    ],
  );
}

void _tapRichTextSpan(WidgetTester tester, String text) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final recognizer = _findTapRecognizer(richText.text, text);
    if (recognizer != null) {
      recognizer.onTap!();
      return;
    }
  }
  fail('Could not find tappable span "$text".');
}

TapGestureRecognizer? _findTapRecognizer(InlineSpan span, String text) {
  if (span is! TextSpan) return null;
  final recognizer = span.recognizer;
  if (span.text == text && recognizer is TapGestureRecognizer) {
    return recognizer;
  }
  final children = span.children;
  if (children == null) return null;
  for (final child in children) {
    final match = _findTapRecognizer(child, text);
    if (match != null) return match;
  }
  return null;
}

class _ReaderTestCurrentBookNotifier extends CurrentBookNotifier {
  _ReaderTestCurrentBookNotifier(this._result);

  final AnalysisResult _result;

  @override
  CurrentBookState build() => CurrentBookState(
    hasBeenOpened: true,
    result: _result,
  );
}

class _EmptyBookshelfNotifier extends BookshelfNotifier {
  @override
  BookshelfState build() => const BookshelfState();
}

class _NoopBookService extends BookService {
  @override
  List<BookMetadata> get books => const [];

  @override
  Future<void> updateProgress(
    String id,
    int currentChapter,
    double chapterProgress, {
    double? chapterScrollOffset,
  }) async {}
}

class _MemoryWordRepository implements WordRepository {
  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    return DictionaryEntry(
      word: word,
      meanings: [
        Meaning(partOfSpeech: 'n.', definitions: ['河流']),
      ],
      sourceName: 'Test',
    );
  }
}

class _MemorySettingsDao implements SettingsDao {
  final Map<String, String> _values = {};

  @override
  Future<Map<String, String>> allEntries() async => Map.of(_values);

  @override
  Future<void> putValue(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> removeValue(String key) async {
    _values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryReadingConfigRepository implements ReadingConfigRepository {
  final Map<String, String> _values = {};

  @override
  Future<void> init() async {}

  @override
  String getString(String key, {required String defaultValue}) {
    return _values[key] ?? defaultValue;
  }

  @override
  Future<void> putString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> close() async {}
}

class _MemoryReadingTimeRepository implements ReadingTimeRepository {
  final Map<String, int> _values = {};

  @override
  Future<void> init() async {}

  @override
  int secondsFor(String key) => _values[key] ?? 0;

  @override
  Future<void> putSeconds(String key, int seconds) async {
    _values[key] = seconds;
  }

  @override
  Future<void> close() async {}
}

class _MemoryUserVocabularyRepository implements UserVocabularyRepository {
  final Map<String, UserWordStatus> _words = {};

  @override
  Future<void> init() async {}

  @override
  UserWordStatus? getStatus(String word) => _words[word.toLowerCase().trim()];

  @override
  Set<String> wordsWithStatus(UserWordStatus status) => _words.entries
      .where((entry) => entry.value == status)
      .map((entry) => entry.key)
      .toSet();

  @override
  Map<String, UserWordStatus> get allWords => Map.unmodifiable(_words);

  @override
  Future<void> setStatus(String word, UserWordStatus status) async {
    _words[word.toLowerCase().trim()] = status;
  }

  @override
  Future<void> remove(String word) async {
    _words.remove(word.toLowerCase().trim());
  }

  @override
  Future<void> close() async {}
}

class _MemoryWordLevelRepository implements WordLevelRepository {
  final List<WordLevelInfo> _entries = [];

  @override
  Future<void> init() async {}

  @override
  Iterable<WordLevelInfo> get values => _entries;

  @override
  bool get isNotEmpty => _entries.isNotEmpty;

  @override
  bool get imported => true;

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    _entries.addAll(entries);
  }

  @override
  Future<void> markImported() async {}

  @override
  Future<void> close() async {}
}

class _MemoryWordContextRepository implements WordContextRepository {
  final Map<String, String> _values = {};

  @override
  Future<void> init() async {}

  @override
  String? getEncodedExamples(String word) => _values[word];

  @override
  Future<void> putEncodedExamples(String word, String encodedExamples) async {
    _values[word] = encodedExamples;
  }

  @override
  Future<void> close() async {}
}

class _MemoryLearningAnalyticsRepository
    implements LearningAnalyticsRepository {
  final Map<String, int> _values = {};

  @override
  Future<void> init() async {}

  @override
  int countFor(String key) => _values[key] ?? 0;

  @override
  Iterable<String> get keys => _values.keys;

  @override
  Future<void> putCount(String key, int count) async {
    _values[key] = count;
  }

  @override
  Future<void> close() async {}
}

class _MemoryLearningItemRepository implements LearningItemRepository {
  final Map<String, LearningItem> _items = {};

  @override
  Future<void> init() async {}

  @override
  Iterable<LearningItem> get values => _items.values;

  @override
  Iterable<dynamic> get keys => _items.keys;

  @override
  int get length => _items.length;

  @override
  LearningItem? get(dynamic key) => _items[key];

  @override
  Future<void> put(String id, LearningItem item) async {
    _items[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final key in keys) {
      _items.remove(key);
    }
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<void> close() async {}
}
