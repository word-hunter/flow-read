part of 'reader_page.dart';

mixin ReaderDailyGoalMixin on riverpod.ConsumerState<ReaderPage> {
  bool get _searchSheetOpen;

  bool _dailyGoalPromptShown = false;
  bool _wasDailyGoalReached = false;
  Timer? _dailyGoalCheckTimer;
  Timer? _readingReminderHideTimer;
  String? _readingReminderMessage;

  // ignore: unused_element
  void _syncDailyGoalWatcher(
    CurrentBookState currentBookState,
    ReadingTimeState readingTime,
  ) {
    if (!currentBookState.isReading) {
      _dailyGoalCheckTimer?.cancel();
      _dailyGoalCheckTimer = null;
      _dailyGoalPromptShown = false;
      _wasDailyGoalReached = readingTime.dailyReadingGoalReached;
      return;
    }

    if (_dailyGoalCheckTimer != null) return;
    _wasDailyGoalReached = readingTime.dailyReadingGoalReached;
    _dailyGoalCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkDailyReadingGoal(),
    );
  }

  void _checkDailyReadingGoal() {
    if (!mounted) return;
    final readingTime = ref.read(readingTimeNotifierProvider);
    final reached = readingTime.dailyReadingGoalReached;
    if (!reached) {
      _wasDailyGoalReached = false;
      _dailyGoalPromptShown = false;
      return;
    }
    if (_wasDailyGoalReached || _dailyGoalPromptShown) return;

    _wasDailyGoalReached = true;
    _dailyGoalPromptShown = true;
    final goalText = _formatGoalDuration(readingTime.dailyReadingGoalSeconds);
    _showReadingReminder('今日阅读目标已达成：$goalText');
  }

  void _showReadingReminder(String message) {
    _readingReminderHideTimer?.cancel();
    if (!mounted) return;
    setState(() => _readingReminderMessage = message);
    _readingReminderHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _readingReminderMessage = null);
    });
  }

  void _hideReadingReminder() {
    _readingReminderHideTimer?.cancel();
    _readingReminderHideTimer = null;
    if (_readingReminderMessage == null || !mounted) return;
    setState(() => _readingReminderMessage = null);
  }

  String _formatGoalDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (remain == 0) return '$hours 小时';
    return '$hours 小时 $remain 分钟';
  }

  Widget _buildReadingReminder(ThemeData theme) {
    final message = _readingReminderMessage;
    final visible = message != null && !_searchSheetOpen;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _disposeDailyGoalWatcher() {
    _dailyGoalCheckTimer?.cancel();
    _readingReminderHideTimer?.cancel();
  }
}
