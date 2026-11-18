import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng _currentCenter = const LatLng(6.2442, -75.5812);
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List _banners = [
    {
      'tag': 'VEHÍCULO ROBADO — ALERTA',
      'title': 'Mazda 3 Gris — Reportado en Medellín',
      'color': const Color(0xFFB71C1C),
      'icon': Icons.warning_amber_rounded,
    },
    {
      'tag': 'NOVEDAD EN LA VÍA',
      'title': 'Paso restringido por obra — Av. Regional',
      'color': const Color(0xFFE65100),
      'icon': Icons.traffic,
    },
    {
      'tag': 'ALIADO DESTACADO — PAUTE AQUÍ',
      'title': 'Grúas y Talleres 24/7 — Asistencia inmediata',
      'color': const Color(0xFF1B5E20),
      'icon': Icons.storefront,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _banners.length;
        });
      }
    });
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentCenter = LatLng(pos.latitude, pos.longitude);
          });
          _mapController.move(_currentCenter, 15.0);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBanner = _banners[_bannerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.car_crash, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'S.O.S. AUTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Asistencia y Seguridad Vial 24/7',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
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
            icon: const Icon(Icons.person_add, color: Color(0xFFFFC107), size: 18),
            label: const Text(
              'Registro',
              style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            children: [
              // Banner superior dinámico
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: activeBanner['color'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(activeBanner['icon'] as IconData, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeBanner['tag'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activeBanner['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Mapa libre OpenStreetMap
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentCenter,
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'ge.sosauto.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentCenter,
                                width: 42,
                                height: 42,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Color(0xFFD32F2F),
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
                          backgroundColor: Colors.white,
                          onPressed: _initLocation,
                          child: const Icon(Icons.gps_fixed, color: Color(0xFF0D1B2A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Cuadrícula de 8 botones conectados a tus archivos reales
              Expanded(
                flex: 5,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.75,
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
                      () => _openScreen(const AgrnteTransitoScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Botón verde inferior conectado a tu archivo allies_screen.dart
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openScreen(const AlliesScreen()),
              icon: const Icon(Icons.storefront),
              label: const Text(
                'Aliados — Directorio de Asistencia y Servicios',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
