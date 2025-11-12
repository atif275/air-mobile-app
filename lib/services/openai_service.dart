import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? ''; // Load API Key

  Future<String> generateResponse(String userInput) async {
    if (_apiKey.isEmpty) {
      return "API key is missing. Please configure it in the .env file.";
    }

    const String endpoint = "https://api.openai.com/v1/chat/completions";
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        "Authorization": "Bearer $_apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system", 
            "content": """You are a helpful assistant that can understand both English and Roman Urdu.
                         Please respond in the same language as the user's input."""
          },
          {"role": "user", "content": userInput}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["choices"][0]["message"]["content"];
    } else {
      print("OpenAI API Error: ${response.body}");
      return "Sorry, I couldn't process that request.";
    }
  }
}
