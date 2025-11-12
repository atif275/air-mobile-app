import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:air/services/camera_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class CameraOverlay extends StatefulWidget {
  final CameraService cameraService;
  final VoidCallback onClose;

  const CameraOverlay({
    Key? key,
    required this.cameraService,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  bool _isFlashOn = false;
  bool _isSwitchingCamera = false;

  void _handleCameraSwitch() async {
    if (_isSwitchingCamera) return;
    
    setState(() => _isSwitchingCamera = true);
    
    try {
      final success = await widget.cameraService.switchCamera();
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch camera')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching camera: $e')),
      );
    } finally {
      setState(() => _isSwitchingCamera = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Camera Preview
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: widget.cameraService.controller != null
                    ? CameraPreview(widget.cameraService.controller!)
                    : Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Text(
                            'Initializing camera...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),

            // Controls Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                    IconButton(
                      icon: _isSwitchingCamera
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.flip_camera_ios, color: Colors.white),
                      onPressed: _isSwitchingCamera ? null : _handleCameraSwitch,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 