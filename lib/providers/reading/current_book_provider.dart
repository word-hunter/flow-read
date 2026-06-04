import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class CurrentBookController {
  const CurrentBookController(this._reader);

  final ReadingProvider _reader;

  AnalysisResult? get result => _reader.result;
}

final currentBookProvider = Provider<CurrentBookController>((ref) {
  return CurrentBookController(ref.watch(readingProvider));
});
