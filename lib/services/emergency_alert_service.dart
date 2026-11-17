import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyAlertService {
  static Future<void> triggerProximityAlarm({
    required BuildContext context,
    required String alertType,
    required String plate,
    String vehicleDescription = 'Vehículo registrado en S.O.S. Auto',
  }) async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);

    final bool isTheft = alertType.toLowerCase() == 'robo';
    final String title = isTheft
        ? '🚨 ALERTA DE ROBO CERCANO'
        : '⚠️ ALERTA DE PELIGRO CERCANO';
    final String announcement = isTheft
        ? 'Atención conductores cercanos: Se reporta robo del vehículo de placas $plate ($vehicleDescription). Mantenga distancia y reporte al 123.'
        : 'Atención conductores cercanos: Usuario en situación de peligro en el vehículo de placas $plate. Precaución en la vía.';

    if (!context.mounted) return;

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

  /// Alias compatible con las llamadas desde stolen_car_screen.dart
  static Future<void> alertarRoboVehiculo({
    BuildContext? context,
    String placa = '',
    String plate = '',
    String descripcion = 'Vehículo reportado como robado',
    String ubicacion = '',
  }) async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
    final String placaFinal = placa.isNotEmpty ? placa : plate;
    if (context != null && context.mounted) {
      await triggerProximityAlarm(
        context: context,
        alertType: 'robo',
        plate: placaFinal,
        vehicleDescription: ubicacion.isNotEmpty ? '$descripcion - $ubicacion' : descripcion,
      );
    }
  }

  static Future<void> detenerVoz() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
