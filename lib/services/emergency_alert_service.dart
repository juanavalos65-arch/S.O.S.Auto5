import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_alert_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await EmergencyAlertService.initNotifications();

  final data = message.data;
  if (data['tipo'] == 'robo_vehiculo') {
    final placa = (data['placa'] ?? '').toString();
    final descripcion = (data['descripcion'] ?? '').toString();
    if (placa.isNotEmpty) {
      await EmergencyAlertService.alertarRoboBackground(
        placa: placa,
        descripcion: descripcion,
      );
    }
  }
}

class TheftAlertListener {
  static StreamSubscription<QuerySnapshot>? _sub;
  static final Set<String> _alertasProcesadas = {};
  static final DateTime _inicioSesion = DateTime.now();

  static Future<void> iniciar({String? ciudad}) async {
    await EmergencyAlertService.initNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.subscribeToTopic('alertas_robo_global');

    if (ciudad != null && ciudad.trim().isNotEmpty) {
      final topicCiudad =
          'alertas_${ciudad.trim().toLowerCase().replaceAll(' ', '_')}';
      await FirebaseMessaging.instance.subscribeToTopic(topicCiudad);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _procesarPayload(
        id: message.messageId ?? DateTime.now().toIso8601String(),
        data: message.data,
      );
    });

    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('vehiculos_robados')
        .where('activo', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      final miPlaca = (prefs.getString('placa') ?? '').trim().toUpperCase();

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        final ts = data['fecha'] ?? data['createdAt'];
        if (ts is Timestamp &&
            ts.toDate().isBefore(
                _inicioSesion.subtract(const Duration(seconds: 30)))) {
          continue;
        }

        final placaReportada =
            (data['placa'] ?? '').toString().trim().toUpperCase();

        if (miPlaca.isNotEmpty && placaReportada == miPlaca) continue;

        await _procesarPayload(
          id: doc.id,
          data: {
            'tipo': 'robo_vehiculo',
            'placa': placaReportada,
            'descripcion': (data['descripcion'] ??
                    '${data['marca'] ?? ''} ${data['color'] ?? ''}')
                .toString(),
          },
        );
      }
    });
  }

  static Future<void> _procesarPayload({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (_alertasProcesadas.contains(id)) return;
    _alertasProcesadas.add(id);

    if (data['tipo'] != 'robo_vehiculo') return;
    final placa = (data['placa'] ?? '').toString();
    if (placa.isEmpty) return;

    await EmergencyAlertService.alertarRoboBackground(
      placa: placa,
      descripcion: (data['descripcion'] ?? '').toString(),
    );
  }
}
