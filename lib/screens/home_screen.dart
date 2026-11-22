import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widget/sos_auto_logo.dart';
import '../services/speed_cameras_provider.dart';
import '../services/route_service.dart';
import 'camera_background_service.dart';
import 'register_vehicle_screen.dart';
import 'paute_aqui_screen.dart';
import 'me_vare_screen.dart';
import 'accidente_screen.dart';
import 'emergency_sos_screen.dart';
import 'stolen_car_screen.dart';
import 'report_incident_screen.dart';
import 'traffic_stop_screen.dart';
import 'allies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _destController = TextEditingController();

  LatLng _currentCenter = const LatLng(6.2442, -75.5812);
  List _osmCameras = [];
  List _firestoreCameras = [];
  StreamSubscription? _firestoreCamSub;

  RouteResult? _activeRoute;
  bool _searchingRoute = false;

  int _bannerIndex = 0;
  Timer? _bannerTimer;
  bool _locating = false;

  final _banners = [
    {
      'tag': 'VEHÍCULO ROBADO — ALERTA',
      'title': 'Mazda 3 Gris — Reportado en Medellín',
      'color': const Color(0xFFB71C1C),
      'icon': Icons.warning_amber_rounded,
      'route': 'stolen',
    },
    {
      'tag': 'NOVEDAD EN LA VÍA',
      'title': 'Paso restringido por obra — Av. Regional',
      'color': const Color(0xFFE65100),
      'icon': Icons.traffic,
      'route': 'incident',
    },
    {
      'tag': 'ALIADO DESTACADO — PAUTE AQUÍ',
      'title': 'Grúas y Talleres 24/7 — Asistencia inmediata',
      'color': const Color(0xFF1B5E20),
      'icon': Icons.storefront,
      'route': 'paute',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initFirestoreCamerasSafe();
    _initLocation();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _banners.length;
        });
      }
    });
  }

  void _initFirestoreCamerasSafe() {
    try {
      if (Firebase.apps.isEmpty) return;
      _firestoreCamSub = FirebaseFirestore.instance
          .collection('camaras')
          .snapshots()
          .listen(
        (snapshot) {
          final loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final double lat = (raw['lat'] ?? 0).toDouble();
            final double lng = (raw['lng'] ?? 0).toDouble();
            if (lat == 0 && lng == 0) continue;
            loaded.add(
              SpeedCameraPoint(
                id: doc.id,
                lat: lat,
                lng: lng,
                velocidad: (raw['velocidad'] is num)
                    ? (raw['velocidad'] as num).toInt()
                    : 0,
                unidad: raw['unidad']?.toString() ?? 'km/h',
                descripcion: raw['descripcion']?.toString() ??
                    'Zona de control de velocidad',
              ),
            );
          }
          if (mounted) {
            setState(() {
              _firestoreCameras = loaded;
            });
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  Future<void> _initLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        try {
          await initializeBackgroundService();
        } catch (_) {}

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final newCenter = LatLng(pos.latitude, pos.longitude);
        final cams = await SpeedCamerasProvider.getCamerasAround(newCenter);

        if (mounted) {
          setState(() {
            _currentCenter = newCenter;
            _osmCameras = cams;
          });
          _mapController.move(_currentCenter, 15.0);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _calculateRoute() async {
    final query = _destController.text.trim();
    if (query.isEmpty || _searchingRoute) return;

    FocusScope.of(context).unfocus();
    setState(() => _searchingRoute = true);

    final result = await RouteService.searchAndRoute(_currentCenter, query);

    if (!mounted) return;
    setState(() => _searchingRoute = false);

    if (result == null || result.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró la ruta. Intenta con ciudad o dirección más específica.',
          ),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() {
      _activeRoute = result;
    });

    try {
      setRutaActual(result.points);
    } catch (_) {}

    final bounds = LatLngBounds.fromPoints(result.points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _activeRoute = null;
      _destController.clear();
    });
    try {
      setRutaActual([]);
    } catch (_) {}
    _mapController.move(_currentCenter, 15.0);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _firestoreCamSub?.cancel();
    _destController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _handleBannerTap(String route) {
    switch (route) {
      case 'stolen':
        _openScreen(const StolenCarScreen());
        break;
      case 'incident':
        _openScreen(const ReportIncidentScreen());
        break;
      case 'paute':
        _openScreen(const PauteAquiScreen());
        break;
    }
  }

  Marker _createCameraMarker(dynamic cam) {
    return Marker(
      point: LatLng(cam.lat, cam.lng),
      width: 40,
      height: 40,
      child: Tooltip(
        message: cam.velocidad > 0
            ? 'Control velocidad ${cam.velocidad} ${cam.unidad}'
            : cam.descripcion,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  List<Marker> _buildAllCameraMarkers() {
    if (!SpeedCamerasProvider.isAllowedInLocation(_currentCenter)) {
      return [];
    }
    return [
      ..._osmCameras.map(_createCameraMarker),
      ..._firestoreCameras.map(_createCameraMarker),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeBanner = _banners[_bannerIndex];
    final camMarkers = _buildAllCameraMarkers();
    final routePoints = _activeRoute?.points ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        toolbarHeight: 52,
        titleSpacing: 10,
        title: Row(
          children: [
            const SosAutoLogo(size: 40, showTextInside: false),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'S.O.S. ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'AUTO',
                          style: TextStyle(color: Color(0xFFFBC02D)),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Asistencia y Seguridad Vial 24/7',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openScreen(const RegisterVehicleScreen()),
            icon: const Icon(Icons.person_add, color: Color(0xFFFFC107), size: 17),
            label: const Text(
              'Registro',
              style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: Column(
            children: [
              // 1. Banner superior dinámico compacto
              InkWell(
                onTap: () => _handleBannerTap(activeBanner['route'] as String),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeBanner['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activeBanner['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeBanner['tag'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              activeBanner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 2. Barra de búsqueda de ruta FUERA del mapa
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.directions,
                      color: Color(0xFF1565C0),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _destController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _calculateRoute(),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: '¿A dónde vas? Buscar ruta...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_activeRoute != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 17, color: Colors.black54),
                        onPressed: _clearRoute,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30),
                      ),
                    IconButton(
                      icon: _searchingRoute
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.search,
                              color: Color(0xFF0A192F),
                              size: 19,
                            ),
                      onPressed: _searchingRoute ? null : _calculateRoute,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 3. Mapa 100% libre (solo lleva el botón GPS en la esquina)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentCenter,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'ge.sosauto.app',
                          ),
                          if (routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 5.0,
                                  color: const Color(0xFF1565C0),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              ...camMarkers,
                              Marker(
                                point: _currentCenter,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF0D47A1),
                                  size: 30,
                                ),
                              ),
                              if (routePoints.isNotEmpty)
                                Marker(
                                  point: routePoints.last,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.flag_circle,
                                    color: Color(0xFF2E7D32),
                                    size: 32,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Botón GPS (círculo blanco con mira) para volver a tu ubicación
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'gps_recenter_btn',
                          backgroundColor: Colors.white,
                          onPressed: _locating ? null : _initLocation,
                          child: _locating
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                )
                              : const Icon(Icons.gps_fixed, color: Color(0xFF0D1B2A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Barra de distancia y tiempo FUERA del mapa (no choca con GPS)
              if (_activeRoute != null) ...[
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: Color(0xFFFBC02D), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_activeRoute!.destinationName} · '
                          '${_activeRoute!.distanceKm.toStringAsFixed(1)} km · '
                          '${_activeRoute!.durationMin} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearRoute,
                        child: const Icon(Icons.close, color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // 5. Cuadrícula compacta de los 8 botones más abajo
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 3.45,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionButton(
                    'Registro',
                    Icons.app_registration,
                    const Color(0xFF1B4965),
                    () => _openScreen(const RegisterVehicleScreen()),
                  ),
                  _buildActionButton(
                    'Paute aquí',
                    Icons.campaign,
                    const Color(0xFF2E7D32),
                    () => _openScreen(const PauteAquiScreen()),
                  ),
                  _buildActionButton(
                    'Me varé',
                    Icons.car_repair,
                    const Color(0xFFEF6C00),
                    () => _openScreen(const MeVareScreen()),
                  ),
                  _buildActionButton(
                    'Accidente',
                    Icons.car_crash,
                    const Color(0xFFC62828),
                    () => _openScreen(const AccidenteScreen()),
                  ),
                  _buildActionButton(
                    'Estoy en peligro',
                    Icons.sos,
                    const Color(0xFF8E0000),
                    () => _openScreen(const EmergencySOSScreen()),
                  ),
                  _buildActionButton(
                    'Robo de auto',
                    Icons.no_crash,
                    const Color(0xFF4A148C),
                    () => _openScreen(const StolenCarScreen()),
                  ),
                  _buildActionButton(
                    'Novedades en vía',
                    Icons.traffic,
                    const Color(0xFFF57C00),
                    () => _openScreen(const ReportIncidentScreen()),
                  ),
                  _buildActionButton(
                    'Agente tránsito',
                    Icons.local_police,
                    const Color(0xFF283593),
                    () => _openScreen(const TrafficStopScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // 6. Botón verde inferior conectado a allies_screen.dart
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openScreen(const AlliesScreen()),
              icon: const Icon(Icons.storefront, color: Colors.white, size: 19),
              label: const Text(
                'Aliados — Directorio de Asistencia y Servicios',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
