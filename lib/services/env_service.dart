import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvService {
  static final EnvService _instance = EnvService._internal();
  factory EnvService() => _instance;
  EnvService._internal();

  static const String _prefsPrefix = 'env_override_';

  // Get environment variable - checks SharedPreferences first, then dotenv
  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString('$_prefsPrefix$key');
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return dotenv.env[key];
  }

  // Set environment variable override in SharedPreferences
  Future<void> set(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$key', value);
  }

  // Remove override (fallback to .env)
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix$key');
  }

  // Clear all overrides
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_prefsPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

