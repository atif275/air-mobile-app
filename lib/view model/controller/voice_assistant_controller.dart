import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:air/services/speech_to_text_service.dart';
import 'package:air/services/text_to_speech_service.dart';
import 'package:air/services/openai_service.dart';
import 'package:air/services/whisper_service.dart';
import 'package:air/services/audio_recorder_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:air/services/python_server_service.dart';


class VoiceAssistantController extends GetxController {
  final SpeechToTextService _speechService = SpeechToTextService();
  final TextToSpeechService _textToSpeechService = TextToSpeechService();
  final OpenAIService _openAIService = OpenAIService();
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  late final WhisperService _whisperService;
  final PythonServerService _pythonServer = PythonServerService();

  // Observable variables
  final isListening = false.obs;
  final isSpeaking = false.obs;
  final userSpeech = ''.obs;
  final botResponse = ''.obs;
  final isInitialized = false.obs;
  final isEnglishTranslationEnabled = true.obs;
  final isRomanizationEnabled = false.obs;
  final isRealtimeTranscriptionEnabled = false.obs;

  Timer? _transcriptionTimer;

  // Add dependency check
  bool get canEnableRomanization => !isEnglishTranslationEnabled.value;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _whisperService = WhisperService(
      apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
    );
  }

  Future<void> _initializeServices() async {
    try {
      bool initialized = await _speechService.initSpeech();
      isInitialized.value = initialized;
      print("Speech service initialized: $initialized");
    } catch (e) {
      print("Error initializing speech service: $e");
      isInitialized.value = false;
    }
  }

  Future<void> startListening() async {
    try {
      if (!isInitialized.value) {
        await _initializeServices();
      }

      isListening.value = true;
      userSpeech.value = '';
      
      if (isRealtimeTranscriptionEnabled.value) {
        await _audioRecorder.startRecording(onSilence: () async {
          final audioPath = await _audioRecorder.stopRecording();
          if (audioPath != null) {
            final transcription = await _whisperService.transcribeAudio(
              audioPath,
              translateToEnglish: isEnglishTranslationEnabled.value,
              romanizeText: !isEnglishTranslationEnabled.value && isRomanizationEnabled.value
            );
            if (transcription.isNotEmpty) {
              userSpeech.value = transcription;
              await processUserSpeech(transcription);
              await _audioRecorder.startRecording(onSilence: () {});
            }
          }
        });
      } else {
        await _audioRecorder.startRecording();
      }
    } catch (e) {
      print("Error in startListening: $e");
      isListening.value = false;
    }
  }

  Future<void> stopListening() async {
    try {
      _transcriptionTimer?.cancel();
      isListening.value = false;
      final audioPath = await _audioRecorder.stopRecording();
      
      if (audioPath != null && !isRealtimeTranscriptionEnabled.value) {
        final transcription = await _whisperService.transcribeAudio(
          audioPath,
          translateToEnglish: isEnglishTranslationEnabled.value,
          romanizeText: !isEnglishTranslationEnabled.value && isRomanizationEnabled.value
        );
        userSpeech.value = transcription;
        await processUserSpeech(transcription);
      }
      
      await File(audioPath ?? '').delete();
    } catch (e) {
      print("Error stopping listening: $e");
    }
  }

  Future<void> processUserSpeech(String userInput) async {
  if (userInput.isEmpty) return;

  try {
    final language = _detectLanguage(userInput);
    
    print("\n=== Speech Processing ===");
    print("Language Detected: $language");
    print("Original Text: $userInput");
    
    if (isEnglishTranslationEnabled.value) {
      print("Translation Enabled: Yes");
    } else {
      print("Translation Enabled: No");
    }
    
    // Send to Python server
    await sendToPythonServer(userInput);
  } catch (e) {
    print("Error processing speech: $e");
  }
}

  String _detectLanguage(String text) {
    // Urdu specific characters and patterns
    if (RegExp(r'[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text) &&
        RegExp(r'[ں|ہ|ے|ۓ|ؤ|ئ]').hasMatch(text)) {
      return 'ur';
    }
    // Arabic specific characters
    else if (RegExp(r'[\u0600-\u06FF]').hasMatch(text) &&
             !RegExp(r'[ں|ہ|ے|ۓ|ؤ|ئ]').hasMatch(text)) {
      return 'ar';
    }
    // Hindi specific characters
    else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      return 'hi';
    }
    return 'en';
  }

  void stopSpeaking() async {
    if (isSpeaking.value) {
      await _textToSpeechService.stop();
      isSpeaking.value = false;
    }
  }

  @override
  void onClose() {
    _transcriptionTimer?.cancel();
    _audioRecorder.dispose();
    _speechService.onClose();
    stopSpeaking();
    super.onClose();
  }



  void toggleTranslation() {
    isEnglishTranslationEnabled.value = !isEnglishTranslationEnabled.value;
    print("Translation ${isEnglishTranslationEnabled.value ? 'enabled' : 'disabled'}");
  }

  Future<void> sendToPythonServer(String transcribedText) async {
  try {
    print("\n=== Server Communication ===");
    final success = await _pythonServer.sendTranscribedText(transcribedText);
    if (success) {
      print('Status: Success');
      print('Request: $transcribedText');
      // The response logging is handled in python_server_service.dart
    } else {
      print('Status: Failed');
      print('Error: Unable to communicate with server');
    }
  } catch (e) {
    print('Status: Error');
    print('Details: $e');
  }
}
}
