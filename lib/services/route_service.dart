import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteStep {
  final LatLng location;
  final String instruction;
  final String streetName;
  final double distanceMeters;

  const RouteStep({
    required this.location,
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
  });
}

class RouteResult {
  final List<LatLng> points;
  final List<RouteStep> steps;
  final double distanceKm;
  final int durationMin;
  final String destinationName;
  final bool avoidedIncidents;
  final List<String> routeWarnings;

  const RouteResult({
    required this.points,
    this.steps = const [],
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
      return 7200;
    }
    if (texto.contains('accidente') ||
        texto.contains('inundación') ||
        texto.contains('árbol caído')) {
      return 2700;
    }
    if (texto.contains('restringido') ||
        texto.contains('congestión') ||
        texto.contains('tráfico lento')) {
      return 1500;
    }
    return 600;
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

  static String _traducirManiobra(
    String type,
    String modifier,
    String streetName,
    int? exitNumber,
  ) {
    final String calle = streetName.trim();
    final String haciaCalle = calle.isNotEmpty ? ' hacia $calle' : '';
    final String porCalle = calle.isNotEmpty ? ' por $calle' : '';

    if (type == 'arrive') return 'Ha llegado a su destino.';
    if (type == 'depart') {
      return calle.isNotEmpty
          ? 'Inicie el recorrido por $calle.'
          : 'Inicie el recorrido siguiendo la ruta.';
    }
    if (type == 'roundabout' || type == 'rotary') {
      final String salida = exitNumber != null && exitNumber > 0
          ? 'tome la salida $exitNumber'
          : 'tome la salida';
      return 'En la glorieta, $salida$haciaCalle.';
    }
    if (type == 'off ramp' || type == 'exit roundabout') {
      return 'Tome la salida$haciaCalle.';
    }
    if (type == 'on ramp' || type == 'merge') {
      return 'Incorpórese a la vía$haciaCalle.';
    }
    if (type == 'fork') {
      if (modifier.contains('left')) {
        return 'En la bifurcación, manténgase a la izquierda$haciaCalle.';
      }
      if (modifier.contains('right')) {
        return 'En la bifurcación, manténgase a la derecha$haciaCalle.';
      }
      return 'En la bifurcación, continúe$haciaCalle.';
    }
    if (modifier == 'uturn') return 'Haga retorno en U$haciaCalle.';
    if (modifier == 'sharp left') return 'Gire cerrado a la izquierda$haciaCalle.';
    if (modifier == 'left') return 'Gire a la izquierda$haciaCalle.';
    if (modifier == 'slight left') return 'Gire levemente a la izquierda$haciaCalle.';
    if (modifier == 'sharp right') return 'Gire cerrado a la derecha$haciaCalle.';
    if (modifier == 'right') return 'Gire a la derecha$haciaCalle.';
    if (modifier == 'slight right') return 'Gire levemente a la derecha$haciaCalle.';

    return 'Continúe recto$porCalle.';
  }

  static List<RouteStep> _parseSteps(Map routeMap) {
    final List<RouteStep> stepsList = [];
    final List legs = routeMap['legs'] ?? [];
    for (final legRaw in legs) {
      final leg = legRaw as Map;
      final List steps = leg['steps'] ?? [];
      for (final stepRaw in steps) {
        final step = stepRaw as Map;
        final maneuver = (step['maneuver'] as Map?) ?? {};
        final List loc = maneuver['location'] ?? [];
        if (loc.length < 2) continue;

        final double lng = (loc[0] as num).toDouble();
        final double lat = (loc[1] as num).toDouble();
        final String type = (maneuver['type'] ?? '').toString();
        final String modifier = (maneuver['modifier'] ?? '').toString();
        final int? exitNum = (maneuver['exit'] is num)
            ? (maneuver['exit'] as num).toInt()
            : null;
        final String streetName = (step['name'] ?? '').toString();
        final double dist = (step['distance'] is num)
            ? (step['distance'] as num).toDouble()
            : 0.0;

        stepsList.add(
          RouteStep(
            location: LatLng(lat, lng),
            instruction: _traducirManiobra(type, modifier, streetName, exitNum),
            streetName: streetName,
            distanceMeters: dist,
          ),
        );
      }
    }
    return stepsList;
  }

  /// Calcula la mejor ruta directamente a coordenadas conocidas (ideal al tocar clínicas o aliados).
  static Future<RouteResult?> routeToCoordinates(
    LatLng origin,
    LatLng destination,
    String destinationName,
  ) async {
    try {
      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&alternatives=true&steps=true',
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

      int bestIndex = 0;
      double bestScore = double.infinity;
      List<LatLng> bestPoints = [];
      List<RouteStep> bestSteps = [];
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
          bestSteps = _parseSteps(r);
          bestDistMeters = distMeters;
          bestDurSeconds = durSeconds;
          bestHazards = matched;
        }
      }

      final bool avoidedIncidents =
          bestIndex > 0 && firstRouteHadHazards && bestHazards.isEmpty;

      return RouteResult(
        points: bestPoints,
        steps: bestSteps,
        distanceKm: bestDistMeters / 1000.0,
        durationMin: (bestDurSeconds / 60.0).round(),
        destinationName: destinationName,
        avoidedIncidents: avoidedIncidents,
        routeWarnings: bestHazards.map((h) => h.label).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Busca una dirección, clínica o comercio priorizando la ciudad/zona actual del usuario.
  static Future<RouteResult?> searchAndRoute(
    LatLng origin,
    String destinationQuery,
  ) async {
    final cleanQuery = destinationQuery.trim();
    if (cleanQuery.isEmpty) return null;

    try {
      // Cuadro de ~35 km alrededor del GPS actual para priorizar sitios locales
      const double delta = 0.32;
      final String viewbox =
          '${origin.longitude - delta},${origin.latitude + delta},'
          '${origin.longitude + delta},${origin.latitude - delta}';

      List places = [];

      // Intento 1: búsqueda priorizada en la zona actual
      final localUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(cleanQuery)}&format=json&limit=5&viewbox=$viewbox',
      );
      final localRes = await http.get(
        localUri,
        headers: {'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)'},
      ).timeout(const Duration(seconds: 8));

      if (localRes.statusCode == 200) {
        places = jsonDecode(localRes.body);
      }

      // Intento 2: si escribió barrio/referencia extra (ej. "eps virrey solis la ford"),
      // probar con las primeras 3 palabras clave
      if (places.isEmpty) {
        final palabras = cleanQuery.split(RegExp(r'\s+'));
        if (palabras.length > 3) {
          final shortQuery = palabras.take(3).join(' ');
          final fallbackUri = Uri.parse(
            'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(shortQuery)}&format=json&limit=5&viewbox=$viewbox',
          );
          final fallbackRes = await http.get(
            fallbackUri,
            headers: {
              'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)'
            },
          ).timeout(const Duration(seconds: 8));
          if (fallbackRes.statusCode == 200) {
            places = jsonDecode(fallbackRes.body);
          }
        }
      }

      if (places.isEmpty) return null;

      // Elegir el resultado más cercano a la ubicación actual
      Map? closestPlace;
      double minDistance = double.infinity;

      for (final p in places) {
        final m = p as Map;
        final double lat = double.parse(m['lat'].toString());
        final double lng = double.parse(m['lon'].toString());
        final double d = Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          lat,
          lng,
        );
        if (d < minDistance) {
          minDistance = d;
          closestPlace = m;
        }
      }

      if (closestPlace == null) return null;

      final double destLat = double.parse(closestPlace['lat'].toString());
      final double destLng = double.parse(closestPlace['lon'].toString());
      final String displayName =
          closestPlace['display_name']?.toString().split(',').first ??
              cleanQuery;

      return routeToCoordinates(
        origin,
        LatLng(destLat, destLng),
        displayName,
      );
    } catch (_) {
      return null;
    }
  }
}
