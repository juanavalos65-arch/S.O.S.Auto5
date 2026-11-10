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
  String _mapEngine = 'Google Maps (Interno)'; // Motor activo dentro de la app

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
            // Contenedor principal del mapa integrado en la app con grilla y simulación de ruta
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.navigation, size: 50, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'S.O.S. Auto - Vista de Mapa Integrada',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Renderizando con: $_mapEngine',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Desliza para mover / Pellizca para zoom en pantalla',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Selector flotante para cambiar entre estilos de mapa interno
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
                  value: _mapEngine,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.layers, size: 18, color: Colors.blueAccent),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: ['Google Maps (Interno)', 'Waze (Interno)'].map((String engine) {
                    return DropdownMenuItem<String>(
                      value: engine,
                      child: Text('Vista: $engine'),
                    );
                  }).toList(),
                  onChanged: (String? newEngine) {
                    if (newEngine != null) {
                      setState(() {
                        _mapEngine = newEngine;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cambiando motor interno a $newEngine')),
                      );
                    }
                  },
                ),
              ),
            ),

            // Controles flotantes de GPS y Zoom
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
                        const SnackBar(content: Text('Mapa centrado en tu posición actual')),
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
