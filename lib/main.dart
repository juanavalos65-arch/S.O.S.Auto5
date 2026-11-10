import 'package:flutter/material.dart';
import 'dart:async';

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
      },
    );
  }
}

// Pantalla de bienvenida con temporizador automático de 3 segundos
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

// Pantalla Principal Interactiva con Mapa y Botones de Asistencia
class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Simulación o contenedor del Mapa Interactivo de fondo
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Mapa Interactivo Activo (Medellín / Vías)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
          // Panel inferior o botones flotantes de asistencia
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Me Varé
                      },
                      icon: const Icon(Icons.car_repair, color: Colors.orange),
                      label: const Text('Me Varé'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Me Accidenté
                      },
                      icon: const Icon(Icons.warning, color: Colors.red),
                      label: const Text('Me Accidenté'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción En Peligro
                      },
                      icon: const Icon(Icons.security, color: Colors.purple),
                      label: const Text('Peligro'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Paute Aquí
                      },
                      icon: const Icon(Icons.campaign, color: Colors.blue),
                      label: const Text('Paute Aquí'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
