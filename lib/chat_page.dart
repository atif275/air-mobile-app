import 'package:flutter/material.dart';
import 'logs_manager.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> _messages = [
    {"sender": "robot", "text": "Hello! How can I assist you today?"},
    {"sender": "user", "text": "What can you do for me?"},
    {"sender": "robot", "text": "I can assist with tasks like managing schedules, sending messages, or providing helpful information."},
  ]; // Stores chat history
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text.trim()});
      LogsManager.addLog(
        message: "Sent message: $text",
        source: "User",
      ); // Log user's message
      _controller.clear();
    });

    // Simulate a robot response with a delay
    Future.delayed(const Duration(seconds: 1), () {
      final response = "I'm here to help with anything you need!";
      setState(() {
        _messages.add({"sender": "robot", "text": response});
        LogsManager.addLog(
          message: "Received response: $response",
          source: "System",
        ); // Log robot's response
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with AIR"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["sender"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft, // Align based on sender
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueGrey[800]
                          : Colors.blueGrey[200], // Different colors for sender
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_controller.text),
                  icon: Icon(Icons.send,
                      color: Theme.of(context).primaryColorDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
