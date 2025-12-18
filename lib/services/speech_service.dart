import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
    return _isAvailable;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isAvailable) {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'es_ES', // Default to Spanish as requested
        listenFor: const Duration(minutes: 1), // permitir dictado largo
        pauseFor: const Duration(
          seconds: 2,
        ), // espera 2s de silencio antes de finalizar
      );
    } else {
      print("Speech recognition not available");
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
