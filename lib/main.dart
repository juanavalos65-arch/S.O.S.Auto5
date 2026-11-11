import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/fcm_service.dart';
import 'widgets/sos_map_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar Supabase con tus credenciales
  await Supabase.initialize(
    url: 'https://TU-PROYECTO.supabase.co',
    anonKey: 'TU_ANON_KEY',
  );

  // Inicializar notificaciones push
  await FCMService().initializeFCM();

  runApp(const SOSAutoApp());
}

class SOSAutoApp extends StatelessWidget {
  const SOSAutoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
