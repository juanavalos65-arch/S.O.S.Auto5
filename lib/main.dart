import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';
import 'services/vehicle_session.dart';

const FirebaseOptions sosAutoFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBNWAWrTAtLjGyQWCXowi7hRGu1wc_IbyQ',
  appId: '1:176539763285:android:9760a74844a0f5b2220adc',
  messagingSenderId: '176539763285',
  projectId: 'sos-auto-18e1c',
  databaseURL: 'https://sos-auto-18e1c-default-rtdb.firebaseio.com',
  storageBucket: 'sos-auto-18e1c.firebasestorage.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: sosAutoFirebaseOptions);
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  await VehicleSession.load();

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
