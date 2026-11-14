import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'register_vehicle_screen.dart';
import 'allies_screen.dart';
import 'emergency_sos_screen.dart';
import 'report_incident_screen.dart';
import 'traffic_stop_screen.dart';
import 'stolen_car_screen.dart';
import 'banner_dinamico.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(6.2442, -75.5812); // Medellín / Colombia

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // 1. MAPA INTERACTIVO DE FONDO
          // ==========================================
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 14.0,
              ),
              myLocationEnabled: false, // Evita crash nativo antes de pedir permiso GPS
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          // ==========================================
          // 2. CABECERA INSTITUCIONAL: LOGOTIPO OFICIAL (Botón superior)
          // ==========================================
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _navigateTo(const BannerDinamico()),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, color: Colors.redAccent, size: 26),
                        SizedBox(width: 8),
                        Text(
                          'S.O.S. Auto',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ==========================================
                // 3. BANNER DINÁMICO (Botón interactivo / Carrusel)
                // ==========================================
                InkWell(
                  onTap: () => _navigateTo(const AlliesScreen()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ S.O.S. Auto - Red Vial Activa (Toque para ver aliados)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 4. PARRILLA INFERIOR CON LOS 8 BOTONES PRINCIPALES (4x2)
          // ==========================================
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6.0,
                crossAxisSpacing: 6.0,
                childAspectRatio: 0.95,
                children: [
                  _buildButton('Regístrese', Icons.person_add, Colors.blue, () => _navigateTo(const RegisterVehicleScreen())),
                  _buildButton('Paute Aquí', Icons.campaign, Colors.amber, () => _navigateTo(const AlliesScreen())),
                  _buildButton('Me Varé', Icons.car_repair, Colors.orange, () => _navigateTo(const EmergencySosScreen())),
                  _buildButton('Accidente', Icons.car_crash, Colors.red, () => _navigateTo(const ReportIncidentScreen())),
                  _buildButton('Peligro', Icons.warning, Colors.deepOrange, () => _navigateTo(const EmergencySosScreen())),
                  _buildButton('Tránsito', Icons.local_police, Colors.indigo, () => _navigateTo(const TrafficStopScreen())),
                  _buildButton('Robo Auto', Icons.local_shipping, Colors.redAccent, () => _navigateTo(const StolenCarScreen())),
                  _buildButton('Novedades', Icons.announcement, Colors.teal, () => _navigateTo(const BannerDinamico())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
