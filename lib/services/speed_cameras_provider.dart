import 'dart:convert';
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

  const SpeedCameraPoint({
    required this.id,
    required this.lat,
    required this.lng,
    this.velocidad = 0,
    this.unidad = 'km/h',
    this.descripcion = 'Zona de control de velocidad',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'velocidad': velocidad,
        'unidad': unidad,
        'descripcion': descripcion,
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
    );
  }
}

class SpeedCamerasProvider {
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

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

  /// Obtiene cámaras de velocidad del continente americano alrededor de [center]
  /// (devuelve lista vacía si la jurisdicción restringe estas alertas).
  static Future<List<SpeedCameraPoint>> getCamerasAround(
    LatLng center, {
    int radioMetros = 30000,
  }) async {
    if (!isAllowedInLocation(center)) {
      return [];
    }

    final gridKey =
        'cams_v2_${(center.latitude * 5).round()}_${(center.longitude * 5).round()}';
    final prefs = await SharedPreferences.getInstance();

    final cachedRaw = prefs.getString(gridKey);
    final cachedTs = prefs.getInt('${gridKey}_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

    if (cachedRaw != null && (now - cachedTs) < sevenDaysMs) {
      try {
        final List decoded = jsonDecode(cachedRaw);
        return decoded
            .map((e) => SpeedCameraPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final fresh = await _fetchFromOverpass(center, radioMetros: radioMetros);
    if (fresh.isNotEmpty) {
      await prefs.setString(
        gridKey,
        jsonEncode(fresh.map((c) => c.toJson()).toList()),
      );
      await prefs.setInt('${gridKey}_ts', now);
      return fresh;
    }

    if (cachedRaw != null) {
      try {
        final List decoded = jsonDecode(cachedRaw);
        return decoded
            .map((e) => SpeedCameraPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return [];
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
