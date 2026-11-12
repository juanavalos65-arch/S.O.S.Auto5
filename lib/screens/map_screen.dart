import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SosAutoMapScreen extends StatefulWidget {
  const SosAutoMapScreen({Key? key}) : super(key: key);

  @override
  State<SosAutoMapScreen> createState() => _SosAutoMapScreenState();
}

class _SosAutoMapScreenState extends State<SosAutoMapScreen> {
  late GoogleMapController _mapController;

  // Coordenadas iniciales (Simulación en Medellín / Colombia)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.2442, -75.5812),
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA INTERACTIVO DE FONDO
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // 2. CABECERA SUPERIOR CON LOGOTIPO OFICIAL
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icon/icon_sos.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'S.O.S. Auto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. BANNER DINÁMICO INFORMATIVO Y COMERCIAL (Carrusel superior/inferior)
          Positioned(
            top: 105,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900]?.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.campaign, color: Colors.amber, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🚨 Alerta Activa: Vehículo reportado robado (Placa: HXU874) - Verifique la vía.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. LOS 8 BOTONES FLOTANTES PERMANENTES SOBRE EL MAPA
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  icon: Icons.person_add,
                  color: Colors.indigo,
                  label: 'Regístrese',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.monetization_on,
                  color: Colors.purple,
                  label: 'Paute Aquí',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.car_repair,
                  color: Colors.amber[800]!,
                  label: 'Me Varé',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.local_hospital,
                  color: Colors.orange,
                  label: 'Me Accidenté',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.security,
                  color: Colors.red,
                  label: 'En Peligro',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.local_police,
                  color: Colors.blue,
                  label: 'Tránsito',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.warning,
                  color: Colors.deepOrange,
                  label: 'Robo Auto',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.report_problem,
                  color: Colors.grey[700]!,
                  label: 'Novedades',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return FloatingActionButton.small(
      heroTag: label,
      backgroundColor: color,
      onPressed: onTap,
      tooltip: label,
      child: Icon(icon, color: Colors.white),
    );
  }
}
