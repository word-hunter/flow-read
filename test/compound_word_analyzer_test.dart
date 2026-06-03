import 'package:flow_read/services/compound_word_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CompoundWordAnalyzer analyzer;

  setUp(() {
    const knownWords = {
      'god',
      'gods',
      'wood',
      'dragon',
      'glass',
      'king',
      'road',
      'to',
    };
    const meanings = {
      'gods': '众神',
      'wood': '树林',
      'dragon': '龙',
      'glass': '玻璃',
      'king': '国王',
      'road': '道路',
    };
    analyzer = CompoundWordAnalyzer(
      isKnownWord: knownWords.contains,
      getMeaning: (word) => meanings[word],
    );
  });

  test('splits known compound words into components', () {
    final godswood = analyzer.analyze('godswood');
    final dragonglass = analyzer.analyze('dragonglass');

    expect(godswood?.components, ['gods', 'wood']);
    expect(godswood?.componentMeanings, ['众神', '树林']);
    expect(godswood?.confidence, greaterThan(0.8));
    expect(dragonglass?.components, ['dragon', 'glass']);
    expect(dragonglass?.confidence, greaterThan(0.8));
  });

  test('ignores connector s between known components', () {
    final result = analyzer.analyze('kingsroad');

    expect(result?.components, ['king', 'road']);
  });

  test('does not split unknown or misleading words', () {
    expect(analyzer.analyze('together'), isNull);
    expect(analyzer.analyze('melancholy'), isNull);
    expect(analyzer.analyze('wood'), isNull);
  });
}
