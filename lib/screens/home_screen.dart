import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  
  // Coordenadas de referencia (Medellín / Colombia)
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

          // 2. BANNER DINÁMICO SUPERIOR
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ S.O.S. Auto - Red Vial Activa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. PARRILLA INFERIOR CON LOS 8 BOTONES PRINCIPALES (4 columnas x 2 filas)
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
                crossAxisCount: 4, // Exactamente 4 columnas
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Sin desplazamiento, todo visible
                mainAxisSpacing: 6.0,
                crossAxisSpacing: 6.0,
                childAspectRatio: 0.95, // Proporción ideal para icono y texto
                children: [
                  _buildButton('Regístrese', Icons.person_add, Colors.blue, () => _onTap('Regístrese')),
                  _buildButton('Paute Aquí', Icons.campaign, Colors.amber, () => _onTap('Paute Aquí')),
                  _buildButton('Me Varé', Icons.car_repair, Colors.orange, () => _onTap('Me Varé')),
                  _buildButton('Accidente', Icons.car_crash, Colors.red, () => _onTap('Me Accidenté')),
                  _buildButton('Peligro', Icons.warning, Colors.deepOrange, () => _onTap('Estoy en Peligro')),
                  _buildButton('Tránsito', Icons.local_police, Colors.indigo, () => _onTap('Agente de Tránsito')),
                  _buildButton('Robo Auto', Icons.local_shipping, Colors.redAccent, () => _onTap('Robo de Auto')),
                  _buildButton('Novedades', Icons.announcement, Colors.teal, () => _onTap('Novedades en Vía')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para cada botón de la cuadrícula
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

  void _onTap(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accionando: $title'), duration: const Duration(milliseconds: 600)),
    );
  }
}
