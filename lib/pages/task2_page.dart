import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:air/widgets/task_components/task_detail_dialog.dart';
import 'package:air/widgets/task_components/task_list_item.dart';
import 'package:air/widgets/task_components/task_timeline.dart';
import 'package:air/widgets/task_components/category_selector.dart';
import 'package:air/widgets/task_components/summary_card.dart';
import 'package:air/models/task_model.dart';
import 'package:air/view%20model/task_view_model.dart';

class Task2Page extends StatefulWidget {
  const Task2Page({Key? key}) : super(key: key);

  @override
  _Task2PageState createState() => _Task2PageState();
}

class _Task2PageState extends State<Task2Page> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late TaskViewModel _taskViewModel;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize search controller
    _searchController.addListener(() {
      if (_taskViewModel != null) {
        _taskViewModel.setSearchQuery(_searchController.text);
      }
    });
    
    // Fetch tasks when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
      _taskViewModel.init();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTaskCompletion(String taskId) async {
    await _taskViewModel.toggleTaskCompletion(taskId);
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        onTaskUpdated: (updatedTask) async {
          await _taskViewModel.updateTask(updatedTask);
          Navigator.of(context).pop();
        },
        onTaskDeleted: (taskId) async {
          await _taskViewModel.deleteTask(taskId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(
        onTaskAdded: (newTask) async {
          await _taskViewModel.createTask(newTask);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<TaskViewModel>(
      builder: (context, taskViewModel, child) {
        _taskViewModel = taskViewModel;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Management'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  taskViewModel.showCompletedTasks ? Icons.check_circle : Icons.check_circle_outline,
                ),
                tooltip: taskViewModel.showCompletedTasks ? 'Hide completed tasks' : 'Show completed tasks',
                onPressed: () {
                  taskViewModel.toggleShowCompletedTasks();
                },
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort tasks',
                onPressed: () {
                  // Show sort options
                  _showSortOptions();
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Timeline'),
                Tab(text: 'Calendar'),
              ],
            ),
          ),
          body: taskViewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tasks Tab
                    Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode 
                                  ? Colors.grey[800] 
                                  : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                        
                        // Category selector
                        CategorySelector(
                          selectedCategory: taskViewModel.selectedCategory,
                          onCategorySelected: (category) {
                            taskViewModel.setSelectedCategory(category);
                          },
                        ),
                        
                        // Task summary
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Today',
                                  count: taskViewModel.todayTasks.length,
                                  icon: Icons.today,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Upcoming',
                                  count: taskViewModel.upcomingTasks.length,
                                  icon: Icons.upcoming,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Error message if any
                        if (taskViewModel.error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              taskViewModel.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Task list
                        Expanded(
                          child: taskViewModel.filteredTasks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.task_alt,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No tasks found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add a new task to get started',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => taskViewModel.fetchAllTasks(),
                                  child: ListView.builder(
                                    itemCount: taskViewModel.filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      return TaskListItem(
                                        task: taskViewModel.filteredTasks[index],
                                        onTaskTap: _showTaskDetails,
                                        onToggleCompletion: _toggleTaskCompletion,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                    
                    // Timeline Tab
                    RefreshIndicator(
                      onRefresh: () => taskViewModel.fetchTodayTasks(),
                      child: TaskTimeline(tasks: taskViewModel.todayTasks),
                    ),
                    
                    // Calendar Tab (placeholder for now)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Calendar View Coming Soon',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            child: const Icon(Icons.add),
            tooltip: 'Add Task',
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Due Date (Earliest First)'),
                onTap: () {
                  _taskViewModel.sortByDueDate(ascending: true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.priority_high),
                title: const Text('Priority (Highest First)'),
                onTap: () {
                  _taskViewModel.sortByPriority(highestFirst: true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.title),
                title: const Text('Alphabetical (A-Z)'),
                onTap: () {
                  _taskViewModel.sortAlphabetically(ascending: true);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Creation Date (Newest First)'),
                onTap: () {
                  _taskViewModel.sortByCreationDate(newestFirst: true);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskSheet({
    Key? key,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  _AddTaskSheetState createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  TaskCategory _category = TaskCategory.personal;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = TimeOfDay.now();
  String _assignedTo = 'Self';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _addTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Combine date and time
    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: dueDateTime,
      priority: _priority,
      category: _category,
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: _notesController.text,
      location: _locationController.text,
      assignedTo: _assignedTo,
    );

    try {
      await widget.onTaskAdded(newTask);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskCategory>(
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TaskStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.toString().split('.').last.capitalize(),
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
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Add Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 