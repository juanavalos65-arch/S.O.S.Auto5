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
                        children: const [
                          Icon(Icons.navigation, size: 48, color: Colors.blueAccent),
                          SizedBox(height: 10),
                          Text(
                            'S.O.S. Auto - Navegación Activa',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Desliza para mover el mapa / Pellizca para hacer zoom',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Controles flotantes superiores
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
