import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;
  final String destinationName;
  final bool avoidedIncidents;
  final List<String> routeWarnings;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.destinationName,
    this.avoidedIncidents = false,
    this.routeWarnings = const [],
  });
}

class _ActiveRoadHazard {
  final double lat;
  final double lng;
  final String label;
  final double penaltySeconds;

  const _ActiveRoadHazard({
    required this.lat,
    required this.lng,
    required this.label,
    required this.penaltySeconds,
  });
}

class RouteService {
  static double _calcularPenalizacionSegundos(
    String tipo,
    String estadoPaso,
  ) {
    final texto = '${tipo.toLowerCase()} ${estadoPaso.toLowerCase()}';

    if (texto.contains('totalmente cerrada') ||
        texto.contains('bloqueo') ||
        texto.contains('derrumbe') ||
        texto.contains('vía cerrada')) {
      return 7200; // +2 horas para forzar desvío si existe ruta alterna
    }
    if (texto.contains('accidente') ||
        texto.contains('inundación') ||
        texto.contains('árbol caído')) {
      return 2700; // +45 min
    }
    if (texto.contains('restringido') ||
        texto.contains('congestión') ||
        texto.contains('tráfico lento')) {
      return 1500; // +25 min
    }
    return 600; // +10 min para retenes, huecos u otras novedades
  }

  static Future<List<_ActiveRoadHazard>> _fetchActiveHazards() async {
    final List<_ActiveRoadHazard> hazards = [];
    try {
      if (Firebase.apps.isEmpty) return hazards;

      final snapshot = await FirebaseFirestore.instance
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(40)
          .get()
          .timeout(const Duration(seconds: 4));

      final ahora = DateTime.now();

      for (final doc in snapshot.docs) {
        final raw = doc.data();
        if (raw['activo'] == false) continue;

        // Las cámaras de fotodetección no bloquean el paso
        final bool esPermanente = raw['esPermanente'] == true;
        if (esPermanente) continue;

        final Timestamp? expiraTs = raw['expiraEn'] as Timestamp?;
        if (expiraTs != null && expiraTs.toDate().isBefore(ahora)) {
          continue;
        }

        final double? lat =
            (raw['lat'] is num) ? (raw['lat'] as num).toDouble() : null;
        final double? lng =
            (raw['lng'] is num) ? (raw['lng'] as num).toDouble() : null;
        if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;

        final String tipo = (raw['tipo'] ?? 'Novedad vial').toString();
        final String estadoPaso = (raw['estadoPaso'] ?? '').toString();
        final String sector = (raw['sector'] ?? '').toString();

        final String etiqueta = [
          tipo,
          if (sector.isNotEmpty) 'en $sector',
          if (estadoPaso.isNotEmpty) '($estadoPaso)',
        ].join(' ');

        hazards.add(
          _ActiveRoadHazard(
            lat: lat,
            lng: lng,
            label: etiqueta,
            penaltySeconds: _calcularPenalizacionSegundos(tipo, estadoPaso),
          ),
        );
      }
    } catch (_) {}
    return hazards;
  }

  static List<_ActiveRoadHazard> _findHazardsOnRoute(
    List<LatLng> routePoints,
    List<_ActiveRoadHazard> hazards,
  ) {
    if (routePoints.isEmpty || hazards.isEmpty) return [];

    // Muestreamos puntos de la polilínea cada ~100 m para evaluar rápido
    final List<LatLng> sampled = [routePoints.first];
    for (int i = 1; i < routePoints.length; i++) {
      final d = Geolocator.distanceBetween(
        sampled.last.latitude,
        sampled.last.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );
      if (d >= 90 || i == routePoints.length - 1) {
        sampled.add(routePoints[i]);
      }
    }

    final List<_ActiveRoadHazard> matched = [];
    for (final h in hazards) {
      for (final pt in sampled) {
        final dist = Geolocator.distanceBetween(
          pt.latitude,
          pt.longitude,
          h.lat,
          h.lng,
        );
        if (dist <= 180) {
          matched.add(h);
          break;
        }
      }
    }
    return matched;
  }

  /// Busca una dirección o ciudad y calcula la mejor ruta desde [origin],
  /// evaluando rutas alternativas para esquivar novedades en la vía activas.
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

      // 2. Pedir rutas alternativas a OSRM + novedades viales vigentes en paralelo
      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};$destLng,$destLat'
        '?overview=full&geometries=geojson&alternatives=true',
      );

      final responses = await Future.wait([
        http.get(osrmUri).timeout(const Duration(seconds: 12)),
        _fetchActiveHazards(),
      ]);

      final routeResponse = responses[0] as http.Response;
      final activeHazards = responses[1] as List<_ActiveRoadHazard>;

      if (routeResponse.statusCode != 200) return null;

      final Map routeJson = jsonDecode(routeResponse.body);
      final List routes = routeJson['routes'] ?? [];
      if (routes.isEmpty) return null;

      // 3. Evaluar todas las rutas candidatas y elegir la mejor sin novedades
      int bestIndex = 0;
      double bestScore = double.infinity;
      List<LatLng> bestPoints = [];
      double bestDistMeters = 0;
      double bestDurSeconds = 0;
      List<_ActiveRoadHazard> bestHazards = [];
      bool firstRouteHadHazards = false;

      for (int i = 0; i < routes.length; i++) {
        final r = routes[i] as Map;
        final geometry = r['geometry'] as Map;
        final List coords = geometry['coordinates'] ?? [];

        final List<LatLng> pts = coords.map((c) {
          final pair = c as List;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        }).toList();

        final double distMeters = (r['distance'] as num).toDouble();
        final double durSeconds = (r['duration'] as num).toDouble();
        final matched = _findHazardsOnRoute(pts, activeHazards);

        if (i == 0 && matched.isNotEmpty) {
          firstRouteHadHazards = true;
        }

        final double penalty = matched.fold<double>(
          0.0,
          (acc, h) => acc + h.penaltySeconds,
        );
        final double score = durSeconds + penalty;

        if (score < bestScore) {
          bestScore = score;
          bestIndex = i;
          bestPoints = pts;
          bestDistMeters = distMeters;
          bestDurSeconds = durSeconds;
          bestHazards = matched;
        }
      }

      final bool avoidedIncidents =
          bestIndex > 0 && firstRouteHadHazards && bestHazards.isEmpty;

      return RouteResult(
        points: bestPoints,
        distanceKm: bestDistMeters / 1000.0,
        durationMin: (bestDurSeconds / 60.0).round(),
        destinationName: displayName,
        avoidedIncidents: avoidedIncidents,
        routeWarnings: bestHazards.map((h) => h.label).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
