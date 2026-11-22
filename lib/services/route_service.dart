import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;
  final String destinationName;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.destinationName,
  });
}

class RouteService {
  /// Busca una dirección o ciudad y calcula la ruta desde [origin] hasta ese destino.
  static Future<RouteResult?> searchAndRoute(
    LatLng origin,
    String destinationQuery,
  ) async {
    final cleanQuery = destinationQuery.trim();
    if (cleanQuery.isEmpty) return null;

    try {
      // 1. Geocodificación gratuita con Nominatim (OpenStreetMap)
      final nominatimUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=1',
      );

      final geoResponse = await http.get(
        nominatimUri,
        headers: {
          'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (geoResponse.statusCode != 200) return null;

      final List places = jsonDecode(geoResponse.body);
      if (places.isEmpty) return null;

      final first = places.first as Map;
      final double destLat = double.parse(first['lat'].toString());
      final double destLng = double.parse(first['lon'].toString());
      final String displayName =
          first['display_name']?.toString().split(',').first ?? cleanQuery;

      // 2. Cálculo de ruta por vías con OSRM (gratuito, sin API key)
      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};$destLng,$destLat'
        '?overview=full&geometries=geojson',
      );

      final routeResponse =
          await http.get(osrmUri).timeout(const Duration(seconds: 12));

      if (routeResponse.statusCode != 200) return null;

      final Map routeJson = jsonDecode(routeResponse.body);
      final List routes = routeJson['routes'] ?? [];
      if (routes.isEmpty) return null;

      final bestRoute = routes.first as Map;
      final geometry = bestRoute['geometry'] as Map;
      final List coords = geometry['coordinates'] ?? [];

      final List<LatLng> routePoints = coords.map((c) {
        final pair = c as List;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      final double distMeters = (bestRoute['distance'] as num).toDouble();
      final double durSeconds = (bestRoute['duration'] as num).toDouble();

      return RouteResult(
        points: routePoints,
        distanceKm: distMeters / 1000.0,
        durationMin: (durSeconds / 60.0).round(),
        destinationName: displayName,
      );
    } catch (_) {
      return null;
    }
  }
}
