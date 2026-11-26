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
import '../services/medical_centers_provider.dart';
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
  int _currentStepIndex = 0;
  String _currentNavInstruction = '';
  final Set<String> _spokenNavMarkers = <String>{};

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

  void _actualizarNavegacionGiroAGiro(LatLng posicionActual) {
    final route = _activeRoute;
    if
