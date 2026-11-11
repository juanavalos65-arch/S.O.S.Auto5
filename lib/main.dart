import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/supabase_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización corregida con publishableKey
  await Supabase.initialize(
    url: 'https://TU-PROYECTO.supabase.co',
    publishableKey: 'TU_PUBLISHABLE_KEY',
  );

  runApp(const SOSAutoApp());
}

class SOSAutoApp extends StatelessWidget {
  const SOSAutoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
