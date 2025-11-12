import 'package:flutter/material.dart';
import 'package:air/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final Function(Task) onTaskTap;
  final Function(String) onToggleCompletion;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTaskTap,
    required this.onToggleCompletion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = task.dueDate.isBefore(now) && !task.isCompleted;
    
    // Format due date
    String dueText;
    if (task.dueDate.day == now.day && 
        task.dueDate.month == now.month && 
        task.dueDate.year == now.year) {
      // Due today
      final hour = task.dueDate.hour.toString().padLeft(2, '0');
      final minute = task.dueDate.minute.toString().padLeft(2, '0');
      dueText = 'Today at $hour:$minute';
    } else if (task.dueDate.difference(now).inDays == 1) {
      // Due tomorrow
      dueText = 'Tomorrow';
    } else {
      // Due on another day
      final month = task.dueDate.month.toString().padLeft(2, '0');
      final day = task.dueDate.day.toString().padLeft(2, '0');
      dueText = '$month/$day/${task.dueDate.year}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue 
              ? Colors.red.withOpacity(0.5) 
              : Colors.transparent,
          width: isOverdue ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => onTaskTap(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority indicator and checkbox
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isCompleted 
                          ? Colors.green.withOpacity(0.2) 
                          : getPriorityColor(task.priority).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted 
                            ? Colors.green 
                            : getPriorityColor(task.priority),
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onToggleCompletion(task.id),
                      customBorder: const CircleBorder(),
                      child: task.isCompleted 
                          ? const Icon(Icons.check, size: 16, color: Colors.green) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: getCategoryColor(task.category),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getCategoryIcon(task.category),
                          size: 16,
                          color: getCategoryColor(task.category),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getCategoryName(task.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: getCategoryColor(task.category),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: getStatusColor(task.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: getStatusColor(task.status).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            getStatusName(task.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: getStatusColor(task.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: task.isCompleted 
                            ? Colors.grey 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.warning : Icons.access_time,
                          size: 14,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue ? 'Overdue: $dueText' : 'Due: $dueText',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (task.location.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 