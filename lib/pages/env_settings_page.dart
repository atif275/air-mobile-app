import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:air/services/logs_manager.dart';
import 'package:air/services/env_service.dart';

class EnvSettingsPage extends StatefulWidget {
  const EnvSettingsPage({Key? key}) : super(key: key);

  @override
  _EnvSettingsPageState createState() => _EnvSettingsPageState();
}

class _EnvSettingsPageState extends State<EnvSettingsPage> {
  // Controllers for IP and Port fields for each server
  final Map<String, TextEditingController> _ipControllers = {};
  final Map<String, TextEditingController> _portControllers = {};
  // Controllers for other fields (API key, websocket)
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEnvValues();
  }

  // Parse URL to extract IP and Port
  Map<String, String> _parseUrl(String url) {
    try {
      final uri = Uri.parse(url.trim().replaceAll(RegExp(r'/$'), ''));
      return {
        'ip': uri.host.isEmpty ? 'localhost' : uri.host,
        'port': uri.port == 0 ? '' : uri.port.toString(),
      };
    } catch (e) {
      // If parsing fails, try manual parsing
      final cleanUrl = url.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/$'), '');
      if (cleanUrl.contains(':')) {
        final parts = cleanUrl.split(':');
        return {
          'ip': parts[0].isEmpty ? 'localhost' : parts[0],
          'port': parts.length > 1 ? parts[1] : '',
        };
      }
      return {'ip': cleanUrl.isEmpty ? 'localhost' : cleanUrl, 'port': ''};
    }
  }

  Future<void> _loadEnvValues() async {
    setState(() => _isLoading = true);
    
    // Server URLs that need IP/Port split
    final serverKeys = [
      'PYTHON_SERVER_URL',
      'TASK_SERVER_URL',
      'FILE_MANAGEMENT_URL',
      'WHATSAPP_SERVER_URL',
      'EMAIL_SERVER_URL',
    ];

    // Parse and load server URLs (check SharedPreferences overrides first)
    final envService = EnvService();
    for (var key in serverKeys) {
      final url = await envService.get(key) ?? '';
      final parsed = _parseUrl(url);
      _ipControllers['${key}_IP'] = TextEditingController(text: parsed['ip'] ?? 'localhost');
      _portControllers['${key}_PORT'] = TextEditingController(text: parsed['port'] ?? '');
    }

    // Load other fields (check SharedPreferences overrides first)
    _controllers['OPENAI_API_KEY'] = TextEditingController(
      text: await envService.get('OPENAI_API_KEY') ?? '',
    );
    _controllers['WEBSOCKET_HOST'] = TextEditingController(
      text: await envService.get('WEBSOCKET_HOST') ?? 'localhost',
    );
    _controllers['WEBSOCKET_PORT'] = TextEditingController(
      text: await envService.get('WEBSOCKET_PORT') ?? '8766',
    );

    setState(() => _isLoading = false);
  }

  Future<void> _saveEnvValues() async {
    setState(() => _isSaving = true);

    try {
      final envService = EnvService();

      // Helper function to build URL from IP and Port
      String _buildUrl(String ip, String port) {
        final cleanIp = ip.trim().isEmpty ? 'localhost' : ip.trim();
        final cleanPort = port.trim();
        if (cleanPort.isEmpty) {
          return 'http://$cleanIp';
        }
        return 'http://$cleanIp:$cleanPort';
      }

      // Save all values to SharedPreferences
      await envService.set('OPENAI_API_KEY', _controllers['OPENAI_API_KEY']!.text);
      await envService.set('PYTHON_SERVER_URL', _buildUrl(_ipControllers['PYTHON_SERVER_URL_IP']!.text, _portControllers['PYTHON_SERVER_URL_PORT']!.text));
      await envService.set('TASK_SERVER_URL', _buildUrl(_ipControllers['TASK_SERVER_URL_IP']!.text, _portControllers['TASK_SERVER_URL_PORT']!.text));
      await envService.set('FILE_MANAGEMENT_URL', _buildUrl(_ipControllers['FILE_MANAGEMENT_URL_IP']!.text, _portControllers['FILE_MANAGEMENT_URL_PORT']!.text));
      await envService.set('WHATSAPP_SERVER_URL', _buildUrl(_ipControllers['WHATSAPP_SERVER_URL_IP']!.text, _portControllers['WHATSAPP_SERVER_URL_PORT']!.text));
      await envService.set('EMAIL_SERVER_URL', _buildUrl(_ipControllers['EMAIL_SERVER_URL_IP']!.text, _portControllers['EMAIL_SERVER_URL_PORT']!.text));
      await envService.set('WEBSOCKET_HOST', _controllers['WEBSOCKET_HOST']!.text);
      await envService.set('WEBSOCKET_PORT', _controllers['WEBSOCKET_PORT']!.text);

      LogsManager.addLog(
        message: "Environment variables updated",
        source: "System"
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Environment variables saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LogsManager.addLog(
        message: "Error saving environment variables: $e",
        source: "System"
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var controller in _ipControllers.values) {
      controller.dispose();
    }
    for (var controller in _portControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // OpenAI API Key
                  _buildSection(
                    'OpenAI Configuration',
                    [
                      _buildTextField('OPENAI_API_KEY', 'OpenAI API Key', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Python Backend Server
                  _buildSection(
                    'Python Backend Server',
                    [
                      _buildServerFields('PYTHON_SERVER_URL', 'Python Server', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Task Management Server
                  _buildSection(
                    'Task Management Server',
                    [
                      _buildServerFields('TASK_SERVER_URL', 'Task Server', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // PC Integration Server
                  _buildSection(
                    'PC Integration Server',
                    [
                      _buildServerFields('FILE_MANAGEMENT_URL', 'File Management Server', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // WhatsApp Integration Server
                  _buildSection(
                    'WhatsApp Integration Server',
                    [
                      _buildServerFields('WHATSAPP_SERVER_URL', 'WhatsApp Server', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email Integration Server
                  _buildSection(
                    'Email Integration Server',
                    [
                      _buildServerFields('EMAIL_SERVER_URL', 'Email Server', isDark),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // WebSocket ML Server
                  _buildSection(
                    'WebSocket ML Server',
                    [
                      _buildTextField('WEBSOCKET_HOST', 'WebSocket Host', isDark),
                      const SizedBox(height: 12),
                      _buildTextField('WEBSOCKET_PORT', 'WebSocket Port', isDark),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveEnvValues,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blueGrey[800] : Colors.blueGrey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildServerFields(String key, String serverName, bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _ipControllers['${key}_IP'],
          keyboardType: TextInputType.text,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: '$serverName IP/Host',
            labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
            hintText: 'e.g., localhost or 192.168.1.4',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _portControllers['${key}_PORT'],
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: '$serverName Port',
            labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
            hintText: 'e.g., 5000',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String key, String label, bool isDark) {
    final isPassword = key.contains('API_KEY');
    
    return TextField(
      controller: _controllers[key],
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        hintText: 'Enter $label',
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.blueGrey[400]! : Colors.blueGrey[600]!, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      ),
    );
  }
}

