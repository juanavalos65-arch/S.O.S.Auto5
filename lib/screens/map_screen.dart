import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Simulación visual interactiva de grilla y mapa vial (compatible sin errores de API Key nativa)
          Container(
            color: const Color(0xFFE5EFFA),
            child: CustomPaint(
              painter: MapGridPainter(),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 54, color: Colors.blueAccent),
                    SizedBox(height: 10),
                    Text(
                      'S.O.S. Auto - Mapa Interactivo Activo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitoreo de ruta y alertas comunitarias',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón flotante superior para centrar GPS o ubicación actual
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buscando ubicación GPS en tiempo real...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor auxiliar para dar el efecto visual de calles y rutas en el fondo del mapa
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      .color = Colors.blue.withOpacity(0.08)
      .strokeWidth = 1.5;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += spacing) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
