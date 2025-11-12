import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:air/view model/controller/voice_assistant_controller.dart';
import 'package:air/services/logs_manager.dart';
import 'package:air/pages/pc_integration_page.dart';
import 'package:air/pages/email_integration_page.dart';
import 'package:air/pages/whatsapp_integration_page.dart';
import 'package:air/pages/login_page.dart';
import 'package:air/pages/env_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleThemeMode;
  final bool isDarkMode;

  const SettingsPage({Key? key, required this.toggleThemeMode, required this.isDarkMode}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final VoiceAssistantController _voiceController = Get.find();
  bool pcIntegrationEnabled = false;
  bool whatsappAccess = false;
  bool instagramAccess = false;
  bool twitterAccess = false;
  bool emailAutomationEnabled = false;
  bool faceRecognitionEnabled = true;
  bool privacyControlsEnabled = true;
  bool faceIdEnabled = false;
  bool isFaceIdAvailable = false;
  final _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkFaceIdAvailability();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      pcIntegrationEnabled = prefs.getBool('pc_integration_enabled') ?? false;
      emailAutomationEnabled = prefs.getBool('email_automation_enabled') ?? false;
      whatsappAccess = prefs.getBool('whatsapp_access_enabled') ?? false;
      faceIdEnabled = prefs.getBool('face_id_enabled') ?? false;
    });
  }

  Future<void> _checkFaceIdAvailability() async {
    if (Platform.isIOS) {
      try {
        final localAuth = LocalAuthentication();
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        final availableBiometrics = await localAuth.getAvailableBiometrics();
        
        setState(() {
          isFaceIdAvailable = canCheckBiometrics && 
                             availableBiometrics.contains(BiometricType.face);
        });
      } catch (e) {
        print('Error checking Face ID availability: $e');
        setState(() {
          isFaceIdAvailable = false;
        });
      }
    }
  }

  Future<void> _togglePCIntegration(bool value) async {
    final prefs = await _prefs;
    setState(() {
      pcIntegrationEnabled = value;
    });
    await prefs.setBool('pc_integration_enabled', value);

    if (value && mounted) {
      // Navigate to PC Integration page when enabled
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PCIntegrationPage()),
      ).then((_) {
        // When returning from PC Integration page, check if we should disable the toggle
        if (!pcIntegrationEnabled) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _toggleEmailAutomation(bool value) async {
    final prefs = await _prefs;
    setState(() {
      emailAutomationEnabled = value;
    });
    await prefs.setBool('email_automation_enabled', value);

    if (value && mounted) {
      // Navigate to Email Integration page when enabled
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmailIntegrationPage()),
      ).then((_) {
        // When returning from Email Integration page, check if we should disable the toggle
        if (!emailAutomationEnabled) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _toggleWhatsApp(bool value) async {
    final prefs = await _prefs;
    setState(() {
      whatsappAccess = value;
    });
    await prefs.setBool('whatsapp_access_enabled', value);

    if (value && mounted) {
      // Navigate to WhatsApp Integration page when enabled
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WhatsAppIntegrationPage()),
      ).then((_) {
        // When returning from WhatsApp Integration page, check if we should disable the toggle
        if (!whatsappAccess) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _toggleFaceId(bool value) async {
    final prefs = await _prefs;
    setState(() {
      faceIdEnabled = value;
    });
    await prefs.setBool('face_id_enabled', value);
    _logFeatureToggle("Face ID", value);
  }

  void _logFeatureToggle(String featureName, bool value) {
    LogsManager.addLog(
      message: "$featureName ${(value ? 'enabled' : 'disabled')}",
      source: "User",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Voice Assistant Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Obx(() => SwitchListTile(
            title: const Text("English Translation"),
            subtitle: const Text("Convert all speech to English automatically"),
            value: _voiceController.isEnglishTranslationEnabled.value,
            onChanged: (value) {
              _voiceController.isEnglishTranslationEnabled.value = value;
              if (value) {
                _voiceController.isRomanizationEnabled.value = false;
              }
              _logFeatureToggle("English Translation", value);
            },
            secondary: const Icon(Icons.translate),
          )),

          Obx(() => SwitchListTile(
            title: const Text("Romanize Text"),
            subtitle: const Text("Convert non-English text to Roman script"),
            value: _voiceController.isRomanizationEnabled.value,
            onChanged: _voiceController.canEnableRomanization 
              ? (value) {
                  _voiceController.isRomanizationEnabled.value = value;
                  _logFeatureToggle("Text Romanization", value);
                }
              : null,
            secondary: const Icon(Icons.text_format),
          )),

          const Divider(),

          // PC Integration
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PC Integration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable PC Integration'),
            subtitle: const Text('Connect and control AIR from your computer'),
            value: pcIntegrationEnabled,
            onChanged: _togglePCIntegration,
            secondary: const Icon(Icons.computer),
          ),
          if (pcIntegrationEnabled)
            ListTile(
              leading: const SizedBox(width: 40),
              title: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PCIntegrationPage(),
                    ),
                  );
                },
                child: const Text('Open PC Integration Settings'),
              ),
            ),

          const Divider(),

          // Social Media Access
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Social Media Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text("WhatsApp"),
            value: whatsappAccess,
            onChanged: _toggleWhatsApp,
            secondary: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
          ),
          if (whatsappAccess)
            ListTile(
              leading: const SizedBox(width: 40),
              title: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WhatsAppIntegrationPage(),
                    ),
                  );
                },
                child: const Text('Open WhatsApp Integration Settings'),
              ),
            ),
          SwitchListTile(
            title: const Text("Instagram"),
            value: instagramAccess,
            onChanged: (value) {
              setState(() {
                instagramAccess = value;
              });
              _logFeatureToggle("Instagram Access", value);
            },
            secondary: const FaIcon(FontAwesomeIcons.instagram, color: Colors.pink),
          ),
          SwitchListTile(
            title: const Text("Twitter"),
            value: twitterAccess,
            onChanged: (value) {
              setState(() {
                twitterAccess = value;
              });
              _logFeatureToggle("Twitter Access", value);
            },
            secondary: const FaIcon(FontAwesomeIcons.twitter, color: Colors.blue),
          ),

          const Divider(),

          // Email Integration
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Email Integration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Email Automation'),
            subtitle: const Text('Allow AIR to manage your emails'),
            value: emailAutomationEnabled,
            onChanged: _toggleEmailAutomation,
            secondary: const Icon(Icons.email),
          ),
          if (emailAutomationEnabled)
            ListTile(
              leading: const SizedBox(width: 40),
              title: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailIntegrationPage(),
                    ),
                  );
                },
                child: const Text('Open Email Integration Settings'),
              ),
            ),

          const Divider(),

          // Face Recognition
          SwitchListTile(
            title: const Text("Face Recognition"),
            subtitle: const Text("Enable face recognition and registration."),
            value: faceRecognitionEnabled,
            onChanged: (value) {
              setState(() {
                faceRecognitionEnabled = value;
              });
              _logFeatureToggle("Face Recognition", value);
            },
            secondary: const Icon(Icons.face),
          ),

          // Face ID Authentication
          if (isFaceIdAvailable)
            SwitchListTile(
              title: const Text("Face ID Login"),
              subtitle: const Text("Use Face ID for quick authentication"),
              value: faceIdEnabled,
              onChanged: _toggleFaceId,
              secondary: const Icon(Icons.face_retouching_natural),
            ),

          const Divider(),

          // Security Settings
          SwitchListTile(
            title: const Text("Privacy Controls"),
            subtitle: const Text("Admin-only health info and privacy settings."),
            value: privacyControlsEnabled,
            onChanged: (value) {
              setState(() {
                privacyControlsEnabled = value;
              });
              _logFeatureToggle("Privacy Controls", value);
            },
            secondary: const Icon(Icons.security),
          ),

          Obx(() => SwitchListTile(
            title: const Text("Real-time Transcription"),
            subtitle: const Text("Transcribe speech in real-time without stopping"),
            value: _voiceController.isRealtimeTranscriptionEnabled.value,
            onChanged: (value) {
              _voiceController.isRealtimeTranscriptionEnabled.value = value;
              _logFeatureToggle("Real-time Transcription", value);
            },
            secondary: const Icon(Icons.speed),
          )),

          const Divider(),

          // Environment Settings
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('Environment Variables'),
            subtitle: const Text('Configure server URLs and API keys'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnvSettingsPage(),
                ),
              );
            },
          ),

          const Divider(),

          // Account Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: widget.isDarkMode ? Colors.amber : Colors.blue,
            ),
            title: const Text('Theme'),
            subtitle: Text(widget.isDarkMode ? 'Dark Mode' : 'Light Mode'),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.toggleThemeMode();
                _logFeatureToggle("Theme", value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text('Sign out of your account'),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _logout();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Log the logout action
    LogsManager.addLog(
      message: "User logged out",
      source: "Authentication"
    );

    // Clear any stored preferences if needed
    final prefs = await _prefs;
    await prefs.clear();

    // Navigate to login page and clear the navigation stack
    if (mounted) {
              Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              toggleThemeMode: widget.toggleThemeMode,
              isDarkMode: widget.isDarkMode,
            ),
          ),
          (route) => false,
        );
    }
  }
}
