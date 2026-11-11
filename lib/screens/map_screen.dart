import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  static const LatLng _initialPosition = LatLng(9.3047, -75.3978);
  
  String _selectedStyle = 'Satélite (Esri)';
  
  final String _esriUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  final String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    String currentUrl = _selectedStyle.contains('Satélite') ? _esriUrl : _osmUrl;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: currentUrl,
                  userAgentPackageName: 'com.sosauto.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _initialPosition,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.navigation,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'Tiles c Esri / OpenStreetMap',
                      textStyle: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 75,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: DropdownButton<String>(
                value: _selectedStyle,
                underline: const SizedBox(),
                icon: const Icon(Icons.layers, size: 18, color: Colors.blueAccent),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                items: [
                  'Satélite (Esri)',
                  'Estándar (OpenStreetMap)'
                ].map((String style) {
                  return DropdownMenuItem<String>(
                    value: style,
                    child: Text('Vista: $style'),
                  );
                }).toList(),
                onChanged: (String? newStyle) {
                  if (newStyle != null) {
                    setState(() {
                      _selectedStyle = newStyle;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cambiando a vista $newStyle')),
                    );
                  }
                },
              ),
            ),
          ),
          Positioned(
            top: 75,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'gps_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blueAccent),
                  onPressed: () {
                    _mapController.move(_initialPosition, 14.0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mapa centrado en tu posición')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
