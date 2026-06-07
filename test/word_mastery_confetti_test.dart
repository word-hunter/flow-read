import 'package:flow_read/providers/reading/vocabulary_notifier.dart';
import 'package:flow_read/widgets/word_mastery_confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('word mastery confetti uses a star particle path', () {
    final path = buildWordMasteryStarPath(const Size.square(20));
    final bounds = path.getBounds();

    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(20));
    expect(bounds.bottom, lessThanOrEqualTo(20));
    expect(bounds.width, greaterThan(18));
    expect(bounds.height, greaterThan(18));
    expect(path.contains(const Offset(10, 10)), isTrue);
    expect(path.contains(const Offset(0, 0)), isFalse);
  });

  test('word mastery star colors follow the current theme gradient', () {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF006A6A),
      tertiary: Color(0xFF8A5A00),
      secondary: Color(0xFF5E5CE6),
    );

    final colors = buildWordMasteryStarColors(colorScheme);

    expect(colors, hasLength(9));
    expect(colors.first, colorScheme.primary);
    expect(colors[4], colorScheme.tertiary);
    expect(colors.last, colorScheme.secondary);
  });

  testWidgets(
    'confetti host rebuilds inside focused app without global key churn',
    (tester) async {
      final provider = _ConfettiTestNotifier();

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            vocabularyNotifierProvider.overrideWith(() => provider),
          ],
          child: const MaterialApp(
            home: Focus(
              autofocus: true,
              child: WordMasteryConfettiHost(child: Text('reader')),
            ),
          ),
        ),
      );

      provider.celebrate(const Offset(42, 64));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('reader'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ConfettiTestNotifier extends VocabularyNotifier {
  int _tick = 0;
  Offset? _origin;

  @override
  VocabularyState build() => VocabularyState(
    wordMasteredCelebrationTick: _tick,
    wordMasteredCelebrationOrigin: _origin,
  );

  void celebrate(Offset origin) {
    _origin = origin;
    _tick += 1;
    state = state.copyWith(
      wordMasteredCelebrationTick: _tick,
      wordMasteredCelebrationOrigin: _origin,
    );
  }
}
