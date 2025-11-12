import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:air/models/task_model.dart';
import 'package:air/services/env_service.dart';
import 'package:intl/intl.dart';

class Task2Service {
  // Singleton pattern
  static final Task2Service _instance = Task2Service._internal();
  factory Task2Service() => _instance;
  Task2Service._internal();

  final EnvService _envService = EnvService();

  // Base URL from .env file or SharedPreferences
  Future<String> get baseUrl async => await _envService.get('TASK_SERVER_URL') ?? 'http://192.168.247.31:5002';

  // Format date to ISO 8601 string
  String _formatDate(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  // Parse date from ISO 8601 string
  DateTime _parseDate(String dateString) {
    return DateTime.parse(dateString).toLocal();
  }

  // Convert Task to JSON
  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'due_date': _formatDate(task.dueDate),
      'priority': task.priority.toString().split('.').last.toLowerCase(),
      'category': task.category.toString().split('.').last,
      'is_completed': task.isCompleted,
      'status': task.status.toString().split('.').last.toLowerCase(),
      'notes': task.notes,
      'location': task.location,
      'assigned_to': task.assignedTo,
    };
  }

  // Convert JSON to Task
  Task _jsonToTask(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: _parseDate(json['due_date']),
      priority: _parsePriority(json['priority']),
      category: _parseCategory(json['category']),
      isCompleted: json['is_completed'],
      status: _parseStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      notes: json['notes'],
      location: json['location'],
      assignedTo: json['assigned_to'],
    );
  }

  // Parse priority from string
  TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  // Parse category from string
  TaskCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return TaskCategory.personal;
      case 'health':
        return TaskCategory.health;
      case 'robotmaintenance':
      case 'robot':
        return TaskCategory.robotMaintenance;
      case 'medication':
        return TaskCategory.medication;
      case 'appointment':
        return TaskCategory.appointment;
      default:
        return TaskCategory.personal;
    }
  }

  // Parse status from string
  TaskStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'scheduled':
        return TaskStatus.scheduled;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  // Handle HTTP errors
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error']['message'] ?? 'Unknown error occurred');
    }
  }

  // GET /api/tasks - Get all tasks with filtering and sorting
  Future<List<Task>> getAllTasks({
    TaskCategory? category,
    TaskStatus? status,
    bool? completed,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? sortBy,
    String? sortOrder,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{};
    
    if (category != null) {
      queryParams['category'] = category.toString().split('.').last.toLowerCase();
    }
    
    if (status != null) {
      queryParams['status'] = status.toString().split('.').last.toLowerCase();
    }
    
    if (completed != null) {
      queryParams['completed'] = completed.toString();
    }
    
    if (dueBefore != null) {
      queryParams['due_before'] = _formatDate(dueBefore);
    }
    
    if (dueAfter != null) {
      queryParams['due_after'] = _formatDate(dueAfter);
    }
    
    if (sortBy != null) {
      queryParams['sort_by'] = sortBy;
    }
    
    if (sortOrder != null) {
      queryParams['sort_order'] = sortOrder;
    }
    
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((taskJson) => _jsonToTask(taskJson))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      rethrow;
    }
  }

  // GET /api/tasks/{task_id} - Get a specific task by ID
  Future<Task> getTaskById(String taskId) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/$taskId');
    
    try {
      final response = await http.get(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return _jsonToTask(data['data']);
      }
      
      throw Exception('Task not found');
    } catch (e) {
      print('Error fetching task: $e');
      rethrow;
    }
  }

  // POST /api/tasks - Create a new task
  Future<Task> createTask(Task task) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_taskToJson(task)),
      );
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return _jsonToTask(data['data']);
      }
      
      throw Exception('Failed to create task');
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // PUT /api/tasks/{task_id} - Update an existing task
  Future<Task> updateTask(Task task) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/${task.id}');
    
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_taskToJson(task)),
      );
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return _jsonToTask(data['data']);
      }
      
      throw Exception('Failed to update task');
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // DELETE /api/tasks/{task_id} - Delete a task
  Future<bool> deleteTask(String taskId) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/$taskId');
    
    try {
      final response = await http.delete(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // GET /api/tasks/date-range - Get tasks within a date range
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    final queryParams = {
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
    };
    
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/date-range').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((taskJson) => _jsonToTask(taskJson))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching tasks by date range: $e');
      rethrow;
    }
  }

  // GET /api/tasks/today - Get today's tasks
  Future<List<Task>> getTodayTasks() async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/today');
    
    try {
      final response = await http.get(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((taskJson) => _jsonToTask(taskJson))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching today\'s tasks: $e');
      rethrow;
    }
  }

  // PATCH /api/tasks/{task_id}/toggle-completion - Toggle task completion status
  Future<Task> toggleTaskCompletion(String taskId) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/api/tasks/$taskId/toggle-completion');
    
    try {
      final response = await http.patch(uri);
      _handleError(response);
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Since this endpoint returns partial task data, we need to fetch the full task
        return getTaskById(taskId);
      }
      
      throw Exception('Failed to toggle task completion');
    } catch (e) {
      print('Error toggling task completion: $e');
      rethrow;
    }
  }
} 