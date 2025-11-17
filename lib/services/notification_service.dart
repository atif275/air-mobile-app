import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
// Removed flutter_timezone import - using timezone package directly
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:air/repositories/task_repository.dart';
import 'package:air/models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Channel IDs
  static const String _taskChannelId = 'task_reminders';
  static const String _taskChannelName = 'Task Reminders';
  static const String _taskChannelDescription = 'Notifications for task reminders';

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('NotificationService: Already initialized', name: 'NotificationService');
      return;
    }

    developer.log('NotificationService: Initializing...', name: 'NotificationService');

    // Initialize timezone
    try {
      tz.initializeTimeZones();
      // tz.local will automatically use the system's local timezone
      developer.log('NotificationService: Timezone initialized (using tz.local)', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error initializing timezone: $e', name: 'NotificationService', error: e);
      // Ensure timezones are initialized
      try {
        tz.initializeTimeZones();
      } catch (_) {}
    }

    // Initialize local notifications
    try {
      final androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request permissions separately
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'taskActions',
            actions: [
              DarwinNotificationAction.plain(
                'COMPLETE_TASK',
                'Mark Complete',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain(
                'SNOOZE_TASK',
                'Snooze',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
            options: {
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // Request permissions
      final hasPermissions = await requestPermissions();
      developer.log('NotificationService: Permissions ${hasPermissions ? 'granted' : 'denied'}', name: 'NotificationService');
      
      developer.log('NotificationService: Local notifications initialized', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error initializing notifications: $e', name: 'NotificationService', error: e);
    }

    // Initialize workmanager for background tasks
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      
      // Register periodic task to check for due tasks
      await Workmanager().registerPeriodicTask(
        'taskChecker',
        'checkTasks',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      
      developer.log('NotificationService: Workmanager initialized and periodic task registered', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error initializing workmanager: $e', name: 'NotificationService', error: e);
    }

    _isInitialized = true;
    developer.log('NotificationService: Initialization complete', name: 'NotificationService');
  }

  Future<void> _createNotificationChannel() async {
    final androidChannel = AndroidNotificationChannel(
      _taskChannelId,
      _taskChannelName,
      description: _taskChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    developer.log('NotificationService: Android notification channel created', name: 'NotificationService');
  }

  Future<bool> requestPermissions() async {
    developer.log('NotificationService: Requesting permissions...', name: 'NotificationService');
    
    try {
      // Request system permissions
      final notificationStatus = await Permission.notification.request();
      developer.log(
        'NotificationService: Notification permission status: ${notificationStatus.name}',
        name: 'NotificationService'
      );

      if (notificationStatus.isDenied) {
        developer.log('NotificationService: Notification permission denied', name: 'NotificationService');
        return false;
      }

      // For iOS, we need additional permissions
      if (Platform.isIOS) {
        // Request reminders permission
        final remindersStatus = await Permission.reminders.request();
        developer.log(
          'NotificationService: Reminders permission status: ${remindersStatus.name}',
          name: 'NotificationService'
        );

        // Request calendar permission
        final calendarStatus = await Permission.calendar.request();
        developer.log(
          'NotificationService: Calendar permission status: ${calendarStatus.name}',
          name: 'NotificationService'
        );

        // Request plugin permissions
        final iosGranted = await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
              provisional: false,
            );
        
        developer.log(
          'NotificationService: iOS plugin permissions ${iosGranted == true ? 'granted' : 'denied'}',
          name: 'NotificationService'
        );

        // Return false if any iOS permission is denied
        if (!remindersStatus.isGranted || !calendarStatus.isGranted || iosGranted != true) {
          return false;
        }
      }

      // For Android, request exact alarm permission
      if (Platform.isAndroid) {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        developer.log(
          'NotificationService: Exact alarm permission status: ${alarmStatus.name}',
          name: 'NotificationService'
        );

        if (!alarmStatus.isGranted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('NotificationService: Error requesting permissions: $e', name: 'NotificationService', error: e);
      return false;
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    developer.log(
      'NotificationService: Notification response received - ${response.actionId ?? 'tapped'} - payload: ${response.payload}',
      name: 'NotificationService'
    );

    // Handle different actions
    switch (response.actionId) {
      case 'COMPLETE_TASK':
        // TODO: Implement task completion
        developer.log('NotificationService: Task marked as complete', name: 'NotificationService');
        break;
      case 'SNOOZE_TASK':
        if (response.payload != null) {
          // Reschedule the task notification for 15 minutes later
          final taskId = int.tryParse(response.payload!);
          if (taskId != null) {
            await scheduleTaskNotification(
              id: taskId,
              title: 'Snoozed Task',
              body: 'This task was snoozed for 15 minutes',
              scheduledDate: DateTime.now().add(const Duration(minutes: 15)),
            );
            developer.log('NotificationService: Task snoozed for 15 minutes', name: 'NotificationService');
          }
        }
        break;
      default:
        // Handle notification tap
        developer.log('NotificationService: Notification tapped', name: 'NotificationService');
    }
  }

  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Ensure the service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Cancel any existing notification for this task
      await _notifications.cancel(id);

      // Create the notification details
      final androidDetails = AndroidNotificationDetails(
        _taskChannelId,
        _taskChannelName,
        channelDescription: _taskChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'taskActions',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id.toString(),
      );

      developer.log(
        'NotificationService: Scheduled notification for task $id at ${scheduledDate.toString()}',
        name: 'NotificationService'
      );
    } catch (e) {
      developer.log(
        'NotificationService: Error scheduling notification: $e',
        name: 'NotificationService',
        error: e
      );
    }
  }

  Future<void> cancelTaskNotification(int id) async {
    try {
      await _notifications.cancel(id);
      developer.log('NotificationService: Cancelled notification for task $id', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error cancelling notification: $e', name: 'NotificationService', error: e);
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      developer.log('NotificationService: Cancelled all notifications', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error cancelling all notifications: $e', name: 'NotificationService', error: e);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    developer.log('Background task executed: $taskName', name: 'WorkManager');
    
    switch (taskName) {
      case 'checkTasks':
        try {
          final taskRepo = TaskRepository();
          final tasks = await taskRepo.getAllTasks();
          final notificationService = NotificationService();
          
          for (var task in tasks) {
            if (!task.isCompleted) {
              final now = DateTime.now();
              final dueDate = task.dueDate;
              
              // Schedule notification if task is due within the next hour
              if (dueDate.isAfter(now) && 
                  dueDate.isBefore(now.add(const Duration(hours: 1)))) {
                await notificationService.scheduleTaskNotification(
                  id: int.parse(task.id),
                  title: 'Task Due Soon: ${task.title}',
                  body: task.description,
                  scheduledDate: dueDate,
                );
                developer.log(
                  'Background task: Scheduled notification for task ${task.id}',
                  name: 'WorkManager'
                );
              }
            }
          }
        } catch (e) {
          developer.log(
            'Background task error: $e',
            name: 'WorkManager',
            error: e
          );
        }
        break;
    }
    
    return Future.value(true);
  });
} 