import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:latlong2/latlong.dart';

final FlutterTts tts = FlutterTts();
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();
final Set<String> yaAvisadas = {};

List<LatLng> rutaActual = [];

void setRutaActual(List<LatLng> puntos) {
  rutaActual = puntos;
  yaAvisadas.clear();
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'camara_channel',
    'Cámaras de Fotodetección',
    description: 'Alertas de cámaras en tu ruta activa',
    importance: Importance.high,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'camara_channel',
      initialNotificationTitle: 'S.O.S. Auto activo',
      initialNotificationContent: 'Vigilando cámaras de fotodetección',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

double distanciaALaRuta(double lat, double lng) {
  if (rutaActual.isEmpty) return 999999;
  double menor = 999999;
  for (final p in rutaActual) {
    final d = Geolocator.distanceBetween(lat, lng, p.latitude, p.longitude);
    if (d < menor) menor = d;
  }
  return menor;
}

int indiceMasCercano(double lat, double lng) {
  int mejor = 0;
  double menor = 999999;
  for (int i = 0; i < rutaActual.length; i++) {
    final d = Geolocator.distanceBetween(
      lat,
      lng,
      rutaActual[i].latitude,
      rutaActual[i].longitude,
    );
    if (d < menor) {
      menor = d;
      mejor = i;
    }
  }
  return mejor;
}

/// Verifica si la cámara está frente al vehículo según su rumbo (heading)
bool _estaAdelantePorRumbo(
  double userLat,
  double userLng,
  double userHeading,
  double camLat,
  double camLng,
) {
  // Si el GPS aún no reporta rumbo válido (vehículo quieto), permite alerta
  if (userHeading < 0) return true;

  final bearing = Geolocator.bearingBetween(userLat, userLng, camLat, camLng);
  final bearingNorm = (bearing + 360) % 360;
  final diff = ((bearingNorm - userHeading + 540) % 360) - 180;
  return diff.abs() <= 65; // Cono frontal de 130°
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}

  await tts.setLanguage('es-ES');
  await tts.setSpeechRate(0.55);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  List> camaras = [];
  StreamSubscription? camSub;
  StreamSubscription? rutaSub;
  Timer? timer;

  camSub = FirebaseFirestore.instance.collection('camaras').snapshots().listen(
    (snap) {
      camaras = snap.docs.map((d) => d.data()).toList();
    },
    onError: (_) {},
  );

  rutaSub = FirebaseFirestore.instance
      .collection('ruta_activa')
      .doc('actual')
      .snapshots()
      .listen(
    (doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final List puntos = data['puntos'] ?? [];
        rutaActual = puntos
            .map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList();
        yaAvisadas.clear();
      }
    },
    onError: (_) {},
  );

  service.on('stopService').listen((_) {
    timer?.cancel();
    camSub?.cancel();
    rutaSub?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (camaras.isEmpty) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return;
    }

    final bool tieneRuta = rutaActual.isNotEmpty;
    final int indiceUsuario =
        tieneRuta ? indiceMasCercano(pos.latitude, pos.longitude) : 0;

    for (final cam in camaras) {
      final double lat = (cam['lat'] ?? 0).toDouble();
      final double lng = (cam['lng'] ?? 0).toDouble();
      if (lat == 0 && lng == 0) continue;

      final String id = cam['id']?.toString() ?? '$lat-$lng';
      final int velocidadMax = (cam['velocidad'] ?? 0) is num
          ? (cam['velocidad'] as num).toInt()
          : 0;

      final double distUsuario = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        lat,
        lng,
      );

      bool debeAlertar = false;

      if (tieneRuta) {
        // Modo 1: Ruta trazada activa
        final double distRuta = distanciaALaRuta(lat, lng);
        final int indiceCamara = indiceMasCercano(lat, lng);
        debeAlertar =
            distRuta < 120 && indiceCamara > indiceUsuario && distUsuario < 600;
      } else {
        // Modo 2: Conducción libre sin ruta cargada en Firestore
        debeAlertar = distUsuario < 500 &&
            _estaAdelantePorRumbo(
              pos.latitude,
              pos.longitude,
              pos.heading,
              lat,
              lng,
            );
      }

      if (debeAlertar && !yaAvisadas.contains(id)) {
        yaAvisadas.add(id);
        final String textoVelocidad =
            velocidadMax > 0 ? ', límite $velocidadMax kilómetros por hora' : '';
        final String mensaje =
            'Atención, cámara de fotomulta a ${distUsuario.toInt()} metros$textoVelocidad, reduce la velocidad';

        await tts.speak(mensaje);
        await notifications.show(
          889,
          'Cámara de fotodetección cercana',
          mensaje,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'camara_channel',
              'Cámaras de Fotodetección',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (distUsuario > 700) {
        yaAvisadas.remove(id);
      }
    }
  });
}
