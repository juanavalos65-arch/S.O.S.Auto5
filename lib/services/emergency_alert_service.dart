import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyAlertService {
  static final AudioPlayer _sirenPlayer = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static Timer? _vibrationTimer;
  static bool _isAlertActive = false;

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

    // 2. Reproducir sirena sintetizada en bucle continuo
    try {
      final Uint8List sirenWav = _generateSirenWavBytes();
      await _sirenPlayer.setReleaseMode(ReleaseMode.loop);
      await _sirenPlayer.setVolume(1.0);
      await _sirenPlayer.play(BytesSource(sirenWav));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }

    // 3. Configurar y leer anuncio de voz en español
    try {
      await _tts.setLanguage('es-CO');
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      await _tts.speak(spokenMessage);
    } catch (_) {}
  }

  /// Alerta visual, sonora (sirena) y de voz por proximidad
  static Future<void> triggerProximityAlarm({
    required BuildContext context,
    required String alertType,
    required String plate,
    String vehicleDescription = 'Vehículo registrado en S.O.S. Auto',
  }) async {
    final bool isTheft = alertType.toLowerCase() == 'robo';
    final String title = isTheft
        ? '🚨 ALERTA DE ROBO CERCANO'
        : '⚠️ ALERTA DE PELIGRO CERCANO';
    final String announcement = isTheft
        ? 'Atención conductores cercanos: Se reporta robo del vehículo de placas $plate ($vehicleDescription). Mantenga distancia y reporte al 123.'
        : 'Atención conductores cercanos: Usuario en situación de peligro en el vehículo de placas $plate. Precaución en la vía.';

    await _startSirenAndVoice(announcement);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isTheft ? Colors.red.shade900 : Colors.deepOrange.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PLACA: ${plate.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              announcement,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await detenerVoz();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.volume_off, color: Colors.amber),
            label: const Text(
              'SILENCIAR Y ENTENDIDO',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Disparador desde StolenCarScreen al cumplirse los 5 segundos
  static Future<void> alertarRoboVehiculo({
    BuildContext? context,
    String placa = '',
    String plate = '',
    String tipoVehiculo = '',
    String marca = '',
    String modelo = '',
    String anio = '',
    String color = '',
    String ciudad = '',
    String sector = '',
    String barrio = '',
    String direccion = '',
    String ubicacion = '',
    String descripcion = '',
    String recompensa = '',
    String nombrePropietario = '',
    String telefono = '',
  }) async {
    final String placaFinal = (placa.isNotEmpty ? placa : plate).toUpperCase();
    final detalles = [
      tipoVehiculo,
      marca,
      modelo,
      color,
      ciudad,
      sector,
      ubicacion,
      descripcion,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final String mensajeVoz =
        'Alerta S.O.S. Auto. Robo de vehículo reportado. Placa $placaFinal. '
        '${detalles.isNotEmpty ? detalles : 'Precaución en la vía y reporte al 123.'}';

    if (context != null && context.mounted) {
      await triggerProximityAlarm(
        context: context,
        alertType: 'robo',
        plate: placaFinal,
        vehicleDescription:
            detalles.isNotEmpty ? detalles : 'Vehículo reportado como robado',
      );
    } else {
      await _startSirenAndVoice(mensajeVoz);
    }
  }

  /// Detiene inmediatamente la sirena, la vibración y el anuncio de voz
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
  }

  /// Genera un ciclo WAV PCM de sirena bitonal (750 Hz -> 1050 Hz -> 750 Hz) en memoria
  static Uint8List _generateSirenWavBytes() {
    const int sampleRate = 22050;
    const double durationSeconds = 1.6;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final int dataSize = numSamples * 2;
    final ByteData buffer = ByteData(44 + dataSize);

    // Encabezado RIFF / WAVE (16-bit mono PCM)
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
      // Modulación tipo sirena policial entre 750 Hz y 1050 Hz
      final double sweep = 0.5 - 0.5 * math.cos(2 * math.pi * (t / durationSeconds));
      final double freq = 750.0 + (300.0 * sweep);
      phase += (2 * math.pi * freq) / sampleRate;
      final int sample = (math.sin(phase) * 32000).toInt().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
