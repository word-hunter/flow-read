import '../storage/repositories/reading_time_repository.dart';

class ReadingTimeService {
  ReadingTimeService({
    ReadingTimeRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? HiveReadingTimeRepository(),
       _clock = clock ?? DateTime.now;

  static const _globalKey = '_global_';

  final ReadingTimeRepository _repository;
  final DateTime Function() _clock;

  int _totalSeconds = 0;
  DateTime? _startTime;
  String? _activeBookId;

  int get totalSeconds => _totalSeconds;

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
    final elapsed = _clock().difference(_startTime!).inSeconds;
    _totalSeconds += elapsed;
    await _repository.putSeconds(_globalKey, _totalSeconds);
    final bookId = _activeBookId;
    if (bookId != null) {
      await _repository.putSeconds(bookId, secondsForBook(bookId) + elapsed);
    }
    _startTime = null;
    _activeBookId = null;
  }

  Future<void> close() async {
    await _repository.close();
  }
}
