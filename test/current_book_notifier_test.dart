import 'package:flow_read/providers/reading/current_book_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateReadingProgress skips nearly identical scroll positions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var notifications = 0;
    final subscription = container.listen<CurrentBookState>(
      currentBookNotifierProvider,
      (_, _) => notifications += 1,
    );
    addTearDown(subscription.close);

    final notifier = container.read(currentBookNotifierProvider.notifier);
    notifier.updateReadingProgress(0.25, scrollOffset: 100);

    expect(notifications, 1);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.25);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      100,
    );

    notifier.updateReadingProgress(0.2501, scrollOffset: 100.2);

    expect(notifications, 1);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.25);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      100,
    );

    notifier.updateReadingProgress(0.26, scrollOffset: 120);

    expect(notifications, 2);
    expect(container.read(currentBookNotifierProvider).readingProgress, 0.26);
    expect(
      container.read(currentBookNotifierProvider).readingScrollOffset,
      120,
    );
  });
}
