import 'package:air/services/notification_service.dart';
import 'package:air/models/task_model.dart';

class TaskNotificationManager {
  static final TaskNotificationManager _instance = TaskNotificationManager._internal();
  factory TaskNotificationManager() => _instance;
  TaskNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      final int taskId = int.parse(task.id);
      
      // Don't schedule notifications for completed tasks
      if (task.isCompleted) {
        print('TaskNotificationManager: Skipping notification for completed task $taskId');
        return;
      }

      // Convert both dates to UTC for accurate comparison
      final now = DateTime.now().toUtc();
      final dueDate = task.dueDate.toUtc();

      // Don't schedule notifications for past due dates
      if (dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now)) {
        print('TaskNotificationManager: Skipping notification for past/current task $taskId (due: ${task.dueDate})');
        return;
      }

      // Schedule the notification
      await _notificationService.scheduleTaskNotification(
        id: taskId,
        title: 'Task Due: ${task.title}',
        body: task.description,
        scheduledDate: task.dueDate,
      );

      print('TaskNotificationManager: Scheduled notification for task $taskId due at ${task.dueDate.toString()}');
    } catch (e) {
      print('TaskNotificationManager: Error scheduling task notification: $e');
    }
  }

  Future<void> cancelTaskNotification(int taskId) async {
    try {
      await _notificationService.cancelTaskNotification(taskId);
      print('TaskNotificationManager: Cancelled notification for task $taskId');
    } catch (e) {
      print('TaskNotificationManager: Error cancelling task notification: $e');
    }
  }

  Future<void> updateTaskNotification(Task task) async {
    try {
      final int taskId = int.parse(task.id);
      
      // Cancel existing notification
      await cancelTaskNotification(taskId);
      
      // Schedule new notification if needed
      await scheduleTaskNotification(task);
      
      print('TaskNotificationManager: Updated notification for task $taskId');
    } catch (e) {
      print('TaskNotificationManager: Error updating task notification: $e');
    }
  }
} 