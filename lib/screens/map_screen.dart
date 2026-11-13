import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Asegúrate de importar tu banner dinámico si está en otro archivo:
// import 'banner_dinamico.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  
  // Coordenadas iniciales (ej. Medellín / Colombia)
  static const LatLng _initialPosition = LatLng(6.2442, -75.5812);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA INTERACTIVO DE FONDO
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 2. CABECERA CON LOGOTIPO OFICIAL Y BANNER DINÁMICO (Superior)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Logotipo Institucional y Nombre de la App
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, color: Colors.redAccent, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'S.O.S. Auto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Banner Dinámico Informativo / Comercial / Alertas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ S.O.S. Auto - Red Vial Activa (Precaución en vía)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. PARRILLA INFERIOR CON LOS 8 BOTONES FLOTANTES
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.count(
                crossAxisCount: 4, // 4 columnas x 2 filas = 8 botones visibles sin scroll
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6.0,
                crossAxisSpacing: 6.0,
                childAspectRatio: 1.0,
                children: [
                  _buildEmergencyButton(
                    icon: Icons.person_add,
                    label: 'Regístrese',
                    color: Colors.blue,
                    onTap: () => _handleAction('register'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.campaign,
                    label: 'Paute Aquí',
                    color: Colors.amber,
                    onTap: () => _handleAction('paute_ aqui'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.car_repair,
                    label: 'Me Varé',
                    color: Colors.orange,
                    onTap: () => _handleAction('me_vare'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.car_crash,
                    label: 'Accidente',
                    color: Colors.red,
                    onTap: () => _handleAction('accident'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.warning,
                    label: 'Peligro',
                    color: Colors.deepOrange,
                    onTap: () => _handleAction('danger'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.local_police,
                    label: 'Tránsito',
                    color: Colors.indigo,
                    onTap: () => _handleAction('traffic_stop'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.local_shipping,
                    label: 'Robo Auto',
                    color: Colors.redAccent,
                    onTap: () => _handleAction('stolen_car'),
                  ),
                  _buildEmergencyButton(
                    icon: Icons.announcement,
                    label: 'Novedades',
                    color: Colors.teal,
                    onTap: () => _handleAction('traffic_news'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para construir cada uno de los 8 botones de forma uniforme
  Widget _buildEmergencyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String actionId) {
    // Lógica para rutear cada botón de emergencia o módulo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Acción seleccionada: $actionId'), duration: const Duration(milliseconds: 800)),
    );
  }
}
