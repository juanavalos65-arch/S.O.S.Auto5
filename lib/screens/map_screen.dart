import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  String _selectedEngine = 'Satélite (Esri)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMapHtml('satellite');
  }

  void _initMapHtml(String type) {
    final String tileUrl = type == 'satellite'
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
          html, body, #map { width: 100%; height: 100%; margin: 0; padding: 0; background: #e5effa; }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <script>
          var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([6.2442, -75.5812], 15);
          L.tileLayer('$tileUrl', {
            maxZoom: 19,
            subdomains: ['a', 'b', 'c']
          }).addTo(map);

          L.marker([6.2442, -75.5812]).addTo(map)
            .bindPopup("<b>S.O.S. Auto</b><br />Ubicación activa.").openPopup();
        </script>
      </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE5EFFA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  void _switchMapStyle(String style) {
    setState(() {
      _selectedEngine = style;
      _isLoading = true;
    });

    if (style.contains('Satélite')) {
      _initMapHtml('satellite');
    } else {
      _initMapHtml('standard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: const Color(0xFFE5EFFA),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Cargando cartografía...',
                      style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
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
                value: _selectedEngine,
                underline: const SizedBox(),
                icon: const Icon(Icons.satellite, size: 18, color: Colors.blueAccent),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                items: [
                  'Satélite (Esri)',
                  'Estándar (OpenStreetMap)'
                ].map((String map) {
                  return DropdownMenuItem<String>(
                    value: map,
                    child: Text('Vista: $map'),
                  );
                }).toList(),
                onChanged: (String? newMap) {
                  if (newMap != null) {
                    _switchMapStyle(newMap);
                  }
                },
              ),
            ),
          ),
          Positioned(
            top: 75,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'reload_sat',
              backgroundColor: Colors.white,
              child: const Icon(Icons.refresh, color: Colors.blueAccent),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _controller.reload();
              },
            ),
          ),
        ],
      ),
    );
  }
}
