import 'package:flutter/material.dart';
import 'package:air/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TaskTimeline extends StatelessWidget {
  final List<Task> tasks;

  const TaskTimeline({
    Key? key,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Sort tasks by time
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    return tasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks scheduled for today',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task to see it in your timeline',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedTasks.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    final timeString = DateFormat('h:mm a').format(task.dueDate);
                    final isFirst = index == 0;
                    final isLast = index == sortedTasks.length - 1;
                    
                    return TimelineTile(
                      alignment: TimelineAlign.manual,
                      lineXY: 0.2,
                      isFirst: isFirst,
                      isLast: isLast,
                      indicatorStyle: IndicatorStyle(
                        width: 20,
                        height: 20,
                        indicator: _buildIndicator(task),
                        drawGap: true,
                      ),
                      beforeLineStyle: LineStyle(
                        color: getCategoryColor(task.category).withOpacity(0.5),
                        thickness: 2,
                      ),
                      afterLineStyle: LineStyle(
                        color: index < sortedTasks.length - 1 
                            ? getCategoryColor(sortedTasks[index + 1].category).withOpacity(0.5) 
                            : getCategoryColor(task.category).withOpacity(0.5),
                        thickness: 2,
                      ),
                      startChild: Center(
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: task.isCompleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      endChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 0, 24),
                        child: _buildTaskCard(context, task),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildIndicator(Task task) {
    return Container(
      decoration: BoxDecoration(
        color: task.isCompleted 
            ? Colors.green 
            : getCategoryColor(task.category),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: task.isCompleted 
          ? const Icon(
              Icons.check,
              size: 12,
              color: Colors.white,
            ) 
          : Icon(
              getCategoryIcon(task.category),
              size: 12,
              color: Colors.white,
            ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: getCategoryColor(task.category).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getCategoryColor(task.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    getCategoryName(task.category),
                    style: TextStyle(
                      fontSize: 12,
                      color: getCategoryColor(task.category),
                      fontWeight: FontWeight.bold,
                    ),
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
            const SizedBox(height: 8),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
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
              ),
            ],
          ],
        ),
      ),
    );
  }
} 