import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final FlutterTts tts = FlutterTts();
final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
final Set<String> yaAvisadas = {};

// AQUI SE GUARDA LA RUTA ACTUAL
List<LatLng> rutaActual = [];

/// ESTA FUNCION LA LLAMA TU MAPA CUANDO CALCULAS UNA RUTA
void setRutaActual(List<LatLng> puntos) {
  rutaActual = puntos;
  yaAvisadas.clear();
  debugPrint('Ruta actualizada con ${puntos.length} puntos');
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationId: 888,
      initialNotificationTitle: 'S.O.S. Auto activo',
      initialNotificationContent: 'Vigilando cámaras en tu ruta',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );
}

// Distancia de un punto a la ruta completa
double distanciaALaRuta(double lat, double lng) {
  if (rutaActual.isEmpty) return 999999;
  double menor = 999999;
  for (var p in rutaActual) {
    final d = Geolocator.distanceBetween(lat, lng, p.latitude, p.longitude);
    if (d < menor) menor = d;
  }
  return menor;
}

// En que parte de la ruta va el usuario y en que parte va la cámara
int indiceMasCercano(double lat, double lng) {
  int mejorIndice = 0;
  double menor = 999999;
  for (int i = 0; i < rutaActual.length; i++) {
    final d = Geolocator.distanceBetween(lat, lng, rutaActual[i].latitude, rutaActual[i].longitude);
    if (d < menor) {
      menor = d;
      mejorIndice = i;
    }
  }
  return mejorIndice;
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

  // Escucha la ruta que le manda el mapa por Firestore
  FirebaseFirestore.instance.collection('ruta_activa').doc('actual').snapshots().listen((doc) {
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final List puntos = data['puntos'] ?? [];
      rutaActual = puntos.map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();
    }
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (rutaActual.isEmpty) return; // Si no hay ruta, no avisa de nada

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) { return; }

    final int indiceUsuario = indiceMasCercano(pos.latitude, pos.longitude);

    for (var cam in camaras) {
      final double lat = (cam['lat'] ?? 0).toDouble();
      final double lng = (cam['lng'] ?? 0).toDouble();
      final String id = cam['id']?.toString() ?? '$lat-$lng';

      final double distUsuarioCamara = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      final double distCamaraRuta = distanciaALaRuta(lat, lng);
      final int indiceCamara = indiceMasCercano(lat, lng);

      // REGLA DE ORO: Solo si está en la ruta, adelante tuyo y cerca
      final bool estaEnMiRuta = distCamaraRuta < 120; // 120 metros de la línea de la ruta
      final bool estaAdelante = indiceCamara > indiceUsuario;
      final bool estaCerca = distUsuarioCamara < 600;

      if (estaEnMiRuta && estaAdelante && estaCerca && !yaAvisadas.contains(id)) {
        yaAvisadas.add(id);
        final String mensaje = 'Atención, cámara de fotomulta en tu ruta a ${distUsuarioCamara.toInt()} metros, reduce la velocidad';
        await tts.speak(mensaje);
        await notifications.show(0, '📸 Cámara en tu ruta', mensaje, const NotificationDetails(android: AndroidNotificationDetails('camara_channel', 'Cámaras', importance: Importance.high)));
      }
      if (distUsuarioCamara > 700) yaAvisadas.remove(id);
    }
  });
}
