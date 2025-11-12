import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory { personal, health, robotMaintenance, medication, appointment }

enum TaskStatus { pending, inProgress, completed, scheduled, cancelled }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  bool isCompleted;
  TaskStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  final String notes;
  final String location;
  final String assignedTo;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.category,
    this.isCompleted = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.location,
    required this.assignedTo,
  });

  // Create a copy of the task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? location,
    String? assignedTo,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      location: location ?? this.location,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

// Helper functions for task properties
Color getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return Colors.green;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.high:
      return Colors.red;
  }
}

Color getCategoryColor(TaskCategory category) {
  switch (category) {
    case TaskCategory.personal:
      return Colors.blue;
    case TaskCategory.health:
      return Colors.green;
    case TaskCategory.robotMaintenance:
      return Colors.purple;
    case TaskCategory.medication:
      return Colors.orange;
    case TaskCategory.appointment:
      return Colors.red;
  }
}

String getCategoryName(TaskCategory category) {
  switch (category) {
    case TaskCategory.personal:
      return 'Personal';
    case TaskCategory.health:
      return 'Health';
    case TaskCategory.robotMaintenance:
      return 'Robot';
    case TaskCategory.medication:
      return 'Medication';
    case TaskCategory.appointment:
      return 'Appointment';
  }
}

IconData getCategoryIcon(TaskCategory category) {
  switch (category) {
    case TaskCategory.personal:
      return Icons.person;
    case TaskCategory.health:
      return Icons.favorite;
    case TaskCategory.robotMaintenance:
      return Icons.smart_toy;
    case TaskCategory.medication:
      return Icons.medication;
    case TaskCategory.appointment:
      return Icons.event;
  }
}

Color getStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return Colors.grey;
    case TaskStatus.inProgress:
      return Colors.blue;
    case TaskStatus.completed:
      return Colors.green;
    case TaskStatus.scheduled:
      return Colors.purple;
    case TaskStatus.cancelled:
      return Colors.red;
  }
}

String getStatusName(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'Pending';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.completed:
      return 'Completed';
    case TaskStatus.scheduled:
      return 'Scheduled';
    case TaskStatus.cancelled:
      return 'Cancelled';
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 