import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

abstract class PronunciationService {
  Future<void> speakWord(String word);
  Future<void> stop();

  void dispose() {}
}

class FlutterTtsPronunciationService implements PronunciationService {
  FlutterTtsPronunciationService({FlutterTts? tts})
    : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  @override
  Future<void> speakWord(String word) async {
    final text = _normalizeWord(word);
    if (text.isEmpty) return;

    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(false);
    _configured = true;
  }

  String _normalizeWord(String word) {
    return word.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
