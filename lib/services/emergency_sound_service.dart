import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencySoundService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isPlaying = false;
  static int _sessionToken = 0;

  static Future<void> startSiren({
    String mensaje = '¡Alerta de emergencia S.O.S. Auto activada!',
    int repeticiones = 3,
  }) async {
    await stopSiren();
    _isPlaying = true;
    final int currentToken = ++_sessionToken;

    try {
      await _tts.setLanguage('es-CO');
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.1);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}

    for (int i = 0; i < repeticiones; i++) {
      if (!_isPlaying || currentToken != _sessionToken) break;

      try {
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.heavyImpact();
      } catch (_) {}

      if (!_isPlaying || currentToken != _sessionToken) break;

      try {
        await _tts.speak(mensaje);
      } catch (_) {}

      if (i < repeticiones - 1 && _isPlaying && currentToken == _sessionToken) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    if (currentToken == _sessionToken) {
      _isPlaying = false;
    }
  }

  static Future<void> checkAndSound([dynamic alertas]) async {
    if (alertas is List && alertas.isEmpty) {
      await stop();
      return;
    }
    await startSiren();
  }

  static Future<void> stopSiren() async {
    _isPlaying = false;
    _sessionToken++;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> stop() async {
    await stopSiren();
  }
}
