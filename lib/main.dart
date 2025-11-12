import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:air/view%20model/task_view_model.dart';
import 'package:air/services/notification_service.dart';
import 'package:air/services/camera_service.dart';
import 'package:air/pages/login_page.dart';
import 'dart:developer' as developer;
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  // Initialize notification service
  developer.log('Main: Initializing notification service...', name: 'Main');
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request permissions on app start
  await _requestInitialPermissions();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
      ],
      child: const AirApp(),
    ),
  );
}

Future<void> _requestInitialPermissions() async {
  developer.log('Requesting initial permissions...', name: 'Permissions');
  
  // Request notification permission first
  final notificationStatus = await Permission.notification.request();
  developer.log(
    'Notification permission status: ${notificationStatus.name}',
    name: 'Permissions'
  );

  // Request calendar and reminders permissions
  final calendarStatus = await Permission.calendar.request();
  developer.log(
    'Calendar permission status: ${calendarStatus.name}',
    name: 'Permissions'
  );

  final remindersStatus = await Permission.reminders.request();
  developer.log(
    'Reminders permission status: ${remindersStatus.name}',
    name: 'Permissions'
  );

  // Request location permissions
  final locationStatus = await Permission.location.request();
  developer.log(
    'Location permission status: ${locationStatus.name}',
    name: 'Permissions'
  );

  // Request other permissions based on platform
  if (Platform.isIOS) {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.speech,
    ];

    for (var permission in permissions) {
      final status = await permission.request();
      developer.log(
        '${permission.toString()} status: ${status.name}',
        name: 'Permissions'
      );
    }
  }

  // Check if background processing is enabled
  if (Platform.isIOS) {
    final backgroundStatus = await Permission.ignoreBatteryOptimizations.request();
    developer.log(
      'Background processing status: ${backgroundStatus.name}',
      name: 'Permissions'
    );
  }
}

class AirApp extends StatefulWidget {
  const AirApp({Key? key}) : super(key: key);

  @override
  _AirAppState createState() => _AirAppState();
}

class _AirAppState extends State<AirApp> {
  bool isDarkMode = true; // Default to dark mode
  final CameraService _cameraService = CameraService();
  bool _showCamera = false;

  void toggleThemeMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIR App',
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Control theme dynamically
      home: LoginPage(toggleThemeMode: toggleThemeMode, isDarkMode: isDarkMode),
    ); 
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

