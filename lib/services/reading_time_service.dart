import 'package:hive/hive.dart';

class ReadingTimeService {
  late Box<int> _box;
  int _totalSeconds = 0;
  DateTime? _startTime;

  int get totalSeconds => _totalSeconds;

  String get displayText {
    if (_totalSeconds < 60) return '$_totalSeconds 秒';
    final minutes = _totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain > 0 ? '$hours 小时 $remain 分钟' : '$hours 小时';
  }

  Future<void> init() async {
    _box = Hive.box<int>('reading_time');
    _totalSeconds = _box.get('_global_', defaultValue: 0) ?? 0;
  }

  void start() {
    _startTime = DateTime.now();
  }

  Future<void> stop() async {
    if (_startTime == null) return;
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    _totalSeconds += elapsed;
    await _box.put('_global_', _totalSeconds);
    _startTime = null;
  }

  Future<void> close() async {
    await _box.close();
  }
}
