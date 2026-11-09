import 'package:flutter/material.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de ejecutar código asíncrono o servicios nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SosAutoApp());
}

class SosAutoApp extends StatelessWidget {
  const SosAutoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SosAutoHomePage(),
    );
  }
}

class SosAutoHomePage extends StatelessWidget {
  const SosAutoHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.directions_car, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Bienvenido a S.O.S. Auto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Sistema de asistencia y tránsito activo',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
