import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widget/sos_auto_logo.dart';
import '../services/banner_feed_service.dart';
import '../services/emergency_sound_service.dart';
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
import '../services/medical_centers_provider.dart';

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
    List _medicalCenters = [];
  List _mapAllies = [];

  StreamSubscription? _firestoreCamSub;
  StreamSubscription? _positionStreamSub;

  StreamSubscription? _stolenSub;
  StreamSubscription? _accidentsSub;
  StreamSubscription? _sosSub;
  StreamSubscription? _incidentsSub;
  StreamSubscription? _adsSub;
  StreamSubscription? _sponsorsSub;

  List _liveStolenBanners = [];
  List _liveAccidentBanners = [];
  List _liveSosBanners = [];
  List _liveIncidentBanners = [];
  List _liveAdBanners = [];
  List _liveSponsors = [];

  bool _initialIncidentsLoaded = false;
  final Set<String> _announcedIncidentIds = <String>{};
  final Map<String, DateTime> _announcedCameraTimes = <String, DateTime>{};

  RouteResult? _activeRoute;
  bool _searchingRoute = false;

  int _bannerIndex = 0;
  Timer? _bannerTimer;
  bool _locating = false;

  final List _defaultSponsors = [
    {
      'nombre': 'Aliado Disponible',
      'subtitulo': 'Espacio Premium',
      'icon': Icons.local_gas_station,
      'color': const Color(0xFFD32F2F),
      'accent': const Color(0xFFFBC02D),
      'imageUrl': '',
      'isPlaceholder': true,
    },
    {
      'nombre': 'Servicio Automotriz',
      'subtitulo': 'Espacio Premium',
      'icon': Icons.build_circle,
      'color': const Color(0xFF1565C0),
      'accent': const Color(0xFF90CAF9),
      'imageUrl': '',
      'isPlaceholder': true,
    },
    {
      'nombre': 'Llantas y Rines',
      'subtitulo': 'Espacio Premium',
      'icon': Icons.tire_repair,
      'color': const Color(0xFFE65100),
      'accent': const Color(0xFFFFCC80),
      'imageUrl': '',
      'isPlaceholder': true,
    },
    {
      'nombre': 'Grúas y Seguros',
      'subtitulo': 'Espacio Premium',
      'icon': Icons.car_repair,
      'color': const Color(0xFF1B5E20),
      'accent': const Color(0xFFA5D6A7),
      'imageUrl': '',
      'isPlaceholder': true,
    },
  ];

  List _buildBaseBanners() {
    return [
      {
        'id': 'base_1',
        'tag': 'S.O.S. AUTO — ASISTENCIA Y SEGURIDAD VIAL 24/7',
        'title':
            'S.O.S. Auto: tu copiloto de seguridad en todo el continente americano',
        'color': const Color(0xFF0A192F),
        'icon': Icons.shield_outlined,
        'iconColor': const Color(0xFFFBC02D),
        'route': 'register',
      },
      {
        'id': 'base_2',
        'tag': 'ALIADOS PREMIUM — CUPOS DISPONIBLES EN PANTALLA PRINCIPAL',
        'title':
            'Destaca el logo de tu marca, taller o aseguradora en Aliados Premium — Toca en Paute aquí',
        'color': const Color(0xFF1B5E20),
        'icon': Icons.workspace_premium,
        'iconColor': const Color(0xFFFBC02D),
        'route': 'paute',
      },
    ];
  }

  List _getInstantLocalBanners() {
    final rawList = BannerFeedService.bannersNotifier.value as List;
    final List local = [];
    for (final raw in rawList) {
      final m = raw as Map;
      final id = (m['id'] ?? '').toString();
      if (id.startsWith('default_')) continue;
      final cat = (m['category'] ?? 'incident').toString();
      String route = 'incident';
      if (cat == 'stolen') route = 'stolen';
      if (id.startsWith('acc_')) route = 'accident';
      if (id.startsWith('sos_')) route = 'sos';

      local.add({
        'id': id,
        'tag': (m['tag'] ?? 'ALERTA S.O.S. AUTO').toString(),
        'title': (m['title'] ?? '').toString(),
        'color': BannerFeedService.colorForCategory(cat),
        'icon': BannerFeedService.iconForCategory(cat),
        'iconColor': Colors.white,
        'route': route,
      });
    }
    return local;
  }

  List _getCurrentBanners() {
    final Set seen = {};
    final List items = [];

    void addUnique(List source) {
      for (final raw in source) {
        final m = raw as Map;
        final key = (m['id'] ?? m['title']).toString();
        if (seen.add(key)) {
          items.add(m);
        }
      }
    }

    addUnique(_getInstantLocalBanners());
    addUnique(_liveSosBanners);
    addUnique(_liveAccidentBanners);

    final int maxLen = [
      _liveStolenBanners.length,
      _liveIncidentBanners.length,
      _liveAdBanners.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      if (i < _liveStolenBanners.length) addUnique([_liveStolenBanners[i]]);
      if (i < _liveIncidentBanners.length) addUnique([_liveIncidentBanners[i]]);
      if (i < _liveAdBanners.length) addUnique([_liveAdBanners[i]]);
    }

    addUnique(_buildBaseBanners());

    return items;
  }

  void _onInstantBannerChanged() {
    if (!mounted) return;
    setState(() {
      _bannerIndex = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    BannerFeedService.bannersNotifier.addListener(_onInstantBannerChanged);
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

  void _verificarProximidadCamaras(LatLng posicionActual) {
    if (!SpeedCamerasProvider.isAllowedInLocation(posicionActual)) return;

    final List todasLasCamaras = [
      ..._osmCameras,
      ..._firestoreCameras,
    ];
    if (todasLasCamaras.isEmpty) return;

    final DateTime ahora = DateTime.now();

    for (final cam in todasLasCamaras) {
      final double distanciaMetros = Geolocator.distanceBetween(
        posicionActual.latitude,
        posicionActual.longitude,
        cam.lat,
        cam.lng,
      );

      if (distanciaMetros <= 300) {
        final String camKey =
            '${cam.id}_${cam.lat.toStringAsFixed(4)}_${cam.lng.toStringAsFixed(4)}';
        final DateTime? ultimoAviso = _announcedCameraTimes[camKey];

        if (ultimoAviso == null ||
            ahora.difference(ultimoAviso).inSeconds >= 180) {
          _announcedCameraTimes[camKey] = ahora;
          final int metrosRedondeados =
              ((distanciaMetros / 10).round() * 10).clamp(20, 300);
          final String limiteTexto = cam.velocidad > 0
              ? 'Límite ${cam.velocidad} kilómetros por hora.'
              : 'Modere su velocidad.';

          unawaited(
            EmergencySoundService.anunciarNovedadVial(
              'Atención. Cámara de fotodetección a $metrosRedondeados metros. $limiteTexto',
              enfriamientoSegundos: 10,
            ),
          );
          break;
        }
      }
    }
  }

  void _iniciarSeguimientoGpsEnVivo() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(
      (Position pos) {
        if (!mounted) return;
        final nuevoCentro = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentCenter = nuevoCentro;
        });
        _verificarProximidadCamaras(nuevoCentro);
      },
      onError: (_) {},
    );
  }

  void _initFirestoreListenersSafe() {
    try {
      if (Firebase.apps.isEmpty) return;
      final db = FirebaseFirestore.instance;

      _firestoreCamSub = db.collection('camaras').snapshots().listen(
        (snapshot) {
          final List loaded = [];
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
            _verificarProximidadCamaras(_currentCenter);
          }
        },
        onError: (_) {},
      );

      _stolenSub = db
          .collection('vehiculos_robados')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final placa = (raw['placa'] ?? raw['plate'] ?? '').toString();
            final vehiculo = (raw['detalleVehiculo'] ??
                    raw['vehiculo'] ??
                    'Vehículo')
                .toString();
            final ciudad = (raw['ciudad'] ?? '').toString();
            loaded.add({
              'id': doc.id,
              'tag': '🚨 VEHÍCULO ROBADO — ALERTA EN VIVO',
              'title': '$vehiculo ${placa.isNotEmpty ? "• PLACA $placa" : ""}'
                  '${ciudad.isNotEmpty ? " • $ciudad" : ""}',
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

      _accidentsSub = db
          .collection('accidentes')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final placa = (raw['placa'] ?? '').toString();
            final vehiculo = (raw['detalleVehiculo'] ?? 'Vehículo').toString();
            final gravedad = (raw['gravedad'] ?? 'Accidente vial').toString();
            final ciudad = (raw['ciudad'] ?? '').toString();
            loaded.add({
              'id': doc.id,
              'tag':
                  '🚑 ACCIDENTE VIAL — ${ciudad.isNotEmpty ? ciudad : "EN VIVO"}',
              'title':
                  '$gravedad • $vehiculo ${placa.isNotEmpty ? "• PLACA $placa" : ""}',
              'color': const Color(0xFFC62828),
              'icon': Icons.car_crash,
              'iconColor': Colors.white,
              'route': 'accident',
            });
          }
          if (mounted) {
            setState(() {
              _liveAccidentBanners = loaded;
              _bannerIndex = 0;
            });
          }
        },
        onError: (_) {},
      );

      _sosSub = db
          .collection('emergencias_sos')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List loaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final placa = (raw['placa'] ?? '').toString();
            final vehiculo = (raw['vehiculo'] ?? 'Vehículo').toString();
            final amenaza = (raw['amenaza'] ?? 'Persona en peligro').toString();
            final ciudad = (raw['ciudad'] ?? '').toString();
            loaded.add({
              'id': doc.id,
              'tag':
                  '🆘 PERSONA EN PELIGRO — ${ciudad.isNotEmpty ? ciudad : "EN VIVO"}',
              'title':
                  '$amenaza • $vehiculo ${placa.isNotEmpty ? "• PLACA $placa" : ""}',
              'color': const Color(0xFF8E0000),
              'icon': Icons.notifications_active,
              'iconColor': Colors.white,
              'route': 'sos',
            });
          }
          if (mounted) {
            setState(() {
              _liveSosBanners = loaded;
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
          final List loaded = [];
          String? nuevoAnuncioVoz;

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

            if (!_initialIncidentsLoaded) {
              _announcedIncidentIds.add(doc.id);
            } else if (_announcedIncidentIds.add(doc.id) &&
                nuevoAnuncioVoz == null) {
              bool estaCerca = true;
              final double? incLat = (raw['lat'] is num)
                  ? (raw['lat'] as num).toDouble()
                  : null;
              final double? incLng = (raw['lng'] is num)
                  ? (raw['lng'] as num).toDouble()
                  : null;
              if (incLat != null && incLng != null) {
                final double dist = Geolocator.distanceBetween(
                  _currentCenter.latitude,
                  _currentCenter.longitude,
                  incLat,
                  incLng,
                );
                estaCerca = dist <= 5000;
              }

              if (estaCerca) {
                nuevoAnuncioVoz = [
                  'Atención conductor. Novedad en la vía: $tipo',
                  if (estadoPaso.isNotEmpty) estadoPaso,
                  if (sector.isNotEmpty) 'en $sector',
                ].join('. ');
              }
            }

            final List partes = [tipo];
            if (sector.isNotEmpty) partes.add(sector);
            if (estadoPaso.isNotEmpty) partes.add(estadoPaso);

            loaded.add({
              'id': 'novedad_${doc.id}',
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

          _initialIncidentsLoaded = true;

          if (nuevoAnuncioVoz != null) {
            unawaited(
              EmergencySoundService.anunciarNovedadVial(
                '$nuevoAnuncioVoz.',
                enfriamientoSegundos: 15,
              ),
            );
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
          final List loaded = [];
          final List sponsorsLoaded = [];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            final nombre = raw['negocio']?.toString() ?? 'Aliado S.O.S. Auto';
            final servicio = raw['servicio']?.toString() ?? 'Asistencia 24/7';
            final logoUrl = (raw['logoUrl'] ?? raw['imagenUrl'] ?? '').toString();
            loaded.add({
              'id': 'ad_${doc.id}',
              'tag': 'ALIADO PREMIUM — PAUTE AQUÍ',
              'title': '$nombre — $servicio',
              'color': const Color(0xFF1B5E20),
              'icon': Icons.storefront,
              'iconColor': const Color(0xFFFBC02D),
              'route': 'allies',
            });
            sponsorsLoaded.add({
              'nombre': nombre,
              'subtitulo': servicio,
              'icon': Icons.verified,
              'color': const Color(0xFF1B5E20),
              'accent': const Color(0xFFFBC02D),
              'imageUrl': logoUrl,
              'isPlaceholder': false,
            });
          }
          if (mounted) {
            setState(() {
              _liveAdBanners = loaded;
              _liveSponsors = sponsorsLoaded;
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
          _verificarProximidadCamaras(newCenter);
          _iniciarSeguimientoGpsEnVivo();
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
    BannerFeedService.bannersNotifier.removeListener(_onInstantBannerChanged);
    _bannerTimer?.cancel();
    _positionStreamSub?.cancel();
    _firestoreCamSub?.cancel();
    _stolenSub?.cancel();
    _accidentsSub?.cancel();
    _sosSub?.cancel();
    _incidentsSub?.cancel();
    _adsSub?.cancel();
    _sponsorsSub?.cancel();
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
        setState(() {
          _bannerIndex = 0;
        });
      }
    });
  }

  void _handleBannerTap(String route) {
    switch (route) {
      case 'stolen':
        _openScreen(const StolenCarScreen());
        break;
      case 'accident':
        _openScreen(const AccidenteScreen());
        break;
      case 'sos':
        _openScreen(const EmergencySOSScreen());
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
      return [];
    }
    return [
      ..._osmCameras.map<Marker>(_createCameraMarker),
      ..._firestoreCameras.map<Marker>(_createCameraMarker),
    ];
  }

  Widget _buildSponsorsStrip() {
    final List sponsors =
        _liveSponsors.isNotEmpty ? _liveSponsors : _defaultSponsors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Color(0xFFD97706),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Aliados Premium',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A192F),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sponsors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = sponsors[index] as Map;
              final bool isPlaceholder = item['isPlaceholder'] == true;
              final String imageUrl = (item['imageUrl'] ?? '').toString();
              final Color mainColor =
                  (item['color'] as Color?) ?? const Color(0xFF0A192F);

              return InkWell(
                onTap: () => _openScreen(
                  isPlaceholder
                      ? const PauteAquiScreen()
                      : const AlliesScreen(),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 86,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Expanded(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              item['icon'] as IconData,
                              color: mainColor,
                              size: 24,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: mainColor,
                            size: 19,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        (item['nombre'] ?? 'Aliado').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBanners = _getCurrentBanners();
    final safeIndex = _bannerIndex % currentBanners.length;
    final activeBanner = currentBanners[safeIndex] as Map;
    final List<Marker> camMarkers = _buildAllCameraMarkers();
    final List<LatLng> routePoints = _activeRoute?.points ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        toolbarHeight: 50,
        titleSpacing: 10,
        title: Row(
          children: [
            const SosAutoLogo(size: 38, showTextInside: false),
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
            icon:
                const Icon(Icons.person_add, color: Color(0xFFFFC107), size: 17),
            label: const Text(
              'Registro',
              style: TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Column(
            children: [
              // 1. Aliados Premium en cabecera
              _buildSponsorsStrip(),
              const SizedBox(height: 6),

              // 2. Banner dinámico ampliado sin contador
              InkWell(
                onTap: () => _handleBannerTap(activeBanner['route'] as String),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: activeBanner['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activeBanner['icon'] as IconData,
                        color: (activeBanner['iconColor'] as Color?) ??
                            const Color(0xFFFBC02D),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeBanner['tag'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _MarqueeBannerText(
                              key: ValueKey(
                                  'banner_${safeIndex}_${activeBanner['title']}'),
                              text: activeBanner['title'] as String,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 3. Buscador de ruta
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
                        icon: const Icon(Icons.close,
                            size: 17, color: Colors.black54),
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

              // 4. Mapa interactivo centrado
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
                              : const Icon(Icons.gps_fixed,
                                  color: Color(0xFF0D1B2A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_activeRoute != null) ...[
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route,
                          color: Color(0xFFFBC02D), size: 16),
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
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // 5. Los 8 botones exactos (Aliados y Paute aquí en la primera fila)
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 3.55,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionButton(
                    'Aliados',
                    Icons.apps_rounded,
                    const Color(0xFF1B4965),
                    () => _openScreen(const AlliesScreen()),
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

class _MarqueeBannerText extends StatefulWidget {
  final String text;
  const _MarqueeBannerText({super.key, required this.text});

  @override
  State<_MarqueeBannerText> createState() => _MarqueeBannerTextState();
}

class _MarqueeBannerTextState extends State<_MarqueeBannerText> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final next = _scrollController.offset + 1.5;
      if (next >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${widget.text}        •        ${widget.text}        ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
