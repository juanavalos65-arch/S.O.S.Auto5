import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sos_auto5/screens/map_screen.dart';
import 'package:sos_auto5/screens/register_vehicle_screen.dart';
import 'package:sos_auto5/screens/emergency_sos_screen.dart';
import 'package:sos_auto5/screens/report_incident_screen.dart';
import 'package:sos_auto5/screens/traffic_stop_screen.dart';

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainHomeScreen(),
        '/register': (context) => const RegisterVehicleScreen(),
        '/emergency': (context) => const EmergencySosScreen(),
        '/report': (context) => const ReportIncidentScreen(),
        '/traffic': (context) => const TrafficStopScreen(),
      },
    );
  }
}

// Pantalla de Bienvenida (Splash Screen) con temporizador automático de 3 segundos
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.directions_car, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Bienvenido a S.O.S. Auto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Sistema de asistencia y tránsito activo',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla Principal Interactiva con Banner, Mapa Real y los 8 Botones
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _bannerIndex = 0;
  final List<String> _bannerMessages = [
    '🏢 Aliado Comercial: Talleres y Grúas Autorizadas (Paute Aquí)',
    '🚨 ALERTA ROBO: Vehículo Chevrolet Aveo - Placa HXU874',
    '⚠️ Novedad Vial: Precaución en vía por clima y mantenimiento'
  ];

  @override
  void initState() {
    super.initState();
    // Rotación automática del banner dinámico cada 4 segundos
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _bannerMessages.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.local_shipping, color: Colors.white),
            SizedBox(width: 10),
            Text('S.O.S. Auto', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Fondo: Mapa interactivo real proveniente de lib/screens/map_screen.dart
          const Positioned.fill(
            child: MapScreen(),
          ),

          // Banner Dinámico Informativo y Comercial (Superior)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: ValueKey<int>(_bannerIndex),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _bannerMessages[_bannerIndex],
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Panel Inferior con los 8 Botones Flotantes Conectados
          Positioned(
            bottom: 15,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila 1 (4 Botones)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, 'Regístrese', Icons.person_add, Colors.indigo, () {
                        Navigator.pushNamed(context, '/register');
                      }),
                      _buildActionButton(context, 'Paute Aquí', Icons.campaign, Colors.blue, () {
                        _showWompiDialog(context);
                      }),
                      _buildActionButton(context, 'Me Varé', Icons.car_repair, Colors.orange, () {
                        Navigator.pushNamed(context, '/emergency');
                      }),
                      _buildActionButton(context, 'Accidente', Icons.warning, Colors.red, () {
                        Navigator.pushNamed(context, '/emergency');
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fila 2 (4 Botones)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(context, 'Peligro', Icons.security, Colors.purple, () {
                        Navigator.pushNamed(context, '/emergency');
                      }),
                      _buildActionButton(context, 'Tránsito', Icons.local_police, Colors.teal, () {
                        Navigator.pushNamed(context, '/traffic');
                      }),
                      _buildActionButton(context, 'Robo Auto', Icons.directions_car_filled, Colors.brown, () {
                        Navigator.pushNamed(context, '/report');
                      }),
                      _buildActionButton(context, 'Novedades', Icons.announcement, Colors.green, () {
                        Navigator.pushNamed(context, '/report');
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _showWompiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Paute Aquí - S.O.S. Auto'),
        content: const Text(
          'Planes publicitarios:\n'
          '• 1 Mes: $50.000 COP\n'
          '• 6 Meses: $550.000 COP\n'
          '• 1 Año: $500.000 COP\n\n'
          'Redirigiendo a la pasarela oficial Wompi.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
