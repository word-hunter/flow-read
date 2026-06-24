import 'package:flow_ai/flow_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estimates mixed English and Chinese text with safety margin', () {
    const estimator = TokenEstimator(safetyMargin: 0);

    expect(estimator.estimate('Alice follows the rabbit.'), 6);
    expect(estimator.estimate('爱丽丝追着兔子'), 14);
    expect(estimator.estimate('Alice 追着 rabbit'), greaterThan(5));
  });

  test('checks prompt fit with reserved output tokens', () {
    const budget = TokenBudget(
      maxInputTokens: 12,
      reservedOutputTokens: 4,
      estimator: TokenEstimator(safetyMargin: 0),
    );

    expect(budget.availableInputTokens, 8);
    expect(budget.checkFit('short prompt'), isTrue);
    expect(
      budget.checkFit('one two three four five six seven eight nine'),
      isFalse,
    );
  });
}
