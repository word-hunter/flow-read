import '../storage/repositories/reading_time_repository.dart';

class ReadingTimeService {
  ReadingTimeService({
    ReadingTimeRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveReadingTimeRepository(),
       _clock = clock ?? DateTime.now;

  static const _globalKey = '_global_';
  static const _dailyKeyPrefix = '_daily_';

  final ReadingTimeRepository _repository;
  final DateTime Function() _clock;

  int _totalSeconds = 0;
  DateTime? _startTime;
  String? _activeBookId;

  int get totalSeconds => _totalSeconds;
  int get todaySeconds {
    final now = _clock();
    return _repository.secondsFor(_dailyKey(now)) + _activeSecondsForDate(now);
  }

  int secondsForBook(String bookId) => _repository.secondsFor(bookId);

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

  void start([String? bookId]) {
    _startTime = _clock();
    _activeBookId = bookId;
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
    await _putDailyElapsed(startTime, stopTime);
    _startTime = null;
    _activeBookId = null;
  }

  Future<void> close() async {
    await _repository.close();
  }

  int secondsForDate(DateTime date) => _repository.secondsFor(_dailyKey(date));

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
}
