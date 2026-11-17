import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyAlertService {
  /// Activa una alerta sonora y visual de proximidad para vehículos cercanos
  /// cuando se reporta 'robo' o 'peligro'.
  static Future<void> triggerProximityAlarm({
    required BuildContext context,
    required String alertType, // 'robo' o 'peligro'
    required String plate,
    String vehicleDescription = 'Vehículo registrado en S.O.S. Auto',
  }) async {
    // 1. Vibración de alerta crítica
    await HapticFeedback.heavyImpact();

    // 2. Sonido de alerta del sistema
    await SystemSound.play(SystemSoundType.alert);

    final bool isTheft = alertType.toLowerCase() == 'robo';
    final String title = isTheft
        ? '🚨 ALERTA DE ROBO CERCANO'
        : '⚠️ ALERTA DE PELIGRO CERCANO';
    final String announcement = isTheft
        ? 'Atención conductores cercanos: Se reporta robo del vehículo de placas $plate ($vehicleDescription). Mantenga distancia y reporte al 123.'
        : 'Atención conductores cercanos: Usuario en situación de peligro en el vehículo de placas $plate. Precaución en la vía.';

    if (!context.mounted) return;

    // 3. Banner de alerta de alta visibilidad en pantalla
    showDialog(
      context: context,
      barrierDismissible: true,
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
          TextButton(
            onPressed: () {
              detenerVoz();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Detiene cualquier alerta sonora o anuncio de voz activo
  static Future<void> detenerVoz() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
