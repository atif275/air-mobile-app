import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:air/models/task_model.dart';

class TaskDetailDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final Function(String) onTaskDeleted;

  const TaskDetailDialog({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  }) : super(key: key);

  @override
  _TaskDetailDialogState createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late Task _task;
  bool _isEditing = false;
  
  // Controllers for editable fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TaskPriority _priority;
  late TaskCategory _category;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: _task.title);
    _descriptionController = TextEditingController(text: _task.description);
    _notesController = TextEditingController(text: _task.notes);
    _locationController = TextEditingController(text: _task.location);
    _dueDate = _task.dueDate;
    _dueTime = TimeOfDay(hour: _task.dueDate.hour, minute: _task.dueDate.minute);
    _priority = _task.priority;
    _category = _task.category;
    _status = _task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    // Combine date and time
    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final updatedTask = _task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      notes: _notesController.text,
      location: _locationController.text,
      dueDate: dueDateTime,
      priority: _priority,
      category: _category,
      status: _status,
      isCompleted: _status == TaskStatus.completed,
      updatedAt: DateTime.now(),
    );

    widget.onTaskUpdated(updatedTask);
    setState(() {
      _task = updatedTask;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(
                            _task.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isEditing ? Icons.save : Icons.edit),
                        tooltip: _isEditing ? 'Save changes' : 'Edit task',
                        onPressed: _isEditing ? _saveChanges : _toggleEditMode,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete task',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text('Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onTaskDeleted(_task.id);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Task ID and timestamps
              _buildInfoRow(
                'ID',
                _task.id,
                Icons.tag,
              ),
              _buildInfoRow(
                'Created',
                DateFormat('MM/dd/yyyy, hh:mm a').format(_task.createdAt),
                Icons.create,
              ),
              _buildInfoRow(
                'Updated',
                DateFormat('MM/dd/yyyy, hh:mm a').format(_task.updatedAt),
                Icons.update,
              ),
              const Divider(),
              
              // Category and Priority
              Row(
                children: [
                  Expanded(
                    child: _isEditing
                        ? DropdownButtonFormField<TaskCategory>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: TaskCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(getCategoryName(category)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _category = value;
                                });
                              }
                            },
                          )
                        : _buildInfoRow(
                            'Category',
                            getCategoryName(_task.category),
                            getCategoryIcon(_task.category),
                            textColor: getCategoryColor(_task.category),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isEditing
                        ? DropdownButtonFormField<TaskPriority>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: TaskPriority.values.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Text(
                                  priority.toString().split('.').last.capitalize(),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _priority = value;
                                });
                              }
                            },
                          )
                        : _buildInfoRow(
                            'Priority',
                            _task.priority.toString().split('.').last.capitalize(),
                            Icons.flag,
                            textColor: getPriorityColor(_task.priority),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status
              _isEditing
                  ? DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            getStatusName(status),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    )
                  : _buildInfoRow(
                      'Status',
                      getStatusName(_task.status),
                      Icons.info_outline,
                      textColor: getStatusColor(_task.status),
                    ),
              const SizedBox(height: 16),
              
              // Due Date
              _isEditing
                  ? Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dueDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _dueDate = date;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MM/dd/yyyy').format(_dueDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _dueTime,
                              );
                              if (time != null) {
                                setState(() {
                                  _dueTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _dueTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildInfoRow(
                      'Due Date',
                      DateFormat('MM/dd/yyyy, hh:mm a').format(_task.dueDate),
                      Icons.event,
                    ),
              const SizedBox(height: 16),
              
              // Description
              _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_task.description),
                      ],
                    ),
              const SizedBox(height: 16),
              
              // Location
              _isEditing
                  ? TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : _buildInfoRow(
                      'Location',
                      _task.location,
                      Icons.location_on,
                    ),
              const SizedBox(height: 16),
              
              // Notes
              _isEditing
                  ? TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_task.notes.isEmpty ? 'No notes' : _task.notes),
                      ],
                    ),
              const SizedBox(height: 16),
              
              // Assigned To
              _buildInfoRow(
                'Assigned To',
                _task.assignedTo,
                Icons.person,
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              if (!_isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final updatedTask = _task.copyWith(
                          isCompleted: !_task.isCompleted,
                          status: !_task.isCompleted 
                              ? TaskStatus.completed 
                              : TaskStatus.pending,
                          updatedAt: DateTime.now(),
                        );
                        widget.onTaskUpdated(updatedTask);
                        setState(() {
                          _task = updatedTask;
                        });
                      },
                      icon: Icon(_task.isCompleted ? Icons.refresh : Icons.check),
                      label: Text(_task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _task.isCompleted ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleEditMode,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: textColor ?? Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 