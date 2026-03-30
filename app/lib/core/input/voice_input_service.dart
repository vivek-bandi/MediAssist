import 'package:speech_to_text/speech_to_text.dart';

import '../../models/assistant_models.dart';

class VoiceInputService {
  VoiceInputService() : _speechToText = SpeechToText();

  final SpeechToText _speechToText;

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize() {
    return _speechToText.initialize();
  }

  Future<void> startListening({
    required AppLanguage language,
    required void Function(String words) onResult,
  }) async {
    final locale = language == AppLanguage.telugu ? 'te-IN' : 'en-US';
    await _speechToText.listen(
      localeId: locale,
      listenOptions: SpeechListenOptions(
        partialResults: true,
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }
}
