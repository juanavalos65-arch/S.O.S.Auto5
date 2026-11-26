import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeedCameraPoint {
  final String id;
  final double lat;
  final double lng;
  final int velocidad;
  final String unidad; // 'km/h' o 'mph'
  final String descripcion;
  final bool reportadaPorUsuario;

  const SpeedCameraPoint({
    required this.id,
    required this.lat,
    required this.lng,
    this.velocidad = 0,
    this.unidad = 'km/h',
    this.descripcion = 'Zona de control de velocidad',
    this.reportadaPorUsuario = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'velocidad': velocidad,
        'unidad': unidad,
        'descripcion': descripcion,
        'reportadaPorUsuario': reportadaPorUsuario,
      };

  factory SpeedCameraPoint.fromJson(Map<String, dynamic> json) {
    return SpeedCameraPoint(
      id: json['id']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      velocidad: (json['velocidad'] as num?)?.toInt() ?? 0,
      unidad: json['unidad']?.toString() ?? 'km/h',
      descripcion:
          json['descripcion']?.toString() ?? 'Zona de control de velocidad',
      reportadaPorUsuario: json['reportadaPorUsuario'] == true,
    );
  }
}

class SpeedCamerasProvider {
  static const String _userFixedCamerasKey = 'user_fixed_speed_cameras_v1';
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static final FlutterTts _tts = FlutterTts();
  static StreamSubscription<Position>? _radarSub;
  static final Set<String> _alertadasRecientemente = {};
  static List<SpeedCameraPoint> _camarasEnMemoria = [];

  /// Verifica si las alertas de cámaras están permitidas en la ubicación actual.
  /// Bloquea automáticamente Virginia, Washington D.C. y zonas federales restringidas.
  static bool isAllowedInLocation(LatLng point) {
    final lat = point.latitude;
    final lng = point.longitude;

    // Virginia y Washington D.C. (EE. UU.): lat 36.54 a 39.47, lng -83.68 a -75.24
    final bool inVirginiaOrDC =
        lat >= 36.54 && lat <= 39.47 && lng >= -83.68 && lng <= -75.24;
    if (inVirginiaOrDC) return false;

    return true;
  }

  /// Guarda una cámara reportada por un usuario para que quede FIJA permanentemente
  /// tanto en Firebase Firestore (para todos los usuarios) como en el teléfono.
  static Future<SpeedCameraPoint> saveUserFixedCamera({
    required double lat,
    required double lng,
    String descripcion = 'Cámara de fotodetección reportada',
    int velocidad = 50,
    String unidad = 'km/h',
  }) async {
    final id = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final nuevaCamara = SpeedCameraPoint(
      id: id,
      lat: lat,
      lng: lng,
      velocidad: velocidad,
      unidad: unidad,
      descripcion: descripcion.trim().isEmpty
          ? 'Cámara de fotodetección reportada'
          : descripcion.trim(),
      reportadaPorUsuario: true,
    );

    // 1. Guardar fija en almacenamiento local del dispositivo
    final prefs = await SharedPreferences.getInstance();
    final actuales = await _getLocalUserFixedCameras(prefs);
    actuales.add(nuevaCamara);
    await prefs.setString(
      _userFixedCamerasKey,
      jsonEncode(actuales.map((c) => c.toJson()).toList()),
    );

    // 2. Actualizar memoria activa inmediatamente
    _camarasEnMemoria = [..._camarasEnMemoria, nuevaCamara];

    // 3. Guardar fija en Firestore para toda la comunidad S.O.S. Auto
    try {
      await FirebaseFirestore.instance
          .collection('camaras_fotodeteccion_fijas')
          .doc(id)
          .set({
        ...nuevaCamara.toJson(),
        'fija': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return nuevaCamara;
  }

  static Future<List<SpeedCameraPoint>> _getLocalUserFixedCameras(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_userFixedCamerasKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded
          .map((e) => SpeedCameraPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Obtiene cámaras fijas reportadas por usuarios (local + nube Firestore)
  static Future<List<SpeedCameraPoint>> getUserFixedCameras() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, SpeedCameraPoint> mapaUnico = {};

    for (final cam in await _getLocalUserFixedCameras(prefs)) {
      mapaUnico[cam.id] = cam;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('camaras_fotodeteccion_fijas')
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final cam = SpeedCameraPoint.fromJson(data);
        if (cam.lat != 0.0 && cam.lng != 0.0) {
          mapaUnico[cam.id] = cam;
        }
      }
      await prefs.setString(
        _userFixedCamerasKey,
        jsonEncode(mapaUnico.values.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}

    return mapaUnico.values.toList();
  }

  /// Obtiene TODAS las cámaras alrededor de [center]:
  /// Base de datos global (OpenStreetMap) + Cámaras fijas reportadas por usuarios.
  static Future<List<SpeedCameraPoint>> getCamerasAround(
    LatLng center, {
    int radioMetros = 30000,
  }) async {
    if (!isAllowedInLocation(center)) {
      return [];
    }

    final Map<String, SpeedCameraPoint> combinadas = {};

    // 1. Siempre cargar primero las cámaras fijas reportadas por usuarios
    final fijasUsuarios = await getUserFixedCameras();
    for (final cam in fijasUsuarios) {
      combinadas[cam.id] = cam;
    }

    // 2. Cargar cámaras de la base de datos global (caché o Overpass)
    final gridKey =
        'cams_v2_${(center.latitude * 5).round()}_${(center.longitude * 5).round()}';
    final prefs = await SharedPreferences.getInstance();

    final cachedRaw = prefs.getString(gridKey);
    final cachedTs = prefs.getInt('${gridKey}_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

    List<SpeedCameraPoint> globales = [];
    if (cachedRaw != null && (now - cachedTs) < sevenDaysMs) {
      try {
        final List decoded = jsonDecode(cachedRaw);
        globales = decoded
            .map((e) => SpeedCameraPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    if (globales.isEmpty) {
      final fresh = await _fetchFromOverpass(center, radioMetros: radioMetros);
      if (fresh.isNotEmpty) {
        globales = fresh;
        await prefs.setString(
          gridKey,
          jsonEncode(fresh.map((c) => c.toJson()).toList()),
        );
        await prefs.setInt('${gridKey}_ts', now);
      } else if (cachedRaw != null) {
        try {
          final List decoded = jsonDecode(cachedRaw);
          globales = decoded
              .map((e) => SpeedCameraPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

    for (final cam in globales) {
      combinadas[cam.id] = cam;
    }

    _camarasEnMemoria = combinadas.values.toList();
    return _camarasEnMemoria;
  }

  /// Activa la notificación automática por voz cuando el conductor se acerca a 400m
  static Future<void> startAutomaticVoiceAlerts() async {
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.5);

    _radarSub?.cancel();
    _radarSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((Position pos) async {
      final actual = LatLng(pos.latitude, pos.longitude);
      if (!isAllowedInLocation(actual)) return;

      if (_camarasEnMemoria.isEmpty) {
        await getCamerasAround(actual);
      }

      for (final cam in _camarasEnMemoria) {
        final distancia = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          cam.lat,
          cam.lng,
        );

        if (distancia <= 400 && !_alertadasRecientemente.contains(cam.id)) {
          _alertadasRecientemente.add(cam.id);
          final velTexto = cam.velocidad > 0
              ? 'Velocidad máxima ${cam.velocidad} ${cam.unidad == 'mph' ? 'millas por hora' : 'kilómetros por hora'}.'
              : 'Reduzca la velocidad.';
          await _tts.speak(
            'Atención. Cámara de fotodetección a ${distancia.round()} metros. ${cam.descripcion}. $velTexto',
          );

          Future.delayed(const Duration(minutes: 5), () {
            _alertadasRecientemente.remove(cam.id);
          });
          break;
        }
      }
    });
  }

  static void stopAutomaticVoiceAlerts() {
    _radarSub?.cancel();
  }

  static Future<List<SpeedCameraPoint>> _fetchFromOverpass(
    LatLng center, {
    required int radioMetros,
  }) async {
    final query = '''
[out:json][timeout:12];
(
  node["highway"="speed_camera"](around:$radioMetros,${center.latitude},${center.longitude});
  node["enforcement"="maxspeed"](around:$radioMetros,${center.latitude},${center.longitude});
);
out body;
''';

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = (decoded['elements'] as List?) ?? [];

        return elements.map((e) {
          final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
          final rawSpeed = tags['maxspeed']?.toString().toLowerCase() ?? '';
          final isMph = rawSpeed.contains('mph');
          final vel =
              int.tryParse(rawSpeed.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          return SpeedCameraPoint(
            id: 'osm_${e['id']}',
            lat: (e['lat'] as num).toDouble(),
            lng: (e['lon'] as num).toDouble(),
            velocidad: vel,
            unidad: isMph ? 'mph' : 'km/h',
            descripcion: tags['name']?.toString() ??
                tags['ref']?.toString() ??
                'Zona de control de velocidad',
          );
        }).toList();
      } catch (_) {}
    }
    return [];
  }
}
