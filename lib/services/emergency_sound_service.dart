import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencySoundService {
  static final FlutterTts _tts = FlutterTts();
  static Timer? _alarmTimer;
  static bool _isPlaying = false;

  static Future<void> startSiren({
    String mensaje = '¡Alerta de emergencia S.O.S. Auto activada!',
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;

    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.2);

    // Primera ejecución inmediata
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
    await _tts.speak(mensaje);

    // Repetición continua cada 3 segundos mientras la alerta siga activa
    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await _tts.speak(mensaje);
    });
  }

  static Future<void> stopSiren() async {
    _isPlaying = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;
    await _tts.stop();
  }
}
