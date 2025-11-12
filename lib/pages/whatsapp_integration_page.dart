import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:air/services/env_service.dart';
import 'dart:async';

class WhatsAppIntegrationPage extends StatefulWidget {
  const WhatsAppIntegrationPage({Key? key}) : super(key: key);

  @override
  State<WhatsAppIntegrationPage> createState() => _WhatsAppIntegrationPageState();
}

class _WhatsAppIntegrationPageState extends State<WhatsAppIntegrationPage> {
  final EnvService _envService = EnvService();
  bool isConnected = false;
  bool messageSyncEnabled = true;
  bool contactSyncEnabled = true;
  
  // New state variables for connection form
  String selectedCountry = 'United States';
  String phoneNumber = '';
  String selectedCountryCode = '+1';
  
  // Validation state variables
  bool isProcessing = false;
  bool isValidating = false;
  String buttonText = 'Send Request';
  
  // Server response state
  String serverResponse = '';
  bool requestSuccessful = false;
  String verificationCode = '';
  int codeExpiresIn = 0; // seconds
  Timer? _codeTimer;
  Timer? _loginStatusTimer;
  int _pollInterval = 5;
  bool _isPollingLoginStatus = false;
  bool codeExpired = false;
  
  // List of countries with their codes
  final List<Map<String, String>> countries = [
    {'name': 'United States', 'code': '+1'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'Australia', 'code': '+61'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'France', 'code': '+33'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'China', 'code': '+86'},
    {'name': 'Japan', 'code': '+81'},
    {'name': 'Brazil', 'code': '+55'},
    {'name': 'Mexico', 'code': '+52'},
    {'name': 'Spain', 'code': '+34'},
    {'name': 'Italy', 'code': '+39'},
    {'name': 'Netherlands', 'code': '+31'},
    {'name': 'Sweden', 'code': '+46'},
    {'name': 'Norway', 'code': '+47'},
    {'name': 'Denmark', 'code': '+45'},
    {'name': 'Finland', 'code': '+358'},
    {'name': 'Switzerland', 'code': '+41'},
  ];

  // Function to send registration request to Flask server
  Future<bool> _sendRegistrationRequest() async {
    try {
      // Get server URL from environment variables
      final serverUrl = await _envService.get('WHATSAPP_SERVER_URL') ?? 'http://192.168.1.5:8767';
      final registerUrl = '$serverUrl/register';
      
      // Prepare the request data
      final requestData = {
        'country': selectedCountry,
        'phone_number': phoneNumber, // Phone number without country code
      };
      
      print('Sending request to: $registerUrl');
      print('Request data: $requestData');
      
      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          serverResponse = responseData['message'] ?? 'Registration successful';
          requestSuccessful = true;
          verificationCode = responseData['whatsapp_web']?['verification_code'] ?? '';
          codeExpired = false;
          codeExpiresIn = 120;
        });
        _startCodeTimer();
        _startLoginStatusPolling();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          serverResponse = errorData['message'] ?? 'Registration failed';
          requestSuccessful = false;
          verificationCode = '';
          codeExpired = false;
          codeExpiresIn = 0;
        });
        _stopCodeTimer();
        _stopLoginStatusPolling();
        return false;
      }
    } catch (e) {
      print('Error sending registration request: $e');
      setState(() {
        serverResponse = 'Network error: $e';
        requestSuccessful = false;
        verificationCode = '';
        codeExpired = false;
        codeExpiresIn = 0;
      });
      _stopCodeTimer();
      _stopLoginStatusPolling();
      return false;
    }
  }

  void _startLoginStatusPolling() {
    _stopLoginStatusPolling();
    _pollInterval = 5;
    _isPollingLoginStatus = true;
    _loginStatusTimer = Timer.periodic(Duration(seconds: _pollInterval), (timer) {
      _checkLoginStatus();
    });
    // Also do an immediate check
    _checkLoginStatus();
  }

  void _stopLoginStatusPolling() {
    _loginStatusTimer?.cancel();
    _loginStatusTimer = null;
    _isPollingLoginStatus = false;
  }

  Future<void> _checkLoginStatus() async {
    if (codeExpired) {
      _stopLoginStatusPolling();
      return;
    }
    try {
      final serverUrl = await _envService.get('WHATSAPP_SERVER_URL') ?? 'http://192.168.1.5:8767';
      final loginStatusUrl = '$serverUrl/login-status';
      final response = await http.get(Uri.parse(loginStatusUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isLoggedIn = data['is_logged_in'] == true;
        if (isLoggedIn) {
          if (!isConnected) {
            setState(() {
              isConnected = true;
              serverResponse = data['message'] ?? 'Connected to WhatsApp';
            });
          }
          // Change polling interval to 30s if not already
          if (_pollInterval != 30) {
            _pollInterval = 30;
            _loginStatusTimer?.cancel();
            _loginStatusTimer = Timer.periodic(Duration(seconds: _pollInterval), (timer) {
              _checkLoginStatus();
            });
          }
        } else {
          // If previously connected, but now not logged in
          if (isConnected) {
            setState(() {
              isConnected = false;
              serverResponse = 'Not connected. Please enter your phone number to get a new code.';
              verificationCode = '';
              codeExpired = false;
              codeExpiresIn = 0;
            });
            _stopLoginStatusPolling();
            _stopCodeTimer();
          }
        }
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  void _startCodeTimer() {
    _stopCodeTimer();
    if (verificationCode.isEmpty) return;
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (codeExpiresIn > 0) {
        setState(() {
          codeExpiresIn--;
        });
      } else {
        setState(() {
          codeExpired = true;
        });
        _stopCodeTimer();
        _stopLoginStatusPolling();
      }
    });
  }

  void _stopCodeTimer() {
    _codeTimer?.cancel();
    _codeTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _checkInitialLoginStatus();
  }

  Future<void> _checkInitialLoginStatus() async {
    if (isConnected) return;
    try {
      final serverUrl = await _envService.get('WHATSAPP_SERVER_URL') ?? 'http://192.168.1.5:8767';
      final loginStatusUrl = '$serverUrl/login-status';
      final response = await http.get(Uri.parse(loginStatusUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isLoggedIn = data['is_logged_in'] == true;
        if (isLoggedIn) {
          setState(() {
            isConnected = true;
            serverResponse = data['message'] ?? 'Connected to WhatsApp';
          });
        }
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  @override
  void dispose() {
    _stopCodeTimer();
    _stopLoginStatusPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Integration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(),
            if (!isConnected && verificationCode.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Enter this code in WhatsApp "Link with Phone number"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(child: _buildVerificationCodeBoxes(verificationCode, codeExpired)),
              const SizedBox(height: 12),
              if (!codeExpired)
                Text(
                  'Expires in ${_formatDuration(codeExpiresIn)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (codeExpired)
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Request Code Again'),
                  ),
                ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 20),
            
            // Connection Form (only shown when not connected)
            if (!isConnected) ...[
              _buildConnectionForm(),
              const SizedBox(height: 20),
            ],
            
            // Features Section
            _buildFeaturesSection(),
            const SizedBox(height: 12),
            
            // Quick Actions
            _buildQuickActionsSection(),
            const SizedBox(height: 20),
            
            // Statistics Card
            _buildStatisticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade900, // Dark background
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConnected ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected 
                      ? 'Your WhatsApp is successfully integrated'
                      : serverResponse.isNotEmpty 
                        ? serverResponse
                        : 'Connect your WhatsApp account to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  if (serverResponse.isNotEmpty && !isConnected) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Phone: $selectedCountryCode$phoneNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: isConnected,
              onChanged: (isProcessing || isValidating) ? null : (value) {
                setState(() {
                  isConnected = value;
                  if (value) {
                    serverResponse = '';
                  }
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WhatsApp Connection Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Country Selection Dropdown
            const Text(
              'Country',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCountry,
                  isExpanded: true,
                  hint: const Text('Select Country'),
                  items: countries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['name'],
                      child: Text(country['name']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCountry = newValue;
                        // Update country code based on selection
                        selectedCountryCode = countries.firstWhere(
                          (country) => country['name'] == newValue
                        )['code']!;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone Number Input
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Country Code Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Text(
                    selectedCountryCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Phone Number Input
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        phoneNumber = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Send Request Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isProcessing || isValidating) ? null : () async {
                  // Validate inputs
                  if (phoneNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a phone number'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  // Start processing immediately
                  setState(() {
                    isProcessing = true;
                    buttonText = 'Processing...';
                  });
                  
                  // Send request to Flask server immediately
                  final requestFuture = _sendRegistrationRequest();
                  
                  // Wait for max 2 seconds in processing state
                  await Future.delayed(const Duration(seconds: 2));
                  
                  // If still processing (no response yet), switch to validating
                  if (isProcessing) {
                    setState(() {
                      isProcessing = false;
                      isValidating = true;
                      buttonText = 'Validating...';
                    });
                  }
                  
                  // Wait for the actual response from server
                  final success = await requestFuture;
                  
                  // Update state based on server response
                  setState(() {
                    isProcessing = false;
                    isValidating = false;
                    isConnected = success;
                    buttonText = 'Send Request';
                  });
                  
                  // Console log the input values
                  print('Country: $selectedCountry');
                  print('Country Code: $selectedCountryCode');
                  print('Phone Number: $phoneNumber');
                  print('Full Phone: $selectedCountryCode$phoneNumber');
                  print('Server Response: $serverResponse');
                  print('Request Successful: $requestSuccessful');
                  
                  // Show appropriate message based on server response
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Successfully connected to WhatsApp: $selectedCountryCode$phoneNumber'
                        : 'Connection failed: $serverResponse'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isProcessing || isValidating) ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Integration Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildFeatureCard(
              icon: Icons.sync,
              title: 'Message Sync',
              subtitle: 'Real-time sync',
              color: Colors.green,
              isEnabled: messageSyncEnabled,
              onTap: () {
                setState(() {
                  messageSyncEnabled = !messageSyncEnabled;
                });
              },
            ),
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Contact Sync',
              subtitle: 'Import contacts',
              color: Colors.purple,
              isEnabled: contactSyncEnabled,
              onTap: () {
                setState(() {
                  contactSyncEnabled = !contactSyncEnabled;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isEnabled ? color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? color : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? color.withOpacity(0.7) : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnabled ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code,
                label: 'Scan QR',
                color: Colors.green,
                onTap: () {
                  // Open QR scanner
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh,
                label: 'Sync Now',
                color: Colors.blue,
                onTap: () {
                  // Sync messages
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings,
                label: 'Advanced',
                color: Colors.purple,
                onTap: () {
                  // Open advanced settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.message,
                    value: '1,247',
                    label: 'Messages',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    value: '89',
                    label: 'Contacts',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.schedule,
                    value: '24h',
                    label: 'Last Sync',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCodeBoxes(String code, bool disabled) {
    // Ensure code is 8 characters
    final chars = code.padRight(8).substring(0, 8).split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(4, (i) => _buildCodeBox(chars[i], disabled)),
        const SizedBox(width: 16),
        const Text('-', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        ...List.generate(4, (i) => _buildCodeBox(chars[i + 4], disabled)),
      ],
    );
  }

  Widget _buildCodeBox(String char, bool disabled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 44,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[700] : Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          fontSize: 22,
          color: disabled ? Colors.grey[400] : Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
} 