import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:air/services/env_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class EmailIntegrationPage extends StatefulWidget {
  const EmailIntegrationPage({super.key});

  @override
  State<EmailIntegrationPage> createState() => _EmailIntegrationPageState();
}

class _EmailIntegrationPageState extends State<EmailIntegrationPage> {
  final EnvService _envService = EnvService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceId = iosInfo.identifierForVendor ?? 'ios-device-${DateTime.now().millisecondsSinceEpoch}';
        });
      } else {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceId = androidInfo.id ?? 'android-device-${DateTime.now().millisecondsSinceEpoch}';
        });
      }
      print('Device ID retrieved: $_deviceId');
    } catch (e) {
      print('Error getting device ID: $e');
      // Generate a fallback device ID if we can't get the real one
      setState(() {
        _deviceId = 'fallback-device-${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Ensure we have a device ID, even if it's a fallback one
    if (_deviceId == null) {
      _deviceId = 'fallback-device-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Log the entered credentials for debugging
    print('Attempting to save email settings:');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Device ID: $_deviceId');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serverUrl = await _envService.get('EMAIL_SERVER_URL') ?? 'http://localhost:5004';
      final response = await http.post(
        Uri.parse('$serverUrl/api/email/save-credentials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'app_password': _passwordController.text,
          'device_id': _deviceId,
        }),
      );

      // Log the response for debugging
      print('Server Response Status: ${response.statusCode}');
      print('Server Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        print('Email settings saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email settings saved successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        print('Failed to save email settings: ${data['message']}');
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to save email settings';
        });
      }
    } catch (e) {
      print('Error saving email settings: $e');
      setState(() {
        _errorMessage = 'Failed to connect to email server. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAppPasswordsPage() async {
    const url = 'https://myaccount.google.com/apppasswords';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the app passwords page')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Integration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Up Email Automation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To enable email automation, you need to:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('1. Enable 2-Step Verification in your Google Account'),
              const Text('2. Generate an App Password for AIR'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openAppPasswordsPage,
                child: const Text('Open Google App Passwords Page'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Gmail Address',
                  hintText: 'Enter your Gmail address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Gmail address';
                  }
                  if (!value.endsWith('@gmail.com')) {
                    return 'Please enter a valid Gmail address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'App Password',
                  hintText: 'Enter your 16-digit app password (with spaces)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                inputFormatters: [
                  // Format the input to automatically add spaces
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    
                    // Remove all spaces and get the raw text
                    final text = newValue.text.replaceAll(' ', '');
                    
                    // If the text is longer than 16 characters, truncate it
                    if (text.length > 16) {
                      return oldValue;
                    }
                    
                    // Add a space after every 4 characters
                    final buffer = StringBuffer();
                    for (int i = 0; i < text.length; i++) {
                      if (i > 0 && i % 4 == 0) {
                        buffer.write(' ');
                      }
                      buffer.write(text[i]);
                    }
                    
                    return TextEditingValue(
                      text: buffer.toString(),
                      selection: TextSelection.collapsed(offset: buffer.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your app password';
                  }
                  
                  // Remove all spaces and check the length
                  final passwordWithoutSpaces = value.replaceAll(' ', '');
                  if (passwordWithoutSpaces.length != 16) {
                    return 'App password must be 16 characters long (excluding spaces)';
                  }
                  
                  // Check if the password has the correct format (4 groups of 4 characters)
                  final passwordGroups = value.split(' ');
                  if (passwordGroups.length != 4 || 
                      passwordGroups.any((group) => group.length != 4)) {
                    return 'App password must be in the format: xxxx xxxx xxxx xxxx';
                  }
                  
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 