import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/reading_time_service.dart';
import '../../services/settings_service.dart';
import '../settings_provider.dart';
import 'services_provider.dart';

@immutable
class ReadingTimeState {
  const ReadingTimeState({
    required this.tick,
    required this.readingTimeSeconds,
    required this.readingTimeDisplay,
    required this.todayReadingTimeSeconds,
    required this.dailyReadingGoalSeconds,
    required this.dailyReadingGoalReached,
    required this.weekReadingTimeSeconds,
    required this.monthReadingTimeSeconds,
    required this.readingGoalDate,
    required this.weekDailyReadingSeconds,
    required this.monthDailyReadingSeconds,
    required this.readingGoalReachedDaysThisWeek,
  });

  final int tick;
  final int readingTimeSeconds;
  final String readingTimeDisplay;
  final int todayReadingTimeSeconds;
  final int dailyReadingGoalSeconds;
  final bool dailyReadingGoalReached;
  final int weekReadingTimeSeconds;
  final int monthReadingTimeSeconds;
  final DateTime readingGoalDate;
  final List<int> weekDailyReadingSeconds;
  final List<int> monthDailyReadingSeconds;
  final int readingGoalReachedDaysThisWeek;

  ReadingTimeState copyWith({int? tick}) {
    return ReadingTimeState(
      tick: tick ?? this.tick,
      readingTimeSeconds: readingTimeSeconds,
      readingTimeDisplay: readingTimeDisplay,
      todayReadingTimeSeconds: todayReadingTimeSeconds,
      dailyReadingGoalSeconds: dailyReadingGoalSeconds,
      dailyReadingGoalReached: dailyReadingGoalReached,
      weekReadingTimeSeconds: weekReadingTimeSeconds,
      monthReadingTimeSeconds: monthReadingTimeSeconds,
      readingGoalDate: readingGoalDate,
      weekDailyReadingSeconds: weekDailyReadingSeconds,
      monthDailyReadingSeconds: monthDailyReadingSeconds,
      readingGoalReachedDaysThisWeek: readingGoalReachedDaysThisWeek,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingTimeState &&
        other.tick == tick;
  }

  @override
  int get hashCode => tick.hashCode;
}

class ReadingTimeNotifier extends Notifier<ReadingTimeState> {
  ReadingTimeService get _time => ref.read(readingTimeServiceProvider);
  SettingsService get _settings => ref.read(settingsProvider);

  int get _dailyGoalSeconds => _settings.dailyReadingGoalSeconds;

  @override
  ReadingTimeState build() {
    return _computeState(0);
  }

  ReadingTimeState _computeState(int tick) {
    return ReadingTimeState(
      tick: tick,
      readingTimeSeconds: _time.totalSeconds,
      readingTimeDisplay: _time.displayText,
      todayReadingTimeSeconds: _time.todaySeconds,
      dailyReadingGoalSeconds: _dailyGoalSeconds,
      dailyReadingGoalReached:
          _dailyGoalSeconds > 0 && _time.todaySeconds >= _dailyGoalSeconds,
      weekReadingTimeSeconds: _time.secondsForWeek(),
      monthReadingTimeSeconds: _time.secondsForMonth(),
      readingGoalDate: _time.currentDate,
      weekDailyReadingSeconds: _time.secondsByDayForWeek(),
      monthDailyReadingSeconds: _time.secondsByDayForMonth(),
      readingGoalReachedDaysThisWeek:
          _time.goalReachedDaysForWeek(_dailyGoalSeconds),
    );
  }

  void refresh() {
    state = _computeState(state.tick + 1);
  }

  int readingTimeSecondsForBook(String bookId) {
    final seconds = _time.secondsForBook(bookId);
    if (seconds > 0) return seconds;
    return _time.totalSeconds;
  }
}

final readingTimeNotifierProvider =
    NotifierProvider<ReadingTimeNotifier, ReadingTimeState>(
  ReadingTimeNotifier.new,
);
