import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreenWidget extends StatelessWidget {
  const MapScreenWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Coordenadas de ejemplo centradas en Medellín / Colombia
    final LatLng initialPosition = LatLng(6.2442, -75.5812);

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialPosition,
        initialZoom: 15.0,
      ),
      children: [
        // Capa de teselas del mapa (OpenStreetMap gratuito)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ge.sosauto.app',
        ),
        // Capa de marcadores (Aquí puedes ubicar aliados y vehículos reportados)
        MarkerLayer(
          markers: [
            Marker(
              point: initialPosition,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
