import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MedicalCenterPoint {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;

  const MedicalCenterPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
  });
}

class MedicalCentersProvider {
  static LatLng? _lastQueryCenter;
  static List<MedicalCenterPoint> _cachedCenters = [];

  static Future<List<MedicalCenterPoint>> getNearbyCenters(
    LatLng center,
  ) async {
    if (_lastQueryCenter != null && _cachedCenters.isNotEmpty) {
      final dLat = (_lastQueryCenter!.latitude - center.latitude).abs();
      final dLng = (_lastQueryCenter!.longitude - center.longitude).abs();
      if (dLat < 0.04 && dLng < 0.04) {
        return _cachedCenters;
      }
    }

    try {
      final query = '''
[out:json][timeout:12];
(
  node["amenity"~"hospital|clinic"](around:12000,${center.latitude},${center.longitude});
  way["amenity"~"hospital|clinic"](around:12000,${center.latitude},${center.longitude});
);
out center tags;
''';

      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return _cachedCenters;

      final Map data = jsonDecode(response.body);
      final List elements = data['elements'] ?? [];
      final List<MedicalCenterPoint> loaded = [];

      for (final el in elements) {
        final m = el as Map;
        final tags = (m['tags'] as Map?) ?? {};
        final String name = (tags['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        double? lat;
        double? lng;
        if (m['lat'] != null && m['lon'] != null) {
          lat = (m['lat'] as num).toDouble();
          lng = (m['lon'] as num).toDouble();
        } else if (m['center'] is Map) {
          final c = m['center'] as Map;
          lat = (c['lat'] as num?)?.toDouble();
          lng = (c['lon'] as num?)?.toDouble();
        }
        if (lat == null || lng == null) continue;

        final String street = (tags['addr:street'] ?? '').toString();
        final String house = (tags['addr:housenumber'] ?? '').toString();
        final String address =
            [street, house].where((s) => s.isNotEmpty).join(' ');
        final String phone =
            (tags['phone'] ?? tags['contact:phone'] ?? '').toString();

        loaded.add(
          MedicalCenterPoint(
            id: 'osm_med_${m['id']}',
            name: name,
            address: address.isNotEmpty ? address : 'Centro médico / Urgencias',
            phone: phone,
            lat: lat,
            lng: lng,
          ),
        );
      }

      _lastQueryCenter = center;
      _cachedCenters = loaded;
      return loaded;
    } catch (_) {
      return _cachedCenters;
    }
  }
}
