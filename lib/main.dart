import 'package:flutter/material.dart';
import 'package:location/location.dart';

void main() {
  runApp(const SOSAutoApp());
}

class SOSAutoApp extends StatelessWidget {
  const SOSAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SOSHomeScreen(),
    );
  }
}

class SOSHomeScreen extends StatefulWidget {
  const SOSHomeScreen({super.key});

  @override
  State<SOSHomeScreen> createState() => _SOSHomeScreenState();
}

class _SOSHomeScreenState extends State<SOSHomeScreen> {
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      _locationData = locData;
    });
  }

  void _triggerEmergency(String title, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: const Text(
          'Alerta de auxilio activada. Transmitiendo ubicación GPS a contactos y red de aliados cercanos...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar (PIN)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Alerta enviada con éxito!')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto - Seguridad Vial', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Simulación de Mapa Interactivo en Tiempo Real
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: Center(
                child: _locationData == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, size: 64, color: Colors.blueGrey),
                          const SizedBox(height: 10),
                          const Text(
                            'Mapa Interactivo S.O.S. Activo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Lat: ${_locationData!.latitude?.toStringAsFixed(4)}, Lon: ${_locationData!.longitude?.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          // Panel de Botones de Emergencia Flotantes / Principales
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _triggerEmergency('ESTOY EN PELIGRO', Colors.red),
                          icon: const Icon(Icons.warning),
                          label: const Text('Estoy en Peligro'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _triggerEmergency('ROBO DE AUTO', Colors.orange),
                          icon: const Icon(Icons.car_crash),
                          label: const Text('Robo de Auto'),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () => _triggerEmergency('ESTOY VARADO', Colors.amber.shade800),
                    icon: const Icon(Icons.build),
                    label: const Text('Estoy Varado (Asistencia)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
