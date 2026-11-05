import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SosAutoApp());
}

class SosAutoApp extends StatelessWidget {
  const SosAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A2540),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2540)),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Enlace oficial de Wompi para pauta y aliados
  Future<void> _launchWompi() async {
    final Uri url = Uri.parse('https://checkout.wompi.co/l/VPOS_3Odu3K');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir la pasarela Wompi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Corporativa
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car_filled, color: Colors.red, size: 36),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'S.O.S.Auto',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A2540),
                              ),
                            ),
                            Text(
                              'Tu ruta nuestro compromiso',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Sección Publicidad / Aliados
                const Text(
                  'Publicidad',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _AdChip(label: 'SHELL'),
                      _AdChip(label: 'PIRELLI'),
                      _AdChip(label: 'MICHELIN'),
                      _AdChip(label: 'BOSCH'),
                      _AdChip(label: 'AXA'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mapa Interactivo Central (Simulado con GoogleMap)
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        const GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(9.3047, -75.3978), // Sincelejo, Sucre
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2540),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🚗 + 28km/h',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botonera Principal (Grid 4x2)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics,
                  childAspectRatio: 2.3,
                  children: [
                    _ActionCard(
                      title: 'Me varé',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Me accidenté',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Estoy en peligro',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Robo de auto',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Me detuvo\nun agente de tránsito',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      fontSize: 11,
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Novedades\nen la vía',
                      color: const Color(0xFFD6E4FC),
                      textColor: const Color(0xFF0A2540),
                      fontSize: 12,
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'Registre\nsu vehículo',
                      color: Colors.red,
                      textColor: Colors.white,
                      fontSize: 12,
                      onTap: () {},
                    ),
                    _ActionCard(
                      title: 'PAUTE\nAQUÍ',
                      color: Colors.red,
                      textColor: Colors.white,
                      fontSize: 13,
                      onTap: _launchWompi,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdChip extends StatelessWidget {
  final String label;
  const _AdChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2540), fontSize: 13),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final Color color;
  final Color textColor;
  final double fontSize;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.color,
    required this.textColor,
    this.fontSize = 12,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
