import 'package:flutter/material.dart';

class LogsManager {
  static final List<Map<String, dynamic>> _logs = [];

  static void addLog({required String message, required String source}) {
    final timestamp = DateTime.now().toString();
    _logs.add({
      'message': message,
      'source': source,
      'timestamp': timestamp,
    });
  }

  static List<Map<String, dynamic>> getLogs() {
    return _logs;
  }

  static void clearLogs() {
    _logs.clear();
  }
}

class LogsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _logs = [];

  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  void addLog({required String message, required String source}) {
    final timestamp = DateTime.now().toString();
    _logs.add({
      'message': message,
      'source': source,
      'timestamp': timestamp,
    });
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
