import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manejador de nivel superior obligatorio para recibir alertas con la app CERRADA
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Alerta S.O.S. Auto en segundo plano: ${message.notification?.title}');
}

class BackgroundAlertPermissionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _prefKey = 'sos_auto_bg_alerts_asked';

  /// Pide permiso explícito al usuario para activar alertas cuando la app esté cerrada
  static Future<void> solicitarPermisoAlertasCerrada(BuildContext context) async {
    final yaPreguntado = await _storage.read(key: _prefKey);
    if (yaPreguntado == 'true') {
      await _activarSuscripcionPush();
      return;
    }

    if (!context.mounted) return;

    final bool? usuarioAcepta = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFFB71C1C), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Activar Alertas con la App Cerrada',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas recibir alertas de robo de vehículos y emergencias cercanas incluso cuando tengas S.O.S. Auto cerrada o el teléfono bloqueado?\n\n'
          'Para lograrlo, te pediremos autorización para:\n'
          '• Notificaciones sonoras críticas en segundo plano.\n'
          '• Ubicación en segundo plano ("Permitir todo el tiempo") únicamente para detectar alertas cerca de tu ruta.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'AHORA NO',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E4F),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('ACTIVAR ALERTAS'),
          ),
        ],
      ),
    );

    await _storage.write(key: _prefKey, value: 'true');

    if (usuarioAcepta == true) {
      await _activarSuscripcionPush();
      await _solicitarUbicacionSegundoPlano();
    }
  }

  static Future<void> _activarSuscripcionPush() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await messaging.subscribeToTopic('alertas_emergencia_sos_auto');
      }
    } catch (_) {}
  }

  static Future<void> _solicitarUbicacionSegundoPlano() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }
}
