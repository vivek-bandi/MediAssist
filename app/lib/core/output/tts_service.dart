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
    await _flutterTts.stop();
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  Future<void> stop() {
    return _flutterTts.stop();
  }
}
