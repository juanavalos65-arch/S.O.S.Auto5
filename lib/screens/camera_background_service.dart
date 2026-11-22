import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

final FlutterTts tts = FlutterTts();
final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
final Set<String> yaAvisadas = {};

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationId: 888,
      initialNotificationTitle: 'S.O.S. Auto activo',
      initialNotificationContent: 'Vigilando cámaras de fotomulta cerca de ti',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  await Firebase.initializeApp();
  await tts.setLanguage('es-ES');
  await tts.setSpeechRate(0.55);
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(const InitializationSettings(android: androidInit));

  List<Map<String, dynamic>> camaras = [];
  FirebaseFirestore.instance.collection('camaras').snapshots().listen((snap) {
    camaras = snap.docs.map((d) => d.data()).toList();
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) { return; }
    for (var cam in camaras) {
      final double lat = (cam['lat'] ?? 0).toDouble();
      final double lng = (cam['lng'] ?? 0).toDouble();
      final String id = cam['id']?.toString() ?? '$lat-$lng';
      final double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      if (dist < 500 && !yaAvisadas.contains(id)) {
        yaAvisadas.add(id);
        final String mensaje = 'Atención, cámara de fotomulta a ${dist.toInt()} metros, reduce la velocidad';
        await tts.speak(mensaje);
        await notifications.show(0, '📸 Cámara cerca', mensaje, const NotificationDetails(android: AndroidNotificationDetails('camara_channel', 'Cámaras', importance: Importance.high)));
      }
      if (dist > 600) yaAvisadas.remove(id);
    }
  });
}
