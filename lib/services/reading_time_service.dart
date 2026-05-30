import '../storage/repositories/reading_time_repository.dart';

class ReadingTimeService {
  ReadingTimeService({
    ReadingTimeRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveReadingTimeRepository(),
       _clock = clock ?? DateTime.now;

  static const _globalKey = '_global_';
  static const _dailyKeyPrefix = '_daily_';
  static const _chapterKeyPrefix = '_chapter_';

  final ReadingTimeRepository _repository;
  final DateTime Function() _clock;

  int _totalSeconds = 0;
  DateTime? _startTime;
  String? _activeBookId;
  int? _activeChapterIndex;

  int get totalSeconds => _totalSeconds;
  DateTime get currentDate => _clock();

  int get todaySeconds {
    final now = _clock();
    return _repository.secondsFor(_dailyKey(now)) + _activeSecondsForDate(now);
  }

  int secondsForBook(String bookId) => _repository.secondsFor(bookId);

  int secondsForChapter(String bookId, int chapterIndex) {
    return _repository.secondsFor(_chapterKey(bookId, chapterIndex));
  }

  String get displayText {
    if (_totalSeconds < 60) return '$_totalSeconds 秒';
    final minutes = _totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours 小时 $remain 分钟' : '$hours 小时';
  }

  Future<void> init() async {
    await _repository.init();
    _totalSeconds = _repository.secondsFor(_globalKey);
  }

  void start([String? bookId, int? chapterIndex]) {
    _startTime = _clock();
    _activeBookId = bookId;
    _activeChapterIndex = chapterIndex;
  }

  Future<void> switchTarget(String? bookId, int? chapterIndex) async {
    if (_startTime == null) {
      _activeBookId = bookId;
      _activeChapterIndex = chapterIndex;
      return;
    }
    await stop();
    start(bookId, chapterIndex);
  }

  Future<void> stop() async {
    if (_startTime == null) return;
    final startTime = _startTime!;
    final stopTime = _clock();
    final elapsed = stopTime.difference(startTime).inSeconds;
    _totalSeconds += elapsed;
    await _repository.putSeconds(_globalKey, _totalSeconds);
    final bookId = _activeBookId;
    if (bookId != null) {
      await _repository.putSeconds(bookId, secondsForBook(bookId) + elapsed);
    }
    final chapterIndex = _activeChapterIndex;
    if (bookId != null && chapterIndex != null) {
      final key = _chapterKey(bookId, chapterIndex);
      await _repository.putSeconds(key, _repository.secondsFor(key) + elapsed);
    }
    await _putDailyElapsed(startTime, stopTime);
    _startTime = null;
    _activeBookId = null;
    _activeChapterIndex = null;
  }

  Future<void> close() async {
    await _repository.close();
  }

  int secondsForDate(DateTime date) => _repository.secondsFor(_dailyKey(date));

  int secondsForWeek([DateTime? date]) {
    final target = date ?? _clock();
    final start = weekStartFor(target);
    var total = 0;
    for (var i = 0; i < 7; i += 1) {
      final day = start.add(Duration(days: i));
      total += secondsForDate(day);
      total += _activeSecondsForDate(day);
    }
    return total;
  }

  List<int> secondsByDayForWeek([DateTime? date]) {
    final target = date ?? _clock();
    final start = weekStartFor(target);
    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return secondsForDate(day) + _activeSecondsForDate(day);
    }, growable: false);
  }

  int secondsForMonth([DateTime? date]) {
    final target = date ?? _clock();
    return secondsByDayForMonth(target).fold(0, (total, day) => total + day);
  }

  List<int> secondsByDayForMonth([DateTime? date]) {
    final target = date ?? _clock();
    final daysInMonth = daysInMonthFor(target);
    return List.generate(daysInMonth, (index) {
      final day = DateTime(target.year, target.month, index + 1);
      return secondsForDate(day) + _activeSecondsForDate(day);
    }, growable: false);
  }

  int goalReachedDaysForWeek(int dailyGoalSeconds, [DateTime? date]) {
    if (dailyGoalSeconds <= 0) return 0;
    final target = date ?? _clock();
    final start = weekStartFor(target);
    var reached = 0;
    for (var i = 0; i < 7; i += 1) {
      if (secondsForDate(start.add(Duration(days: i))) >= dailyGoalSeconds) {
        reached += 1;
      }
    }
    if (todaySeconds >= dailyGoalSeconds &&
        _sameDay(target, _clock()) &&
        secondsForDate(target) < dailyGoalSeconds) {
      reached += 1;
    }
    return reached.clamp(0, 7).toInt();
  }

  static DateTime weekStartFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static int daysInMonthFor(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _activeSecondsForDate(DateTime date) {
    final start = _startTime;
    if (start == null) return 0;
    final now = _clock();
    if (now.isBefore(start)) return 0;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final segmentStart = start.isAfter(dayStart) ? start : dayStart;
    final segmentEnd = now.isBefore(dayEnd) ? now : dayEnd;
    if (!segmentEnd.isAfter(segmentStart)) return 0;
    return segmentEnd.difference(segmentStart).inSeconds;
  }

  Future<void> _putDailyElapsed(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return;

    var cursor = start;
    while (cursor.isBefore(end)) {
      final nextDay = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
      ).add(const Duration(days: 1));
      final segmentEnd = end.isBefore(nextDay) ? end : nextDay;
      final elapsed = segmentEnd.difference(cursor).inSeconds;
      if (elapsed > 0) {
        final key = _dailyKey(cursor);
        await _repository.putSeconds(
          key,
          _repository.secondsFor(key) + elapsed,
        );
      }
      cursor = segmentEnd;
    }
  }

  String _dailyKey(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$_dailyKeyPrefix${date.year}-${two(date.month)}-${two(date.day)}';
  }

  String _chapterKey(String bookId, int chapterIndex) {
    return '$_chapterKeyPrefix${Uri.encodeComponent(bookId)}_$chapterIndex';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
