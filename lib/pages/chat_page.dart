import 'package:flutter/material.dart';
import 'package:air/services/logs_manager.dart';
import 'dart:math';
import 'package:air/services/python_server_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final PythonServerService _pythonServer = PythonServerService();
  bool _isTyping = false;
  String _serverStatus = "Connected";
  
  // Sample messages for demonstration
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm AIR, your personal assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to focus node to scroll to bottom when keyboard appears
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    // Dismiss keyboard after sending message
    FocusScope.of(context).unfocus();
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    LogsManager.addLog(
      message: "Sent message: $text",
      source: "User",
    );
    
    _scrollToBottom();
    
    try {
      // Send message to Python server
      final response = await _sendToPythonServer(text);
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _serverStatus = "Connected";
      });
      
      LogsManager.addLog(
        message: "Received response: $response",
        source: "AIR",
      );
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "I'm sorry, I'm having trouble connecting to my server. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _serverStatus = "Disconnected";
      });
      
      LogsManager.addLog(
        message: "Error communicating with server: $e",
        source: "System",
      );
    }
    
    _scrollToBottom();
  }
  
  Future<String> _sendToPythonServer(String text) async {
    try {
      final success = await _pythonServer.sendTranscribedText(text);
      
      if (success) {
        // Use the actual bot response from the server via the getter method
        return _pythonServer.lastBotResponse;
      } else {
        setState(() {
          _serverStatus = "Error";
        });
        return _pythonServer.lastBotResponse; // This will contain the error message
      }
    } catch (e) {
      setState(() {
        _serverStatus = "Disconnected";
      });
      print("Error sending to Python server: $e");
      return "I'm having trouble connecting to my server. Please try again later.";
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 16,
              child: ClipOval(
                child: Image.asset(
                  'assets/air_robot_head1.PNG',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 18,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text("AIR Assistant"),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About AIR Chat"),
                  content: const Text(
                    "AIR Chat allows you to communicate with your AIR assistant using text. "
                    "Your messages are sent to the same AI system that powers the voice assistant."
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Use resizeToAvoidBottomInset to prevent keyboard from pushing content up
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                "Today",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Server status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _serverStatus == "Connected" 
                          ? Colors.green 
                          : _serverStatus == "Error" 
                              ? Colors.orange 
                              : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$_serverStatus to ${dotenv.env['PYTHON_SERVER_URL']?.split('//').last.split(':').first ?? 'server'}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat messages
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping on the chat area
                  FocusScope.of(context).unfocus();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final showTimestamp = index == _messages.length - 1 || 
                                         _messages[index + 1].isUser != message.isUser;
                    
                    return MessageBubble(
                      message: message,
                      showTimestamp: showTimestamp,
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
              ),
            ),
            
            // Typing indicator
            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const TypingIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      "AIR is typing...",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Message input
            Container(
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Attachment feature coming soon"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final bool isDarkMode;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.showTimestamp,
    required this.isDarkMode,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar for bot messages
              if (!message.isUser) ...[
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 16,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/air_robot_head1.PNG',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Message bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).primaryColor
                        : isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              // Space after user messages
              if (message.isUser)
                const SizedBox(width: 8),
            ],
          ),
          
          // Timestamp
          if (showTimestamp)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: message.isUser ? 0 : 40,
                right: message.isUser ? 8 : 0,
              ),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final position = sin((_controller.value - delay) * 2 * pi);
            return Transform.translate(
              offset: Offset(0, position * 3),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
