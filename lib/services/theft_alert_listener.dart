import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_alert_service.dart';
import 'firestore_rest_service.dart';


/// Manejador obligatorio para cuando la app está cerrada en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await EmergencyAlertService.initNotifications();

  final data = message.data;
  final tipo = (data['tipo'] ?? '').toString();
  if (tipo == 'robo_vehiculo') {
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
  static StreamSubscription<QuerySnapshot>? _subPulso;
  static StreamSubscription<QuerySnapshot>? _subRobos;
  static final Set<String> _alertasProcesadas = {};
  static final DateTime _inicioSesion = DateTime.now();

  /// Llamar una vez en main.dart después de Firebase.initializeApp()
  static Future<void> iniciar({String? ciudad}) async {
    await EmergencyAlertService.initNotifications();

    // 1. Canal FCM (app cerrada y app abierta)
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.subscribeToTopic('alertas_robo_global');

      if (ciudad != null && ciudad.trim().isNotEmpty) {
        final topicCiudad =
            'alertas_${ciudad.trim().toLowerCase().replaceAll(' ', '_')}';
        await FirebaseMessaging.instance.subscribeToTopic(topicCiudad);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _procesarAlerta(
          claveUnica:
              message.messageId ?? '${message.data['placa']}_${DateTime.now().minute}',
          tipo: (message.data['tipo'] ?? '').toString(),
          placa: (message.data['placa'] ?? '').toString(),
          descripcion: (message.data['descripcion'] ?? '').toString(),
        );
      });
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final miPlaca = (prefs.getString('placa') ?? '').trim().toUpperCase();

    // 2. Canal ultra-rápido: pulso_inmediato (sin filtros complejos)
    _subPulso?.cancel();
    _subPulso = FirebaseFirestore.instance
        .collection('pulso_inmediato')
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final ts = data['ts'];
        if (ts is Timestamp &&
            ts.toDate().isBefore(
                _inicioSesion.subtract(const Duration(seconds: 25)))) {
          continue;
        }

        final placa = (data['placa'] ?? '').toString().trim().toUpperCase();
        if (miPlaca.isNotEmpty && placa == miPlaca) continue;

        await _procesarAlerta(
          claveUnica: 'robo_${placa}_${DateTime.now().minute}',
          tipo: (data['tipo'] ?? 'robo_vehiculo').toString(),
          placa: placa,
          descripcion: (data['descripcion'] ?? '').toString(),
        );
      }
    });

    // 3. Canal de respaldo: vehiculos_robados
    _subRobos?.cancel();
    _subRobos = FirebaseFirestore.instance
        .collection('vehiculos_robados')
        .where('activo', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final ts = data['fecha'] ?? data['createdAt'];
        if (ts is Timestamp &&
            ts.toDate().isBefore(
                _inicioSesion.subtract(const Duration(seconds: 25)))) {
          continue;
        }

        final placa = (data['placa'] ?? '').toString().trim().toUpperCase();
        if (miPlaca.isNotEmpty && placa == miPlaca) continue;

        final desc = (data['descripcion'] ??
                '${data['marca'] ?? ''} ${data['color'] ?? ''}')
            .toString();

        await _procesarAlerta(
          claveUnica: 'robo_${placa}_${DateTime.now().minute}',
          tipo: 'robo_vehiculo',
          placa: placa,
          descripcion: desc,
        );
      }
    });
  }

  static Future<void> _procesarAlerta({
    required String claveUnica,
    required String tipo,
    required String placa,
    required String descripcion,
  }) async {
    if (_alertasProcesadas.contains(claveUnica)) return;
    _alertasProcesadas.add(claveUnica);

    if (tipo == 'robo_vehiculo' && placa.isNotEmpty) {
      await EmergencyAlertService.alertarRoboBackground(
        placa: placa,
        descripcion: descripcion,
      );
    } else if (tipo == 'peligro') {
      await EmergencyAlertService.alertarPeligro(mensaje: descripcion);
    } else if (tipo == 'accidente') {
      await EmergencyAlertService.alertarAccidente(mensaje: descripcion);
    }
  }

  /// Helper para disparar el pulso relámpago desde cualquier pantalla de emergencia
  static void emitirPulsoInmediato({
    required String tipo,
    String placa = '',
    String descripcion = '',
  }) {
    unawaited(
      FirebaseFirestore.instance.collection('pulso_inmediato').add({
        'tipo': tipo,
        'placa': placa.trim().toUpperCase(),
        'descripcion': descripcion.trim(),
        'ts': FieldValue.serverTimestamp(),
      }),
    );
  }
}
