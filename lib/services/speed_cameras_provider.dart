import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SpeedCameraPoint {
  final String id;
  final double lat;
  final double lng;
  final int velocidad;
  final String descripcion;

  const SpeedCameraPoint({
    required this.id,
    required this.lat,
    required this.lng,
    this.velocidad = 0,
    this.descripcion = 'Cámara de fotodetección',
  });
}

class SpeedCamerasProvider {
  /// Cámaras base offline (funcionan incluso sin internet)
  static const List<SpeedCameraPoint> camarasBase = [
    // Medellín (corredores principales de fotodetección)
    SpeedCameraPoint(
      id: 'med_reg_1',
      lat: 6.2468,
      lng: -75.5762,
      velocidad: 60,
      descripcion: 'Av. Regional — Sector La Alpujarra',
    ),
    SpeedCameraPoint(
      id: 'med_reg_2',
      lat: 6.2154,
      lng: -75.5789,
      velocidad: 60,
      descripcion: 'Av. Regional — Sector Industriales / Poblado',
    ),
    SpeedCameraPoint(
      id: 'med_aut_1',
      lat: 6.2845,
      lng: -75.5638,
      velocidad: 60,
      descripcion: 'Autopista Norte — Sector Punto Cero / Caribe',
    ),
    SpeedCameraPoint(
      id: 'med_las_1',
      lat: 6.2192,
      lng: -75.5574,
      velocidad: 50,
      descripcion: 'Av. Las Palmas — Sector San Diego',
    ),
    // Sincelejo / Troncal de Occidente
    SpeedCameraPoint(
      id: 'sin_troncal_1',
      lat: 9.2958,
      lng: -75.3961,
      velocidad: 50,
      descripcion: 'Troncal de Occidente — Sincelejo',
    ),
  ];

  /// Consulta gratuita a OpenStreetMap (Overpass API) en un radio de [radioMetros]
  static Future<List<SpeedCameraPoint>> fetchOsmCameras(
    LatLng center, {
    int radioMetros = 25000,
  }) async {
    final query = '''
[out:json][timeout:10];
node["highway"="speed_camera"](around:$radioMetros,${center.latitude},${center.longitude});
out body;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (decoded['elements'] as List?) ?? [];

      return elements.map((e) {
        final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
        final maxSpeedRaw = tags['maxspeed']?.toString() ?? '0';
        final vel = int.tryParse(maxSpeedRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        return SpeedCameraPoint(
          id: 'osm_${e['id']}',
          lat: (e['lat'] as num).toDouble(),
          lng: (e['lon'] as num).toDouble(),
          velocidad: vel,
          descripcion: tags['name']?.toString() ?? 'Cámara fotodetección (OSM)',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
