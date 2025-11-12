import 'package:flutter/material.dart';
import 'package:air/models/task_model.dart';
import 'package:air/repositories/task_repository.dart';
import 'package:air/services/task_notification_manager.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  final TaskNotificationManager _notificationManager = TaskNotificationManager();
  
  TaskViewModel() : _repository = TaskRepository();
  
  // Task lists
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<Task> _todayTasks = [];
  List<Task> _upcomingTasks = [];
  
  // Loading states
  bool _isLoading = false;
  String? _error;
  
  // Filter states
  TaskCategory _selectedCategory = TaskCategory.personal;
  bool _showCompletedTasks = false;
  String _searchQuery = '';
  
  // Getters
  List<Task> get allTasks => _allTasks;
  List<Task> get filteredTasks => _filteredTasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get upcomingTasks => _upcomingTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskCategory get selectedCategory => _selectedCategory;
  bool get showCompletedTasks => _showCompletedTasks;
  String get searchQuery => _searchQuery;
  
  // Initialize the view model
  Future<void> init() async {
    await fetchAllTasks();
    await fetchTodayTasks();
    await fetchUpcomingTasks();
  }
  
  // Fetch all tasks from the repository
  Future<void> fetchAllTasks() async {
    _setLoading(true);
    try {
      _allTasks = await _repository.getAllTasks();
      
      // Schedule notifications for all non-completed tasks
      final now = DateTime.now();
      for (var task in _allTasks) {
        if (!task.isCompleted) {
          // Convert both dates to UTC for accurate comparison
          final dueDate = task.dueDate.toUtc();
          final currentTime = now.toUtc();
          
          if (dueDate.isAfter(currentTime)) {
            await _notificationManager.scheduleTaskNotification(task);
            print('TaskViewModel: Scheduled notification for task: ${task.title} at ${task.dueDate}');
          } else {
            print('TaskViewModel: Skipping notification for past task: ${task.title} (due: ${task.dueDate})');
          }
        }
      }
      
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch tasks: $e';
      print('TaskViewModel: Error fetching tasks: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Fetch today's tasks
  Future<void> fetchTodayTasks() async {
    try {
      _todayTasks = await _repository.getTodayTasks();
      notifyListeners();
    } catch (e) {
      print('Error fetching today\'s tasks: $e');
    }
  }
  
  // Fetch upcoming tasks
  Future<void> fetchUpcomingTasks() async {
    try {
      _upcomingTasks = await _repository.getUpcomingTasks();
      notifyListeners();
    } catch (e) {
      print('Error fetching upcoming tasks: $e');
    }
  }
  
  // Create a new task
  Future<bool> createTask(Task task) async {
    _setLoading(true);
    try {
      final createdTask = await _repository.createTask(task);
      if (createdTask != null) {
        _allTasks.add(createdTask);
        _applyFilters();
        await fetchTodayTasks();
        await fetchUpcomingTasks();
        await _notificationManager.scheduleTaskNotification(createdTask);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to create task: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update an existing task
  Future<bool> updateTask(Task task) async {
    _setLoading(true);
    try {
      final updatedTask = await _repository.updateTask(task);
      if (updatedTask != null) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
          _applyFilters();
          await fetchTodayTasks();
          await fetchUpcomingTasks();
          await _notificationManager.updateTaskNotification(updatedTask);
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = 'Failed to update task: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    try {
      final success = await _repository.deleteTask(taskId);
      if (success) {
        _allTasks.removeWhere((task) => task.id == taskId);
        _applyFilters();
        await fetchTodayTasks();
        await fetchUpcomingTasks();
        await _notificationManager.cancelTaskNotification(int.parse(taskId));
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete task: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Toggle task completion
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final updatedTask = await _repository.toggleTaskCompletion(taskId);
      if (updatedTask != null) {
        final index = _allTasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _allTasks[index] = updatedTask;
          _applyFilters();
          await fetchTodayTasks();
          await fetchUpcomingTasks();
          await _notificationManager.updateTaskNotification(updatedTask);
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = 'Failed to toggle task completion: $e';
      return false;
    }
  }
  
  // Set selected category
  void setSelectedCategory(TaskCategory category) {
    _selectedCategory = category;
    _applyFilters();
  }
  
  // Toggle show completed tasks
  void toggleShowCompletedTasks() {
    _showCompletedTasks = !_showCompletedTasks;
    _applyFilters();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }
  
  // Apply filters to all tasks
  void _applyFilters() {
    _filteredTasks = _allTasks.where((task) {
      // Filter by search text
      final searchMatch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by category
      final categoryMatch = _selectedCategory == task.category;
      
      // Filter by completion status
      final completionMatch = _showCompletedTasks || !task.isCompleted;
      
      return searchMatch && categoryMatch && completionMatch;
    }).toList();
    
    notifyListeners();
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Sort tasks by due date
  void sortByDueDate({bool ascending = true}) {
    _filteredTasks.sort((a, b) => ascending
        ? a.dueDate.compareTo(b.dueDate)
        : b.dueDate.compareTo(a.dueDate));
    notifyListeners();
  }
  
  // Sort tasks by priority
  void sortByPriority({bool highestFirst = true}) {
    _filteredTasks.sort((a, b) => highestFirst
        ? b.priority.index.compareTo(a.priority.index)
        : a.priority.index.compareTo(b.priority.index));
    notifyListeners();
  }
  
  // Sort tasks alphabetically
  void sortAlphabetically({bool ascending = true}) {
    _filteredTasks.sort((a, b) => ascending
        ? a.title.compareTo(b.title)
        : b.title.compareTo(a.title));
    notifyListeners();
  }
  
  // Sort tasks by creation date
  void sortByCreationDate({bool newestFirst = true}) {
    _filteredTasks.sort((a, b) => newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }
} 