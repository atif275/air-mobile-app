import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:air/services/python_server_service.dart';

class WhisperService {
  final String apiKey;
  static const String endpoint = 'https://api.openai.com/v1/audio/transcriptions';
  final PythonServerService _pythonServer = PythonServerService();

  WhisperService({required this.apiKey});

  Future<String> transcribeAudio(String audioFilePath, {
    bool translateToEnglish = true,
    bool romanizeText = false
  }) async {
    try {
      String transcribedText;
      if (romanizeText) {
        transcribedText = await _romanizeAudio(audioFilePath);
      } else {
        transcribedText = await _transcribeNormal(audioFilePath, translateToEnglish);
      }

      // Send transcribed text to Python server
      if (transcribedText.isNotEmpty) {
        try {
          final success = await _pythonServer.sendTranscribedText(transcribedText);
          if (success) {
            print('Successfully sent to Python server: $transcribedText');
          } else {
            print('Failed to send to Python server');
          }
        } catch (e) {
          print('Error sending to Python server: $e');
        }
      }

      return transcribedText;
    } catch (e) {
      print("Error in transcribeAudio: $e");
      return '';
    }
  }

  Future<String> _transcribeNormal(String audioFilePath, bool translateToEnglish) async {
    final url = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
      })
      ..files.add(await http.MultipartFile.fromPath('file', audioFilePath))
      ..fields['model'] = 'whisper-1'
      ..fields['response_format'] = 'json';

    if (translateToEnglish) {
      request.fields['language'] = 'en';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final text = jsonDecode(responseBody)['text'];
      print("Transcribed Text: $text");
      return text;
    } else {
      print("Whisper API Error: $responseBody");
      return '';
    }
  }

  Future<String> _romanizeAudio(String audioFilePath) async {
    // First get normal transcription
    final transcription = await _transcribeNormal(audioFilePath, false);
    
    // Then romanize using GPT
    final romanizationUrl = Uri.parse('https://api.openai.com/v1/chat/completions');
    final romanizationResponse = await http.post(
      romanizationUrl,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '''You are a translator that converts text to Roman script.
                         For Urdu/Hindi, use common romanization.
                         Keep English words unchanged.
                         Only respond with the romanized text, no explanations.'''
          },
          {
            'role': 'user',
            'content': 'Convert this text to Roman script: $transcription'
          }
        ],
        'temperature': 0.3
      }),
    );

    if (romanizationResponse.statusCode == 200) {
      final jsonResponse = jsonDecode(romanizationResponse.body);
      return jsonResponse['choices'][0]['message']['content'];
    }
    return transcription;
  }
} 