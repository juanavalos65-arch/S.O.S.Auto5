import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  double _previousScale = 1.0;
  String _preferredMap = 'Google Maps'; // Opción elegida por el usuario

  void _selectMapEngine(String mapType) {
    setState(() {
      _preferredMap = mapType;
    });
    
    // Muestra un aviso flotante confirmando el motor de navegación seleccionado estilo InDriver / Waze
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Motor de navegación cambiado a: $mapType'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onScaleStart: (details) {
          _previousScale = _scale;
          _previousOffset = details.focalPoint - _offset;
        },
        onScaleUpdate: (details) {
          setState(() {
            _scale = (_previousScale * details.scale).clamp(0.5, 3.0);
            _offset = details.focalPoint - _previousOffset;
          });
        },
        child: Stack(
          children: [
            // Fondo con grilla interactiva deslizable y escalable
            Positioned.fill(
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(_offset.dx, _offset.dy)
                  ..scale(_scale),
                alignment: Alignment.center,
                child: Container(
                  color: const Color(0xFFE5EFFA),
                  child: CustomPaint(
                    painter: MapGridPainter(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigation, size: 48, color: Colors.blueAccent),
                          const SizedBox(height: 10),
                          const Text(
                            'S.O.S. Auto - Navegación Activa',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Navegando con: $_preferredMap',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Desliza para mover / Pellizca para zoom',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Selector flotante de preferencia de Mapa (Google Maps vs Waze) estilo InDriver
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
                  value: _preferredMap,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.map, size: 18, color: Colors.blueAccent),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: ['Google Maps', 'Waze'].map((String map) {
                    return DropdownMenuItem<String>(
                      value: map,
                      child: Text('App: $map'),
                    );
                  }).toList(),
                  onChanged: (String? newMap) {
                    if (newMap != null) {
                      _selectMapEngine(newMap);
                    }
                  },
                ),
              ),
            ),

            // Controles flotantes superiores derechos (GPS y Zoom)
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
                      setState(() {
                        _scale = 1.0;
                        _offset = Offset.zero;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mapa centrado en Ruta / Medellín')),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black87),
                    onPressed: () {
                      setState(() {
                        _scale = (_scale * 1.2).clamp(0.5, 3.0);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black87),
                    onPressed: () {
                      setState(() {
                        _scale = (_scale / 1.2).clamp(0.5, 3.0);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.12)
      ..strokeWidth = 1.5;

    const spacing = 50.0;
    for (double i = -size.width; i < size.width * 2; i += spacing) {
      canvas.drawLine(Offset(i, -size.height), Offset(i, size.height * 2), paint);
    }
    for (double j = -size.height; j < size.height * 2; j += spacing) {
      canvas.drawLine(Offset(-size.width, j), Offset(size.width * 2, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
