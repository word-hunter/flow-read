import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reading_provider.dart';
import 'reading_provider_riverpod.dart';

class VocabularyController {
  const VocabularyController(this._reader);

  final ReadingProvider _reader;

  int get wordMasteredCelebrationTick => _reader.wordMasteredCelebrationTick;
  String? get wordMasteredCelebrationWord =>
      _reader.wordMasteredCelebrationWord;
  Offset? get wordMasteredCelebrationOrigin =>
      _reader.wordMasteredCelebrationOrigin;
}

final vocabularyProvider = Provider<VocabularyController>((ref) {
  return VocabularyController(ref.watch(readingProvider));
});
