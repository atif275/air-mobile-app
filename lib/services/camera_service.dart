import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:air/services/env_service.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? controller;
  bool isStreaming = false;
  bool _serverReady = false;
  DateTime? _lastFrameTime;
  int _reconnectAttempts = 0;
  StreamController<Uint8List> _imageStreamController;
  WebSocketChannel? _mlServerChannel;
  bool _isInitialized = false;
  CameraDescription? _currentCamera;
  List<CameraDescription> _cameras = [];
  final EnvService _envService = EnvService();
  
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const Duration RECONNECT_DELAY = Duration(seconds: 2);
  static const Duration FRAME_INTERVAL = Duration(milliseconds: 100);
  static const int MAX_IMAGE_DIMENSION = 640;
  static const int JPEG_QUALITY = 70;
  
  CameraService() : _imageStreamController = StreamController<Uint8List>.broadcast();

  Future<String> get mlServerUrl async {
    final host = await _envService.get('WEBSOCKET_HOST') ?? 'localhost';
    final port = await _envService.get('WEBSOCKET_PORT') ?? '8766';
    return 'ws://$host:$port';
  }

  Future<bool> initializeCamera() async {
    print('Initializing camera...');
    try {
      final allCameras = await availableCameras();
      if (allCameras.isEmpty) return false;

      // Filter to only get the main back and front cameras
      _cameras = allCameras.where((camera) {
        // Only include the first back camera and first front camera
        return camera.lensDirection == CameraLensDirection.back ||
               camera.lensDirection == CameraLensDirection.front;
      }).toList();

      // Start with front camera by default
      _currentCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      controller = CameraController(
        _currentCamera!,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS 
            ? ImageFormatGroup.bgra8888 
            : ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      await controller!.setFlashMode(FlashMode.off);
      print('Device camera initialized successfully');
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  Future<bool> switchCamera() async {
    if (_cameras.isEmpty || _cameras.length < 2) {
      return false;
    }

    try {
      // Stop current stream if active
      final wasStreaming = isStreaming;
      if (wasStreaming) {
        stopStreaming();
      }

      // Switch between front and back camera only
      _currentCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != _currentCamera!.lensDirection,
        orElse: () => _cameras.first,
      );

      // Initialize new camera
      controller = CameraController(
        _currentCamera!,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS 
            ? ImageFormatGroup.bgra8888 
            : ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      await controller!.setFlashMode(FlashMode.off);

      // Restart streaming if it was active
      if (wasStreaming) {
        startStreaming();
      }

      return true;
    } catch (e) {
      print('Error switching camera: $e');
      return false;
    }
  }

  void startStreaming() {
    print('Starting camera stream...');
    isStreaming = true;
    _reconnectAttempts = 0;
    print('Starting device camera stream');
    _connectToMLServer();
    _setupDeviceCameraStream();
  }

  Stream<Uint8List> get imageStream {
    print('Providing device camera stream');
    if (!_serverReady) {
      print('Waiting for server ready signal...');
    }
    return _imageStreamController.stream;
  }

  Future<void> _connectToMLServer() async {
    try {
      final url = await mlServerUrl;
      print('Connecting to ML WebSocket server at $url');
      _mlServerChannel = WebSocketChannel.connect(Uri.parse(url));
      print('Connected to ML WebSocket server');
      _setupMLServerListeners();
    } catch (e) {
      print('Error connecting to ML WebSocket server: $e');
      throw e;
    }
  }

  void _setupMLServerListeners() {
    _mlServerChannel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          print('Received message from ML server: ${data['type']}');
          
          if (data['type'] == 'ready') {
            _serverReady = true;
            print('ML server is ready to receive frames');
          } else if (data['type'] == 'frame_ack') {
            print('Frame ${data['frame_number']} acknowledged by ML server');
          } else if (data['type'] == 'error') {
            print('ML server error: ${data['message']}');
          }
        } catch (e) {
          print('Error processing ML server message: $e');
        }
      },
      onError: (error) {
        print('ML WebSocket error: $error');
        _reconnect();
      },
      onDone: () {
        print('ML WebSocket connection closed');
        _reconnect();
      },
    );
  }

  void _setupDeviceCameraStream() async {
    if (controller == null) return;

    await controller!.startImageStream((image) async {
      if (!isStreaming || _mlServerChannel == null || !_serverReady) return;

      final now = DateTime.now();
      if (_lastFrameTime != null &&
          now.difference(_lastFrameTime!) < FRAME_INTERVAL) {
        return;
      }
      _lastFrameTime = now;

      try {
        final bytes = await _processImageFrame(image);
        
        if (_mlServerChannel != null && _serverReady) {
          print('Sending frame to ML server');
          _mlServerChannel!.sink.add(jsonEncode({
            'type': 'image',
            'image': base64Encode(bytes),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        }

        if (!_imageStreamController.isClosed) {
          _imageStreamController.add(bytes);
        }
      } catch (e) {
        print('Error processing camera frame: $e');
      }
    });
  }

  Future<Uint8List> _processImageFrame(CameraImage image) async {
    try {
      List<int>? imageBytes;
      
      if (Platform.isIOS) {
        // For iOS: Convert BGRA to JPEG
        final img.Image? capturedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
        
        if (capturedImage != null) {
          final img.Image resized = img.copyResize(
            capturedImage,
            width: MAX_IMAGE_DIMENSION,
            height: (MAX_IMAGE_DIMENSION * image.height ~/ image.width),
          );
          imageBytes = img.encodeJpg(resized, quality: JPEG_QUALITY);
        } else {
          throw Exception('Failed to process iOS image');
        }
      } else {
        // For Android: Process YUV data
        final img.Image capturedImage = img.Image(width: image.width, height: image.height);
        
        final Uint8List yPlane = image.planes[0].bytes;
        final Uint8List uPlane = image.planes[1].bytes;
        final Uint8List vPlane = image.planes[2].bytes;
        
        final int yRowStride = image.planes[0].bytesPerRow;
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel!;

        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final int yIndex = y * yRowStride + x;
            final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

            final int yp = yPlane[yIndex];
            final int up = uPlane[uvIndex];
            final int vp = vPlane[uvIndex];

            int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
            int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round().clamp(0, 255);
            int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

            capturedImage.setPixelRgb(x, y, r, g, b);
          }
        }

        final img.Image resized = img.copyResize(
          capturedImage,
          width: MAX_IMAGE_DIMENSION,
          height: (MAX_IMAGE_DIMENSION * image.height ~/ image.width),
        );
        imageBytes = img.encodeJpg(resized, quality: JPEG_QUALITY);
      }

      if (imageBytes != null) {
        print('Processed image size: ${imageBytes.length} bytes');
        return Uint8List.fromList(imageBytes);
      } else {
        throw Exception('Failed to process image');
      }
    } catch (e) {
      print('Error in _processImageFrame: $e');
      rethrow;
    }
  }

  void stopStreaming() {
    print('Stopping camera stream...');
    isStreaming = false;
    _serverReady = false;
    _lastFrameTime = null;
    print('Stopping device camera stream');
    controller?.stopImageStream();
    _mlServerChannel?.sink.close();
    _mlServerChannel = null;
    print('Stream stopped successfully');
  }

  Future<void> _reconnect() async {
    if (!isStreaming || _reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        print('Max reconnection attempts reached');
        stopStreaming();
      }
      return;
    }

    _reconnectAttempts++;
    print('Reconnection attempt $_reconnectAttempts of $MAX_RECONNECT_ATTEMPTS');
    
    await Future.delayed(RECONNECT_DELAY);
    stopStreaming();
    startStreaming();
  }

  void dispose() {
    print('Disposing camera service');
    stopStreaming();
    controller?.dispose();
    _imageStreamController.close();
    _isInitialized = false;
  }
} 
 