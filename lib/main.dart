import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Si home_screen.dart está directo en lib/, cambia esta línea a: import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SosAutoApp());
}

class SosAutoApp extends StatelessWidget {
  const SosAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. AUTO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
