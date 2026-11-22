import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'services/vehicle_session.dart';
import 'screens/camera_background_service.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase no inicializado aún (falta google-services.json): $e');
  }
  await VehicleSession.load();

  // ESTA LINEA ES LA QUE ACTIVA LAS CAMARAS EN SEGUNDO PLANO
  try {
    await initializeBackgroundService();
  } catch (e) {
    debugPrint('No se pudo iniciar servicio de cámaras: $e');
  }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
