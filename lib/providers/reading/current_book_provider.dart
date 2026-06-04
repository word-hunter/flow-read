import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../../models/book.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class CurrentBookController {
  const CurrentBookController(this._reader);

  final ReadingProvider _reader;

  Book? get book => _reader.book;
  AnalysisResult? get result => _reader.result;
  int get currentChapter => _reader.currentChapter;
  int get chapterCount => _reader.chapterCount;
  bool get isReading => _reader.isReading;
  bool get hasBook => _reader.hasBook;
  bool get hasBeenOpened => _reader.hasBeenOpened;
  int get currentTab => _reader.currentTab;

  Future<void> goToChapter(int index) {
    return _reader.goToChapter(index);
  }

  void switchTab(int index) {
    _reader.switchTab(index);
  }

  void highlightSourceExcerpt(String excerpt) {
    _reader.highlightSourceExcerpt(excerpt);
  }
}

final currentBookProvider = Provider<CurrentBookController>((ref) {
  return CurrentBookController(ref.watch(readingProvider));
});
