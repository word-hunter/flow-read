import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class ReadingTimeController {
  const ReadingTimeController(this._reader);

  final ReadingProvider _reader;

  int get readingTimeSeconds => _reader.readingTimeSeconds;
  String get readingTimeDisplay => _reader.readingTimeDisplay;
  int get todayReadingTimeSeconds => _reader.todayReadingTimeSeconds;
  int get dailyReadingGoalSeconds => _reader.dailyReadingGoalSeconds;
  bool get dailyReadingGoalReached => _reader.dailyReadingGoalReached;
  int get weekReadingTimeSeconds => _reader.weekReadingTimeSeconds;
  int get monthReadingTimeSeconds => _reader.monthReadingTimeSeconds;
  DateTime get readingGoalDate => _reader.readingGoalDate;
  List<int> get weekDailyReadingSeconds => _reader.weekDailyReadingSeconds;
  List<int> get monthDailyReadingSeconds => _reader.monthDailyReadingSeconds;
  int get readingGoalReachedDaysThisWeek =>
      _reader.readingGoalReachedDaysThisWeek;

  int readingTimeSecondsForBook(String bookId) {
    return _reader.readingTimeSecondsForBook(bookId);
  }
}

final readingTimeProvider = Provider<ReadingTimeController>((ref) {
  return ReadingTimeController(ref.watch(readingProvider));
});
