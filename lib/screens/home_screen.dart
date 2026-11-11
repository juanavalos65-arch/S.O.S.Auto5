import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Visor de Mapa OpenStreetMap
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(6.2442, -75.5812), // Medellín
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ge.sosauto.app',
              ),
            ],
          ),

          // Cabecera y Banner Dinámico
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "⚠️ S.O.S. Auto - Red Vial Activa",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Botones Flotantes Inferiores
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text("Me Varé"),
                    backgroundColor: Colors.yellow[700],
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("Me Accidenté"),
                    backgroundColor: Colors.red,
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("Paute Aquí"),
                    backgroundColor: Colors.blue,
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
