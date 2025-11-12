import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:air/services/env_service.dart';

class PythonServerService {
  final EnvService _envService = EnvService();
  
  Future<String> get baseUrl async => await _envService.get('PYTHON_SERVER_URL') ?? 'http://localhost:5000';
  String _lastBotResponse = "";
  String _lastUserInfo = "";
  String _lastFullResponse = "";

  // Getter methods to access the last response data
  String get lastBotResponse => _lastBotResponse;
  String get lastUserInfo => _lastUserInfo;
  String get lastFullResponse => _lastFullResponse;

  Future<bool> sendTranscribedText(String text) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/transcription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final responseText = jsonResponse['response'];
        _lastBotResponse = responseText;
        _lastFullResponse = responseText;
        _lastUserInfo = '';
        
        print('\n=== Python Server Response ===');
        print('Status: ${jsonResponse['status']}');
        print('Request: $text\n');
        
        // Extract user info and bot response
        if (responseText.contains('NAME=')) {
          // If response contains user info, it comes first
          final userInfoEnd = responseText.indexOf('\n\n');
          if (userInfoEnd != -1) {
            _lastUserInfo = responseText.substring(0, userInfoEnd).trim();
            _lastBotResponse = responseText.substring(userInfoEnd + 2).trim();
            
            print('User Info:');
            print(_lastUserInfo.split('\n').map((line) => '  $line').join('\n'));
            print('\nBot Response:');
            print('  $_lastBotResponse');
          }
        } else {
          // If no user info, just print bot response
          print('Bot Response:');
          print('  $responseText');
        }
        
        return true;
      } else {
        print('\n=== Error ===');
        print('Status Code: ${response.statusCode}');
        
        _lastBotResponse = "I'm sorry, I couldn't process your request. Server returned status code ${response.statusCode}";
        _lastUserInfo = '';
        _lastFullResponse = '';
        
        return false;
      }
    } catch (e) {
      print('\nServer Error: $e');
      
      _lastBotResponse = "I'm having trouble connecting to my server. Please try again later.";
      _lastUserInfo = '';
      _lastFullResponse = '';
      
      return false;
    }
  }
} 