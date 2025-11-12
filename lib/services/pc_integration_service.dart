import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:air/services/env_service.dart';

class PCIntegrationService {
  static final PCIntegrationService _instance = PCIntegrationService._internal();
  factory PCIntegrationService() => _instance;
  PCIntegrationService._internal();

  final EnvService _envService = EnvService();
  
  Future<String> get baseUrl async => await _envService.get('FILE_MANAGEMENT_URL') ?? 'http://192.168.1.4:5003';
  String? _connectionId;
  Timer? _statusCheckTimer;
  final _deviceInfo = DeviceInfoPlugin();
  final _prefs = SharedPreferences.getInstance();
  bool _isServerAvailable = true;

  // Stream controller for connection status updates
  final _connectionStatusController = StreamController<Map<String, dynamic>>.broadcast();

  // Getter for connection status stream
  Stream<Map<String, dynamic>> get connectionStatusStream => _connectionStatusController.stream;

  Future<String> _getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return 'unknown';
  }

  Future<void> _saveConnectionState() async {
    final prefs = await _prefs;
    await prefs.setString('pc_connection_id', _connectionId ?? '');
  }

  Future<void> _loadConnectionState() async {
    final prefs = await _prefs;
    _connectionId = prefs.getString('pc_connection_id');
    if (_connectionId?.isNotEmpty == true) {
      _startStatusCheck();
    }
  }

  Future<bool> _checkServerAvailability() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse(url));
      _isServerAvailable = response.statusCode == 200;
      return _isServerAvailable;
    } catch (e) {
      _isServerAvailable = false;
      return false;
    }
  }

  Future<Map<String, dynamic>> connect({
    required String sshCommand,
    required String password,
    required String osType,
  }) async {
    try {
      if (!await _checkServerAvailability()) {
        return {
          'status': 'failed',
          'connection_id': null,
          'device_name': null,
          'error': 'Server is not available',
        };
      }

      final deviceId = await _getDeviceId();
      final requestBody = {
        'ssh_command': sshCommand,
        'password': password,
        'os_type': osType,
        'device_id': deviceId,
      };

      print('Sending connect request with body: ${jsonEncode(requestBody)}');

      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/api/pc/connect'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Connect response status: ${response.statusCode}');
      print('Connect response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'connected') {
          _connectionId = data['connection_id'];
          await _saveConnectionState();
          _startStatusCheck();
          return data;
        }
      }

      return {
        'status': 'failed',
        'connection_id': null,
        'device_name': null,
        'error': response.statusCode == 200 
            ? jsonDecode(response.body)['error'] ?? 'Unknown error'
            : 'Server returned status code: ${response.statusCode}',
      };
    } catch (e) {
      print('Connect error: $e');
      return {
        'status': 'failed',
        'connection_id': null,
        'device_name': null,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> checkStatus() async {
    if (_connectionId == null) {
      return {
        'status': 'disconnected',
        'device_name': null,
        'last_seen': null,
        'error': 'No active connection'
      };
    }

    if (!await _checkServerAvailability()) {
      return {
        'status': 'disconnected',
        'device_name': null,
        'last_seen': null,
        'error': 'Server is not available'
      };
    }

    try {
      final url = await baseUrl;
      final response = await http.get(
        Uri.parse('$url/api/pc/status?connection_id=$_connectionId'),
      );

      print('Status response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Map the new response structure to our expected format
        final mappedData = {
          'status': data['state'] ?? 'disconnected',
          'device_name': data['device_name'],
          'last_seen': data['last_seen'],
          'error': data['error'],
          'metrics': data['metrics'],
        };

        _connectionStatusController.add(mappedData);
        return mappedData;
      }

      final errorData = {
        'status': 'disconnected',
        'device_name': null,
        'last_seen': null,
        'error': 'Server returned status code: ${response.statusCode}'
      };
      _connectionStatusController.add(errorData);
      return errorData;
    } catch (e) {
      print('Status check error: $e');
      final errorData = {
        'status': 'disconnected',
        'device_name': null,
        'last_seen': null,
        'error': e.toString()
      };
      _connectionStatusController.add(errorData);
      return errorData;
    }
  }

  Future<Map<String, dynamic>> disconnect() async {
    if (_connectionId == null) {
      return {'status': 'disconnected', 'error': null};
    }

    try {
      if (await _checkServerAvailability()) {
        final url = await baseUrl;
        final response = await http.post(
          Uri.parse('$url/api/pc/disconnect'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'connection_id': _connectionId,
          }),
        );
      }

      _stopStatusCheck();
      _connectionId = null;
      await _saveConnectionState();
      return {'status': 'disconnected', 'error': null};
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await checkStatus();
      if (status['status'] != 'connected') {
        _stopStatusCheck();
        _connectionId = null;
        await _saveConnectionState();
      }
    });
  }

  void _stopStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  Future<void> initialize() async {
    await _loadConnectionState();
  }

  void dispose() {
    _stopStatusCheck();
    _connectionStatusController.close();
  }
} 