import 'dart:async';
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

import '../services/speed_cameras_provider.dart';

final FlutterTts tts = FlutterTts();
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();
final Set yaAvisadas = {};

List rutaActual = [];

void setRutaActual(List puntos) {
  rutaActual = puntos;
  yaAvisadas.clear();
}

Future initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'camara_channel',
    'Control de Velocidad',
    description: 'Alertas preventivas de zonas de control de velocidad',
    importance: Importance.high,
  );

  await notifications
      .resolvePlatformSpecificImplementation()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'camara_channel',
      initialNotificationTitle: 'S.O.S. Auto activo',
      initialNotificationContent: 'Asistencia vial y alertas preventivas activas',
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

bool _estaAdelantePorRumbo(
  double userLat,
  double userLng,
  double userHeading,
  double camLat,
  double camLng,
) {
  if (userHeading < 0) return true;
  final bearing = Geolocator.bearingBetween(userLat, userLng, camLat, camLng);
  final bearingNorm = (bearing + 360) % 360;
  final diff = ((bearingNorm - userHeading + 540) % 360) - 180;
  return diff.abs() <= 65;
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

  List camarasFirestore = [];
  List camarasContinentales = [];
  DateTime ultimaConsultaOsm = DateTime.fromMillisecondsSinceEpoch(0);

  final camSub =
      FirebaseFirestore.instance.collection('camaras').snapshots().listen(
    (snap) {
      camarasFirestore = snap.docs.map((d) {
        final data = d.data();
        return SpeedCameraPoint(
          id: data['id']?.toString() ?? d.id,
          lat: (data['lat'] ?? 0).toDouble(),
          lng: (data['lng'] ?? 0).toDouble(),
          velocidad: (data['velocidad'] is num)
              ? (data['velocidad'] as num).toInt()
              : 0,
          unidad: data['unidad']?.toString() ?? 'km/h',
          descripcion: data['descripcion']?.toString() ??
              'Zona de control de velocidad',
        );
      }).toList();
    },
    onError: (_) {},
  );

  final rutaSub = FirebaseFirestore.instance
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

  Timer? timer;
  service.on('stopService').listen((_) {
    timer?.cancel();
    camSub.cancel();
    rutaSub.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 5), (_) async {
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

    final currentLatLng = LatLng(pos.latitude, pos.longitude);

    if (!SpeedCamerasProvider.isAllowedInLocation(currentLatLng)) {
      return;
    }

    if (DateTime.now().difference(ultimaConsultaOsm).inMinutes >= 10) {
      ultimaConsultaOsm = DateTime.now();
      camarasContinentales =
          await SpeedCamerasProvider.getCamerasAround(currentLatLng);
    }

    final todasLasCamaras = [...camarasContinentales, ...camarasFirestore];
    if (todasLasCamaras.isEmpty) return;

    final bool tieneRuta = rutaActual.isNotEmpty;
    final int indiceUsuario =
        tieneRuta ? indiceMasCercano(pos.latitude, pos.longitude) : 0;

    for (final cam in todasLasCamaras) {
      if (cam.lat == 0 && cam.lng == 0) continue;

      final double distUsuario = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        cam.lat,
        cam.lng,
      );

      bool debeAlertar = false;

      if (tieneRuta) {
        final double distRuta = distanciaALaRuta(cam.lat, cam.lng);
        final int indiceCamara = indiceMasCercano(cam.lat, cam.lng);
        debeAlertar =
            distRuta < 120 && indiceCamara > indiceUsuario && distUsuario < 600;
      } else {
        debeAlertar = distUsuario < 500 &&
            _estaAdelantePorRumbo(
              pos.latitude,
              pos.longitude,
              pos.heading,
              cam.lat,
              cam.lng,
            );
      }

      if (debeAlertar && !yaAvisadas.contains(cam.id)) {
        yaAvisadas.add(cam.id);
        final String unidadVoz =
            cam.unidad == 'mph' ? 'millas por hora' : 'kilómetros por hora';
        final String textoVelocidad =
            cam.velocidad > 0 ? ', límite ${cam.velocidad} $unidadVoz' : '';
        final String mensaje =
            'Atención, zona de control de velocidad a ${distUsuario.toInt()} metros$textoVelocidad';

        await tts.speak(mensaje);
        await notifications.show(
          889,
          'Control de velocidad cercano',
          mensaje,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'camara_channel',
              'Control de Velocidad',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (distUsuario > 700) {
        yaAvisadas.remove(cam.id);
      }
    }
  });
}
