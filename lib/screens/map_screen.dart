import 'package:flutter/material.dart';
import 'package:maplibre_gl/mapbox_gl.dart';

class SOSMapWidget extends StatefulWidget {
  @override
  _SOSMapWidgetState createState() => _SOSMapWidgetState();
}

class _SOSMapWidgetState extends State<SOSMapWidget> {
  MaplibreMapController? mapController;

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaplibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: LatLng(6.2442, -75.5812), // Coordenadas base (ej. Medellín)
        zoom: 14.0,
      ),
      styleString: "https://demotiles.maplibre.org/style.json", // O servidor OSM vectorial
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.Tracking,
    );
  }
}
