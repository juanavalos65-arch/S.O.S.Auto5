import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  String _selectedEngine = 'Google Maps (Interno)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // URL de inserción directa para cargar Google Maps dentro de la WebView sin API Key
    final String initialUrl = 'https://maps.google.com/maps?q=6.2442,-75.5812&z=15&output=embed';
    
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
      ..loadRequest(Uri.parse(initialUrl));
  }

  void _switchMapEngine(String engine) {
    setState(() {
      _selectedEngine = engine;
      _isLoading = true;
    });

    String url = '';
    if (engine == 'Waze (Interno)') {
      // Vista web interactiva de OpenStreetMap / Waze compatible con embed
      url = 'https://www.openstreetmap.org/#map=15/6.2442/-75.5812';
    } else {
      // Google Maps Embed nativo sin API Key
      url = 'https://maps.google.com/maps?q=6.2442,-75.5812&z=15&output=embed';
    }

    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Visor web integrado que renderiza el mapa real dentro de la app
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),

          // Indicador de carga mientras renderiza la cartografía
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
                      'Cargando mapa en S.O.S. Auto...',
                      style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Selector flotante para cambiar entre motores de mapa dentro de la app
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
                icon: const Icon(Icons.map, size: 18, color: Colors.blueAccent),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                items: [
                  'Google Maps (Interno)',
                  'Waze (Interno)'
                ].map((String map) {
                  return DropdownMenuItem<String>(
                    value: map,
                    child: Text('Vista: $map'),
                  );
                }).toList(),
                onChanged: (String? newMap) {
                  if (newMap != null) {
                    _switchMapEngine(newMap);
                  }
                },
              ),
            ),
          ),

          // Botón flotante superior derecho para recargar o actualizar el mapa
          Positioned(
            top: 75,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'reload_map',
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
