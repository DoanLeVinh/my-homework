import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    return _isInitialized;
  }

  Future<String?> listen() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    String? result;

    await _speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
      },
      localeId: 'vi_VN', // Vietnamese locale
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );

    // Wait for listening to complete
    await Future.delayed(const Duration(seconds: 6));

    return result;
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;
}
