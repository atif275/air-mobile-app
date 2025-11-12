import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:air/services/pc_integration_service.dart';

class PCIntegrationPage extends StatefulWidget {
  const PCIntegrationPage({Key? key}) : super(key: key);

  @override
  State<PCIntegrationPage> createState() => _PCIntegrationPageState();
}

class _PCIntegrationPageState extends State<PCIntegrationPage> {
  final _pcService = PCIntegrationService();
  bool _isConnecting = false;
  String _connectionStatus = 'Not Connected';
  String? _connectedDeviceName;
  String? _lastError;
  StreamSubscription? _connectionStatusSubscription;
  
  final TextEditingController _sshCommandController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedOS = 'macOS'; // Default selection
  late List<String> _currentInstructions;

  // Map OS to zip file names
  final Map<String, String> _osScripts = {
    'macOS': 'air_connect_macos_linux.zip',
    'Windows': 'air_connect_windows.zip',
    'Linux': 'air_connect_macos_linux.zip',
  };
  
  // Map OS to script and instruction file names
  final Map<String, Map<String, String>> _osFiles = {
    'macOS': {
      'script': 'start_ssh_tunnel.sh',
      'instructions': 'steps.txt'
    },
    'Windows': {
      'script': 'start_ssh_tunnel.ps1',
      'instructions': 'steps_windows.txt'
    },
    'Linux': {
      'script': 'start_ssh_tunnel.sh',
      'instructions': 'steps.txt'
    },
  };

  List<String> _getInstructions(String os) {
    final scriptName = _osFiles[os]!['script'];
    final instructionsFile = _osFiles[os]!['instructions'];

    switch (os) {
      case 'macOS':
        return [
          'Download and extract the connection package',
          'Open Terminal on your Mac',
          'Navigate to the extracted folder',
          'Run: chmod +x ./$scriptName',
          'Execute: ./$scriptName',
          'Follow the instructions in $instructionsFile',
          'Copy the SSH command generated',
          'Paste the SSH command below',
          'Enter your Mac\'s password',
        ];
      case 'Windows':
        return [
          'Download and extract the connection package',
          'Open PowerShell as Administrator',
          'Navigate to the extracted folder',
          'Execute the script: ./$scriptName',
          'Follow the instructions in $instructionsFile',
          'Copy the SSH command generated',
          'Paste the SSH command below',
          'Enter your Windows password',
        ];
      case 'Linux':
        return [
          'Download and extract the connection package',
          'Open Terminal',
          'Navigate to the extracted folder',
          'Run: chmod +x ./$scriptName',
          'Execute: ./$scriptName',
          'Follow the instructions in $instructionsFile',
          'Copy the SSH command generated',
          'Paste the SSH command below',
          'Enter your Linux user password',
        ];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentInstructions = _getInstructions(_selectedOS);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _pcService.initialize();
    _connectionStatusSubscription = _pcService.connectionStatusStream.listen((status) {
      setState(() {
        _connectionStatus = status['status'] == 'connected' ? 'Connected' : 'Disconnected';
        _connectedDeviceName = status['device_name'];
        if (status['error'] != null) {
          _lastError = status['error'];
        }
      });
    });
  }

  void _updateOS(String newOS) {
    setState(() {
      _selectedOS = newOS;
      _currentInstructions = _getInstructions(newOS);
    });
  }

  Future<void> _connect() async {
    if (_sshCommandController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _lastError = null;
    });

    try {
      final result = await _pcService.connect(
        sshCommand: _sshCommandController.text,
        password: _passwordController.text,
        osType: _selectedOS,
      );

      setState(() {
        _isConnecting = false;
        if (result['status'] == 'connected') {
          _connectionStatus = 'Connected';
          _connectedDeviceName = result['device_name'];
          _lastError = null;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to computer!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _connectionStatus = 'Failed';
          _lastError = result['error'] ?? 'Unknown error occurred';
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: ${_lastError}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Failed';
        _lastError = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final result = await _pcService.disconnect();
      
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Disconnected';
        _connectedDeviceName = null;
        if (result['error'] != null) {
          _lastError = result['error'];
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _lastError = e.toString();
      });
    }
  }

  Future<void> _downloadAndShareScript() async {
    try {
      // Get the zip file name for the selected OS
      final zipFileName = _osScripts[_selectedOS]!;
      
      // Load the zip file from assets
      final ByteData data = await rootBundle.load('assets/scripts/$zipFileName');
      final List<int> bytes = data.buffer.asUint8List();
      
      // Get temporary directory to store the file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$zipFileName');
      
      // Write the file
      await file.writeAsBytes(bytes);
      
      // Share the zip file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AIR Connection Package for $_selectedOS\n\n' +
             'Please extract this package and follow the instructions in ${_osFiles[_selectedOS]!['instructions']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection package downloaded successfully! Please extract and follow the instructions.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download connection package: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Integration'),
        elevation: 0,
        actions: [
          if (_connectionStatus == 'Connected')
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Connection Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _connectionStatus == 'Connected'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _connectionStatus == 'Connected'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              _connectionStatus,
                              style: TextStyle(
                                color: _connectionStatus == 'Connected'
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_connectedDeviceName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Connected to: $_connectedDeviceName',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // OS Selection
              const Text(
                'Select Your Computer\'s Operating System',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOS,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: ['macOS', 'Windows', 'Linux'].map((String os) {
                      return DropdownMenuItem<String>(
                        value: os,
                        child: Row(
                          children: [
                            Icon(
                              os == 'Windows' 
                                ? Icons.window 
                                : os == 'macOS' 
                                  ? Icons.apple 
                                  : Icons.computer,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(os),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateOS(newValue);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Download Package Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadAndShareScript,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Connection Package'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              const Text(
                'Connection Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentInstructions.length,
                itemBuilder: (context, index) {
                  return _buildInstructionStep(
                    index + 1,
                    _currentInstructions[index],
                  );
                },
              ),

              const SizedBox(height: 24),

              // SSH Command Input
              TextField(
                controller: _sshCommandController,
                decoration: InputDecoration(
                  labelText: 'SSH Command',
                  hintText: 'Paste the SSH command here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      final clipboardData = await Clipboard.getData('text/plain');
                      if (clipboardData?.text != null) {
                        _sshCommandController.text = clipboardData!.text!;
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Computer Password',
                  hintText: 'Enter your computer\'s password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_lastError != null && _connectionStatus != 'Connected')
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Connect Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isConnecting || _connectionStatus == 'Connected'
                      ? null
                      : _connect,
                  icon: _isConnecting
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.computer),
                  label: Text(_isConnecting 
                      ? 'Connecting...' 
                      : _connectionStatus == 'Connected'
                          ? 'Connected'
                          : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sshCommandController.dispose();
    _passwordController.dispose();
    _connectionStatusSubscription?.cancel();
    _pcService.dispose();
    super.dispose();
  }
} 