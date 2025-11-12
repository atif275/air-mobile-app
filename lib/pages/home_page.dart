import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:air/pages/settings_page.dart';
import 'package:air/pages/logs.dart';
import 'package:air/services/logs_manager.dart';
import 'package:air/pages/chat_page.dart';
import 'package:air/view%20model/controller/voice_assistant_controller.dart';
import 'package:air/services/camera_service.dart';
import 'package:air/widgets/camera_stream_panel.dart';
import 'package:air/widgets/swipe_indicator.dart';
import 'package:air/pages/task2_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleThemeMode;
  final bool isDarkMode;

  const HomePage({Key? key, required this.toggleThemeMode, required this.isDarkMode}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  bool isMuted = true;
  int _selectedHeadIndex = 1; // 1 or 2
  final VoiceAssistantController _voiceController = Get.put(VoiceAssistantController());
  final CameraService _cameraService = CameraService();
  bool _showCamera = false;
  final PageController _pageController = PageController();
  bool _isSwipeExpanded = false;

  String status = "Loading AIR...";

  @override
  void initState() {
    super.initState();
    _simulateModelLoading();
  }

  void _simulateModelLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isLoading = false;
      status = "Status: Ready to Help!";
      LogsManager.addLog(message: "AIR is ready to help!", source: "System");
    });
  }


  Widget _buildRoundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: onPressed,
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueGrey[800],
          child: Icon(
            icon,
            size: 28,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIR Home'),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: "Settings",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  toggleThemeMode: widget.toggleThemeMode,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            );
            LogsManager.addLog(message: "Opened Settings Page", source: "User");
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                widget.toggleThemeMode();
                LogsManager.addLog(
                  message: widget.isDarkMode
                      ? "Switched to Dark Mode"
                      : "Switched to Light Mode",
                  source: "User",
                );
              },
              tooltip: widget.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
          // Robot Head Image
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Robot Head Image with Loading State
                Stack(
                  children: [
                    SizedBox(
                      height: 400,
                      child: PageView(
                        controller: _pageController,
                        physics: _isSwipeExpanded 
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _isSwipeExpanded = index == 1;
                          });
                        },
                        children: [
                          // Robot Head Image
                          Stack(
                            children: [
                              if (isLoading)
                                const Center(
                                  child: SpinKitCircle(
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                ),
                              Opacity(
                                opacity: isLoading ? 0.0 : 1.0,
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/air_robot_head$_selectedHeadIndex.PNG',
                                        width: 300,
                                        height: 300,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback if image not found
                                          return Container(
                                            width: 300,
                                            height: 300,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.smart_toy,
                                              size: 150,
                                              color: Colors.white70,
                                            ),
                                          );
                                        },
                                      ),
                                      // Head Selection Toggle
                                      if (!isLoading)
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                        setState(() {
                                                      _selectedHeadIndex = 1;
                                                    });
                                                    LogsManager.addLog(
                                                      message: "Switched to robot head 1",
                                                      source: "User"
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _selectedHeadIndex == 1
                                                          ? Colors.blue
                                                          : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      '1',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: _selectedHeadIndex == 1
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedHeadIndex = 2;
                                                    });
                                                    LogsManager.addLog(
                                                      message: "Switched to robot head 2",
                                                      source: "User"
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _selectedHeadIndex == 2
                                                          ? Colors.blue
                                                          : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      '2',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: _selectedHeadIndex == 2
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                          
                          // Camera Stream Panel
                          CameraStreamPanel(
                            cameraService: _cameraService,
                            showCamera: _showCamera,
                            onCameraClose: () {
                              _cameraService.stopStreaming();
                              setState(() => _showCamera = false);
                              LogsManager.addLog(message: "Closed camera stream", source: "System");
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Swipe Indicator
                    Positioned(
                      left: _isSwipeExpanded ? 0 : null,
                      right: _isSwipeExpanded ? null : 0,
                      top: 140,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          key: ValueKey<bool>(_isSwipeExpanded),
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity! < 0 && !_isSwipeExpanded) {
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else if (details.primaryVelocity! > 0 && _isSwipeExpanded) {
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: SwipeIndicator(
                            isExpanded: _isSwipeExpanded,
                            shouldBounce: _showCamera,
                            onTap: () {
                              _pageController.animateToPage(
                                _isSwipeExpanded ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),

          // Status Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // First Row Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: _buildRoundButton(
                  icon: Icons.list_alt,
                  tooltip: "Logs",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogsPage()),
                    );
                    LogsManager.addLog(message: "Opened Logs Page", source: "User");
                  },
                ),
              ),
              // Empty space for floating mic button
              const SizedBox(width: 90, height: 60),
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: _buildRoundButton(
                  icon: Icons.keyboard,
                  tooltip: "Text Chat",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                    LogsManager.addLog(message: "Opened Text Chat", source: "User");
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second Row Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: _buildRoundButton(
                  icon: Icons.assignment,
                  tooltip: "Task Management",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Task2Page(),
                      ),
                    );
                    LogsManager.addLog(message: "Opened Task Management Page", source: "User");
                  },
                ),
              ),
              // Empty space in center
              const SizedBox(width: 60, height: 60),
              // Camera Button - Right side, aligned with Text Chat above
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: _buildRoundButton(
                icon: _showCamera ? Icons.camera_enhance : Icons.camera_alt,
                tooltip: _showCamera ? "Stop Camera" : "Start Camera",
                onPressed: () async {
                  if (!_showCamera) {
                    final initialized = await _cameraService.initializeCamera();
                    if (initialized) {
                      setState(() => _showCamera = true);
                        _cameraService.startStreaming();
                        LogsManager.addLog(message: "Started device camera stream", source: "System");
                    }
                  } else {
                    _cameraService.stopStreaming();
                    setState(() => _showCamera = false);
                    LogsManager.addLog(message: "Stopped camera stream", source: "System");
                  }
                  },
                ),
              ),
            ],
          ),

            ],
          ),
          // Floating Mic Button between rows - centered horizontally
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                ),
                SizedBox(
                  width: 90,
                  height: 90,
                  child: GestureDetector(
                    onTap: () async {
                      if (_voiceController.isListening.value) {
                        await _voiceController.stopListening();
                        setState(() {
                          isMuted = true;
                        });
                      } else {
                        await _voiceController.startListening();
                        setState(() {
                          isMuted = false;
                        });
                      }
                      LogsManager.addLog(
                        message: isMuted ? "Voice Assistant Muted" : "Voice Assistant Activated",
                        source: "User"
                      );
                    },
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blueGrey[800],
                      child: Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        size: 45,
                        color: isMuted
                            ? Colors.red
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Speech Bubble below mic button - positioned in Stack
          Obx(() => _voiceController.isListening.value
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55 + 160, // Below mic button (90 button + 40 spacing)
                    ),
              Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? Colors.grey[800]?.withOpacity(0.7) 
                              : Colors.grey[200]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.isDarkMode 
                                ? Colors.grey[700]!.withOpacity(0.3)
                                : Colors.grey[300]!.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _voiceController.userSpeech.value.isEmpty 
                              ? "Listening..." 
                              : _voiceController.userSpeech.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 