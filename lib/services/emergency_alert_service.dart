import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EmergencyAlertService {
  static final AudioPlayer _sirenPlayer = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static Timer? _vibrationTimer;
  static bool _isAlertActive = false;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'sos_auto_robo_critico';
  static const String _channelName = 'Alertas Críticas de Robo';

  static bool get isAlertActive => _isAlertActive;

  /// Inicializa el canal de alerta crítica (llamar una vez en main.dart)
  static Future<void> initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _notifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notificaciones de emergencia que despiertan la pantalla',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Dispara notificación que despierta la pantalla + sirena + voz en otros teléfonos
  static Future<void> alertarRoboBackground({
    required String placa,
    required String descripcion,
  }) async {
    final placaLimpia = placa.trim().toUpperCase();
    final descLimpia = descripcion.trim();
    final mensajeVoz = descLimpia.isEmpty
        ? 'Alerta S.O.S. Auto. Robo de vehículo reportado. Placa $placaLimpia.'
        : 'Alerta S.O.S. Auto. Robo de vehículo reportado. Placa $placaLimpia. $descLimpia';

    await _mostrarNotificacionCritica(placaLimpia, mensajeVoz);
    await _startSirenAndVoice(mensajeVoz);
  }

  static Future<void> _mostrarNotificacionCritica(
    String placa,
    String mensaje,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alerta de robo de vehículo cercano',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
    );

    await _notifications.show(
      911,
      '🚨 ROBO DE VEHÍCULO - PLACA $placa',
      mensaje,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Inicia sirena continua + vibración crítica + anuncio de voz en español
  static Future<void> _startSirenAndVoice(String spokenMessage) async {
    await detenerVoz();
    _isAlertActive = true;

    // 1. Vibración continua cada 1.2 segundos
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (_isAlertActive) {
        HapticFeedback.heavyImpact();
      }
    });

    // 2. Sirena sintetizada en bucle
    try {
      final sirenBytes = _generateSirenWavBytes();
      await _sirenPlayer.setReleaseMode(ReleaseMode.loop);
      await _sirenPlayer.setVolume(1.0);
      await _sirenPlayer.play(BytesSource(sirenBytes));
    } catch (e) {
      debugPrint('Error reproduciendo sirena: $e');
    }

    // 3. Voz en español repetida mientras la alerta esté activa
    try {
      await _tts.setLanguage('es-CO');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() async {
        if (_isAlertActive) {
          await Future.delayed(const Duration(milliseconds: 900));
          if (_isAlertActive) {
            await _tts.speak(spokenMessage);
          }
        }
      });

      await _tts.speak(spokenMessage);
    } catch (e) {
      debugPrint('Error en TTS emergencia: $e');
    }
  }

  /// Métodos directos para los botones locales de emergencia
  static Future<void> alertarRobo({
    required String placa,
    String descripcion = '',
  }) async {
    await alertarRoboBackground(placa: placa, descripcion: descripcion);
  }

  static Future<void> alertarPeligro({String mensaje = ''}) async {
    final texto = mensaje.isEmpty
        ? 'Alerta S.O.S. Auto. Conductor en peligro solicitando ayuda inmediata.'
        : mensaje;
    await _startSirenAndVoice(texto);
  }

  static Future<void> alertarAccidente({String mensaje = ''}) async {
    final texto = mensaje.isEmpty
        ? 'Alerta S.O.S. Auto. Accidente de tránsito reportado en la vía.'
        : mensaje;
    await _startSirenAndVoice(texto);
  }

  /// Detiene sirena, vibración, voz y borra la notificación crítica
  static Future<void> detenerVoz() async {
    _isAlertActive = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _sirenPlayer.stop();
    } catch (_) {}

    try {
      await _tts.stop();
    } catch (_) {}

    try {
      await _notifications.cancel(911);
    } catch (_) {}
  }

  /// Genera onda WAV de sirena policial/emergencia en memoria (sin depender de archivos mp3)
  static Uint8List _generateSirenWavBytes() {
    const int sampleRate = 22050;
    const double durationSeconds = 2.0;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final int dataSize = numSamples * 2;
    final ByteData buffer = ByteData(44 + dataSize);

    // Cabecera RIFF/WAVE
    buffer.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    buffer.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // Mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    buffer.setUint32(36, 0x64617461, Endian.big); // "data"
    buffer.setUint32(40, dataSize, Endian.little);

    double phase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Oscilación entre 650 Hz y 1250 Hz
      final double freq = 950.0 + 300.0 * math.sin(2.0 * math.pi * 1.0 * t);
      phase += (2.0 * math.pi * freq) / sampleRate;
      final int sample = (math.sin(phase) * 28000).toInt().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
