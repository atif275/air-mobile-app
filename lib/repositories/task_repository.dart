import 'package:air/models/task_model.dart';
import 'package:air/services/task2_service.dart';

class TaskRepository {
  final Task2Service _taskService = Task2Service();
  
  // Get all tasks with optional filtering
  Future<List<Task>> getAllTasks({
    TaskCategory? category,
    TaskStatus? status,
    bool? completed,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      return await _taskService.getAllTasks(
        category: category,
        status: status,
        completed: completed,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      print('Repository error getting all tasks: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // Get a specific task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return await _taskService.getTaskById(taskId);
    } catch (e) {
      print('Repository error getting task by ID: $e');
      return null;
    }
  }
  
  // Create a new task
  Future<Task?> createTask(Task task) async {
    try {
      return await _taskService.createTask(task);
    } catch (e) {
      print('Repository error creating task: $e');
      return null;
    }
  }
  
  // Update an existing task
  Future<Task?> updateTask(Task task) async {
    try {
      return await _taskService.updateTask(task);
    } catch (e) {
      print('Repository error updating task: $e');
      return null;
    }
  }
  
  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      return await _taskService.deleteTask(taskId);
    } catch (e) {
      print('Repository error deleting task: $e');
      return false;
    }
  }
  
  // Get tasks within a date range
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _taskService.getTasksByDateRange(startDate, endDate);
    } catch (e) {
      print('Repository error getting tasks by date range: $e');
      return [];
    }
  }
  
  // Get today's tasks
  Future<List<Task>> getTodayTasks() async {
    try {
      return await _taskService.getTodayTasks();
    } catch (e) {
      print('Repository error getting today\'s tasks: $e');
      return [];
    }
  }
  
  // Toggle task completion status
  Future<Task?> toggleTaskCompletion(String taskId) async {
    try {
      return await _taskService.toggleTaskCompletion(taskId);
    } catch (e) {
      print('Repository error toggling task completion: $e');
      return null;
    }
  }
  
  // Get tasks by category
  Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    return getAllTasks(category: category);
  }
  
  // Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    return getAllTasks(status: status);
  }
  
  // Get completed tasks
  Future<List<Task>> getCompletedTasks() async {
    return getAllTasks(completed: true);
  }
  
  // Get pending tasks
  Future<List<Task>> getPendingTasks() async {
    return getAllTasks(completed: false);
  }
  
  // Get upcoming tasks (due after today)
  Future<List<Task>> getUpcomingTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getAllTasks(dueAfter: today, completed: false);
  }
} 