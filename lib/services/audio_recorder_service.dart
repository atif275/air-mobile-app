import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();
  String? _currentPath;
  static const double SILENCE_THRESHOLD = -45.0; // dB
  static const Duration SILENCE_DURATION = Duration(milliseconds: 800);
  DateTime? _lastAudioPeak;
  Stream<Amplitude>? _amplitudeStream;
  Function()? _onSilenceDetected;

  Future<void> startRecording({Function()? onSilence}) async {
    try {
      _onSilenceDetected = onSilence;
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentPath = path;
        
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        // Start monitoring audio amplitude
        _startAmplitudeMonitoring();
      }
    } catch (e) {
      print("Error starting recording: $e");
      rethrow;
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeStream = Stream.periodic(
      const Duration(milliseconds: 100),
      (_) => _audioRecorder.getAmplitude(),
    ).asyncMap((future) async => await future);

    _amplitudeStream?.listen((amplitude) {
      if (amplitude.current > SILENCE_THRESHOLD) {
        _lastAudioPeak = DateTime.now();
      } else if (_lastAudioPeak != null) {
        final silenceDuration = DateTime.now().difference(_lastAudioPeak!);
        if (silenceDuration > SILENCE_DURATION) {
          _onSilenceDetected?.call();
          _lastAudioPeak = null;
        }
      }
    });
  }

  Future<String?> getTemporaryFile() async {
    if (_currentPath != null && await _audioRecorder.isRecording()) {
      final tempPath = '${_currentPath!}_temp.m4a';
      await _audioRecorder.stop();
      await File(_currentPath!).copy(tempPath);
      await startRecording(); // Resume recording
      return tempPath;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    try {
      await _audioRecorder.stop();
      return _currentPath;
    } catch (e) {
      print("Error stopping recording: $e");
      return null;
    }
  }

  Future<void> dispose() async {
    _amplitudeStream = null;
    _onSilenceDetected = null;
    await _audioRecorder.dispose();
  }
} 