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
  List<dynamic> _osmCameras = [];
  List<dynamic> _firestoreCameras = [];
  StreamSubscription? _firestoreCamSub;

  StreamSubscription? _stolenSub;
  StreamSubscription? _incidentsSub;
  StreamSubscription? _adsSub;

  List> _liveStolenBanners = [];
  List> _liveIncidentBanners = [];
  List> _liveAdBanners = [];

  RouteResult? _activeRoute;
  bool _searchingRoute = false;

  int _bannerIndex = 0;
  Timer? _bannerTimer;
  bool _locating = false;

  List> _buildBaseBanners() {
    return [
      {
        'tag': 'S.O.S. AUTO — ASISTENCIA Y SEGURIDAD VIAL 24/7',
        'title':
            'S.O.S. Auto: tu copiloto de seguridad en todo el continente americano',
        'color': const Color(0xFF0A192F),
        'icon': Icons.shield_outlined,
        'iconColor': const Color(0xFFFBC02D),
        'route': 'register',
      },
      {
        'tag': 'PAUTE AQUÍ — ESPACIO COMERCIAL DISPONIBLE',
        'title':
            'Paute aquí — Anuncia tu taller, grúa o negocio automotriz 24/7 en S.O.S. Auto',
        'color': const Color(0xFF1B5E20),
        'icon': Icons.campaign,
        'iconColor': const Color(0xFFFBC02D),
        'route': 'paute',
      },
    ];
  }

  List> _getCurrentBanners() {
    final List> items = _buildBaseBanners();

    final int maxLen = [
      _liveAdBanners.length,
      _liveStolenBanners.length,
      _liveIncidentBanners.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      if (i < _liveAdBanners.length) {
        items.add(_liveAdBanners[i]);
      }
      if (i < _liveStolenBanners.length) {
        items.add(_liveStolenBanners[i]);
      }
      if (i < _liveIncidentBanners.length) {
        items.add(_liveIncidentBanners[i]);
      }
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    _initFirestoreListenersSafe();
    _initLocation();
    _bannerTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final total = _getCurrentBanners().length;
      if (total == 0) return;
      setState(() {
        _bannerIndex = (_bannerIndex + 1) % total;
      });
    });
  }

  void _initFirestoreListenersSafe() {
    try {
      if (Firebase.apps.isEmpty) return;
      final db = FirebaseFirestore.instance;

      _firestoreCamSub = db.collection('camaras').snapshots().listen(
        (snapshot) {
          final List<dynamic> loaded = [];
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
            setState(() => _firestoreCameras = loaded);
          }
        },
        onError: (_) {},
      );

      _stolenSub = db
          .collection('vehiculos_robados')
          .where('activo', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List> loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final placa = raw['placa']?.toString() ?? '';
            final vehiculo = raw['vehiculo']?.toString() ?? 'Vehículo';
            final ciudad = raw['ciudad']?.toString() ?? '';
            loaded.add({
              'tag': 'VEHÍCULO ROBADO — ALERTA EN VIVO',
              'title': '$vehiculo ${placa.isNotEmpty ? "($placa)" : ""}'
                  '${ciudad.isNotEmpty ? " — Reportado en $ciudad" : ""}',
              'color': const Color(0xFFB71C1C),
              'icon': Icons.warning_amber_rounded,
              'iconColor': Colors.white,
              'route': 'stolen',
            });
          }
          if (mounted) {
            setState(() {
              _liveStolenBanners = loaded;
              _bannerIndex = 0;
            });
          }
        },
        onError: (_) {},
      );

      _incidentsSub = db
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(20)
          .snapshots()
          .listen(
        (snapshot) {
          final ahora = DateTime.now();
          final List> loaded = [];

          for (final doc in snapshot.docs) {
            final raw = doc.data();
            if (raw['activo'] == false) continue;

            final bool esPermanente = raw['esPermanente'] == true;
            if (!esPermanente) {
              final Timestamp? expiraTs = raw['expiraEn'] as Timestamp?;
              if (expiraTs != null && expiraTs.toDate().isBefore(ahora)) {
                continue;
              }
            }

            final tipo = raw['tipo']?.toString() ?? 'Novedad en la vía';
            final sector = raw['sector']?.toString() ?? '';
            final estadoPaso = raw['estadoPaso']?.toString() ?? '';

            final partes = <String>[tipo];
            if (sector.isNotEmpty) partes.add(sector);
            if (estadoPaso.isNotEmpty) partes.add(estadoPaso);

            loaded.add({
              'tag': esPermanente
                  ? 'PUNTO DE CONTROL / FOTODETECCIÓN'
                  : 'NOVEDAD EN LA VÍA — EN VIVO',
              'title': partes.join(' · '),
              'color': esPermanente
                  ? const Color(0xFFC62828)
                  : const Color(0xFFE65100),
              'icon': esPermanente ? Icons.speed : Icons.traffic,
              'iconColor': Colors.white,
              'route': 'incident',
            });
          }

          if (mounted) {
            setState(() {
              _liveIncidentBanners = loaded;
              _bannerIndex = 0;
            });
          }
        },
        onError: (_) {},
      );

      _adsSub = db
          .collection('pautas_activas')
          .where('activo', isEqualTo: true)
          .where('pagoVerificado', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List> loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final nombre = raw['negocio']?.toString() ?? 'Aliado S.O.S. Auto';
            final servicio = raw['servicio']?.toString() ?? 'Asistencia 24/7';
            loaded.add({
              'tag': 'ALIADO DESTACADO — PAUTE AQUÍ',
              'title': '$nombre — $servicio',
              'color': const Color(0xFF1B5E20),
              'icon': Icons.storefront,
              'iconColor': const Color(0xFFFBC02D),
              'route': 'allies',
            });
          }
          if (mounted) {
            setState(() {
              _liveAdBanners = loaded;
              _bannerIndex = 0;
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
    _stolenSub?.cancel();
    _incidentsSub?.cancel();
    _adsSub?.cancel();
    _destController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleBannerTap(String route) {
    switch (route) {
      case 'stolen':
        _openScreen(const StolenCarScreen());
        break;
      case 'incident':
        _openScreen(const ReportIncidentScreen());
        break;
      case 'allies':
        _openScreen(const AlliesScreen());
        break;
      case 'paute':
        _openScreen(const PauteAquiScreen());
        break;
      case 'register':
      default:
        _openScreen(const RegisterVehicleScreen());
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
      return <Marker>[];
    }
    return <Marker>[
      ..._osmCameras.map<Marker>(_createCameraMarker),
      ..._firestoreCameras.map<Marker>(_createCameraMarker),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentBanners = _getCurrentBanners();
    final safeIndex = _bannerIndex % currentBanners.length;
    final activeBanner = currentBanners[safeIndex];
    final List<Marker> camMarkers = _buildAllCameraMarkers();
    final List<LatLng> routePoints = _activeRoute?.points ?? <LatLng>[];

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
                    'Tu copiloto de seguridad en América',
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
                        color: (activeBanner['iconColor'] as Color?) ??
                            const Color(0xFFFBC02D),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            _MarqueeBannerText(
                              key: ValueKey('banner_$safeIndex'),
                              text: activeBanner['title'] as String,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${safeIndex + 1}/${currentBanners.length}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                              
