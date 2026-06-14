import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

abstract class PronunciationService {
  Future<void> speakWord(
    String word, {
    String? audioUrl,
    String languageCode,
  });
  Future<void> stop();

  void dispose() {}
}

class FlutterTtsPronunciationService implements PronunciationService {
  FlutterTtsPronunciationService({FlutterTts? tts, AudioPlayer? audioPlayer})
    : _tts = tts ?? FlutterTts(),
      _audioPlayer = audioPlayer ?? AudioPlayer();

  final FlutterTts _tts;
  final AudioPlayer _audioPlayer;
  String? _configuredLanguage;

  static const _jpdbAudioXorKey = [0x06, 0x23, 0x54, 0x0f];

  @override
  Future<void> speakWord(
    String word, {
    String? audioUrl,
    String languageCode = 'en',
  }) async {
    final text = _normalizeWord(word);
    if (text.isEmpty) return;

    await stop();

    if (audioUrl != null && audioUrl.isNotEmpty) {
      final played = await _playJpdbAudio(audioUrl);
      if (played) return;
    }

    await _speakWithTts(text, languageCode);
  }

  Future<bool> _playJpdbAudio(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-Access': 'please don\'t steal these files'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 400) return false;

      final bytes = Uint8List.fromList(response.bodyBytes);
      if (bytes.length < 4) return false;

      for (var i = 0; i < 4; i++) {
        bytes[i] ^= _jpdbAudioXorKey[i];
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/jpdb_audio.ogg');
      await tempFile.writeAsBytes(bytes);

      await _audioPlayer.setFilePath(tempFile.path);
      await _audioPlayer.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _speakWithTts(String text, String languageCode) async {
    final ttsLanguage = _ttsLanguageFor(languageCode);
    await _ensureConfigured(ttsLanguage);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
    _audioPlayer.dispose();
  }

  Future<void> _ensureConfigured(String language) async {
    if (_configuredLanguage == language) return;

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(language.startsWith('ja') ? 0.5 : 0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(false);
    _configuredLanguage = language;
  }

  String _ttsLanguageFor(String languageCode) {
    return switch (languageCode) {
      'ja' => 'ja-JP',
      'en' => 'en-US',
      _ => 'en-US',
    };
  }

  String _normalizeWord(String word) {
    return word.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
