import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencySoundService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isPlaying = false;
  static int _sessionToken = 0;

  // Control para avisos informativos (novedades en la vía / cámaras)
  static String _ultimoAvisoVial = '';
  static DateTime? _horaUltimoAvisoVial;

  static bool get isSirenActive => _isPlaying;

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

  /// Anuncia por voz novedades en la vía o cámaras de fotodetección
  /// sin interrumpir nunca una alerta crítica de sirena activa.
  static Future<void> anunciarNovedadVial(
    String mensaje, {
    int enfriamientoSegundos = 25,
  }) async {
    final String texto = mensaje.trim();
    if (texto.isEmpty) return;

    // Nunca pisar una emergencia crítica (Robo, Accidente, Estoy en Peligro)
    if (_isPlaying) return;

    // Evitar repetir exactamente el mismo anuncio seguidamente por GPS
    final DateTime ahora = DateTime.now();
    if (_ultimoAvisoVial == texto &&
        _horaUltimoAvisoVial != null &&
        ahora.difference(_horaUltimoAvisoVial!).inSeconds <
            enfriamientoSegundos) {
      return;
    }

    _ultimoAvisoVial = texto;
    _horaUltimoAvisoVial = ahora;

    try {
      await HapticFeedback.mediumImpact();
      await _tts.setLanguage('es-CO');
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
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
