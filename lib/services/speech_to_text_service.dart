import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:get/get.dart';
import 'dart:async';

class SpeechToTextService extends GetxController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  var isListening = false.obs;
  var recognizedText = ''.obs;
  bool _initialized = false;

  Future<bool> initSpeech() async {
    if (_initialized) return true;

    try {
      print("🎤 Starting new listening session...");
      _initialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      return _initialized;
    } catch (e) {
      print("Error initializing speech service: $e");
      _initialized = false;
      return false;
    }
  }

  void _handleStatus(String status) {
    print("🎤 Status: $status");
    switch (status) {
      case 'listening':
        isListening.value = true;
        break;
      case 'notListening':
        isListening.value = false;
        break;
    }
  }

  void _handleError(dynamic error) {
    print("Speech recognition error: $error");
    isListening.value = false;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_initialized) {
      bool initialized = await initSpeech();
      if (!initialized) return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            print("🗣 Words detected: ${result.recognizedWords}");
            recognizedText.value = result.recognizedWords;
            onResult(result.recognizedWords);
          }
        },
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      );
      print("✅ Listening started");
    } catch (e) {
      print("Error in startListening: $e");
      isListening.value = false;
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    print("✅ Stopping listening session");
  }

  void onClose() {
    _speech.cancel();
    super.onClose();
  }
}
