import 'package:flutter_tts/flutter_tts.dart';

import '../../models/assistant_models.dart';

class TtsService {
  TtsService() : _flutterTts = FlutterTts();

  final FlutterTts _flutterTts;

  Future<void> speak({
    required String text,
    required AppLanguage language,
  }) async {
    final locale = language == AppLanguage.telugu ? 'te-IN' : 'en-US';
    final speechRate = language == AppLanguage.telugu ? 0.45 : 0.34;
    final chunks = _speechChunks(text);
    if (chunks.isEmpty) {
      return;
    }

    await _flutterTts.stop();
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.awaitSpeakCompletion(true);

    for (final chunk in chunks) {
      await _flutterTts.speak(chunk);
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }
  }

  List<String> _speechChunks(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final rawChunks = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (rawChunks.isEmpty) {
      return [normalized];
    }

    return rawChunks;
  }

  Future<void> stop() {
    return _flutterTts.stop();
  }
}
