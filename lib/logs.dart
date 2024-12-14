import 'package:flutter/material.dart';
import 'logs_manager.dart';

class LogsPage extends StatefulWidget {
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> logs = LogsManager.getLogs(); // Fetch logs

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                LogsManager.clearLogs();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logs cleared")),
              );
            },
            tooltip: "Clear Logs",
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                "No logs available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isSystem = log['source'] == "System";

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSystem ? Colors.blue : Colors.green,
                    child: Icon(
                      isSystem ? Icons.smart_toy : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(log['message']),
                  subtitle: Text(log['timestamp']),
                  trailing: Text(
                    log['source'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSystem ? Colors.blue : Colors.green,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
