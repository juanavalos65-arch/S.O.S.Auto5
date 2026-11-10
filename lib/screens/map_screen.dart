import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  String _selectedEngine = 'Google Maps';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebViewController('https://www.google.com/maps/@6.2442,-75.5812,15z');
  }

  void _initWebViewController(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE5EFFA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _switchMapEngine(String engine) {
    setState(() {
      _selectedEngine = engine;
      _isLoading = true;
    });

    if (engine == 'Waze') {
      // Cargador de Waze integrado en vista web
      _controller.loadRequest(Uri.parse('https://www.waze.com/ul?ll=6.2442,-75.5812&navigate=yes'));
    } else {
      // Cargador de Google Maps integrado en vista web
      _controller.loadRequest(Uri.parse('https://www.google.com/maps/@6.2442,-75.5812,15z'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Visor web integrado que muestra el mapa real dentro de la app
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),

          // Indicador de carga mientras renderiza la cartografía
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Selector flotante para cambiar entre Google Maps y Waze dentro de la app
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
                items: ['Google Maps', 'Waze'].map((String map) {
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

          // Controles flotantes superiores derechos (Recargar / Centrar)
          Positioned(
            top: 75,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'reload_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.blueAccent),
                  onPressed: () {
                    _controller.reload();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Actualizando mapa...')),
                    );
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
