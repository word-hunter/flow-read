import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../../models/book.dart';
import '../../models/book_difficulty.dart';
import 'reading_provider_riverpod.dart';

@immutable
class CurrentBookState {
  const CurrentBookState({
    this.currentChapter = 0,
    this.readingProgress = 0.0,
    this.readingScrollOffset,
    this.isReading = false,
    this.hasBeenOpened = false,
    this.currentTab = 0,
  });

  final int currentChapter;
  final double readingProgress;
  final double? readingScrollOffset;
  final bool isReading;
  final bool hasBeenOpened;
  final int currentTab;

  CurrentBookState copyWith({
    int? currentChapter,
    double? readingProgress,
    double? readingScrollOffset,
    bool? isReading,
    bool? hasBeenOpened,
    int? currentTab,
    bool clearScrollOffset = false,
  }) {
    return CurrentBookState(
      currentChapter: currentChapter ?? this.currentChapter,
      readingProgress: readingProgress ?? this.readingProgress,
      readingScrollOffset: clearScrollOffset
          ? null
          : (readingScrollOffset ?? this.readingScrollOffset),
      isReading: isReading ?? this.isReading,
      hasBeenOpened: hasBeenOpened ?? this.hasBeenOpened,
      currentTab: currentTab ?? this.currentTab,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentBookState &&
        other.currentChapter == currentChapter &&
        other.readingProgress == readingProgress &&
        other.readingScrollOffset == readingScrollOffset &&
        other.isReading == isReading &&
        other.hasBeenOpened == hasBeenOpened &&
        other.currentTab == currentTab;
  }

  @override
  int get hashCode => Object.hash(
        currentChapter,
        readingProgress,
        readingScrollOffset,
        isReading,
        hasBeenOpened,
        currentTab,
      );
}

class CurrentBookNotifier extends Notifier<CurrentBookState> {
  @override
  CurrentBookState build() {
    final reader = ref.watch(readingProvider);
    return CurrentBookState(
      currentChapter: reader.currentChapter,
      readingProgress: reader.readingProgress,
      readingScrollOffset: reader.readingScrollOffset,
      isReading: reader.isReading,
      hasBeenOpened: reader.hasBeenOpened,
      currentTab: reader.currentTab,
    );
  }

  Book? get book {
    final reader = ref.read(readingProvider);
    return reader.book;
  }

  String? get activeBookId {
    final reader = ref.read(readingProvider);
    return reader.activeBookId;
  }

  AnalysisResult? get result {
    final reader = ref.read(readingProvider);
    return reader.result;
  }

  int get chapterCount {
    final reader = ref.read(readingProvider);
    return reader.chapterCount;
  }

  bool get hasBook {
    final reader = ref.read(readingProvider);
    return reader.hasBook;
  }

  BookDifficultyRating? get currentBookDifficulty {
    final reader = ref.read(readingProvider);
    return reader.currentBookDifficulty;
  }

  // ---- Navigation ----

  void updateReadingProgress(double progress, {double? scrollOffset}) {
    final reader = ref.read(readingProvider);
    reader.updateReadingProgress(progress, scrollOffset: scrollOffset);
  }

  Future<void> goToChapter(int index) async {
    final reader = ref.read(readingProvider);
    await reader.goToChapter(index);
    state = state.copyWith(
      currentChapter: reader.currentChapter,
      readingProgress: reader.readingProgress,
      readingScrollOffset: reader.readingScrollOffset,
    );
  }

  void enterReader() {
    final reader = ref.read(readingProvider);
    reader.enterReader();
    state = state.copyWith(isReading: true, hasBeenOpened: true);
  }

  void exitReader() {
    final reader = ref.read(readingProvider);
    reader.exitReader();
    state = state.copyWith(isReading: false);
  }

  void switchTab(int index) {
    final reader = ref.read(readingProvider);
    reader.switchTab(index);
    state = state.copyWith(currentTab: index);
  }

  void highlightSourceExcerpt(String excerpt) {
    final reader = ref.read(readingProvider);
    reader.highlightSourceExcerpt(excerpt);
  }
}

final currentBookNotifierProvider =
    NotifierProvider<CurrentBookNotifier, CurrentBookState>(
  CurrentBookNotifier.new,
);
