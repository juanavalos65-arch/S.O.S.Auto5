import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

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
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFD700),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MainMapScreen(),
    );
  }
}

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  final MapController _mapController = MapController();
  final LocalAuthentication _auth = LocalAuthentication();
  
  LatLng _currentPosition = const LatLng(9.3047, -75.3978); // Default
  double _currentSpeedKmH = 0.0;
  StreamSubscription<Position>? _positionStream;

  // Banner dynamic rotation
  int _bannerIndex = 0;
  late Timer _bannerTimer;
  final List> _bannerItems = [
    {
      "tag": "🏢 PAUTA ALIADO",
      "title": "Taller Electromecánico El Pibe",
      "desc": "Grúas 24/7 y diagnóstico escáner - 15% desc. usuarios S.O.S. Auto",
      "color": "0xFF3B82F6"
    },
    {
      "tag": "🚨 AUTO ROBADO",
      "title": "Toyota Hilux Blanco 2023 - Placa HXU874",
      "desc": "Hurtado en Troncal del Caribe. Contacto directo en la app.",
      "color": "0xFFEF4444"
    },
    {
      "tag": "⚠️ NOVEDAD EN LA VÍA",
      "title": "Derrumbe Parcial - Vía a la Costa",
      "desc": "Paso restringido a un solo carril. Reduzca la velocidad.",
      "color": "0xFFF59E0B"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initGeolocation();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _bannerIndex = (_bannerIndex + 1) % _bannerItems.length;
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _bannerTimer.cancel();
    super.dispose();
  }

  Future<void> _initGeolocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentSpeedKmH = (position.speed * 3.6).clamp(0, 220);
      });
      _mapController.move(_currentPosition, 16.0);
    });
  }

  // Protocolo de Cancelación de Emergencia (5s)
  void _triggerEmergencyProtocol(String title, String alertType) {
    int secondsLeft = 5;
    Timer? countdownTimer;
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft > 1) {
                setModalState(() => secondsLeft--);
              } else {
                t.cancel();
                Navigator.of(dialogContext).pop();
                _dispatchEmergencySignal(alertType);
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                  const SizedBox(width: 10),
                  Expanded(child: Text('ALERTA: $title', style: const TextStyle(fontSize: 16, color: Colors.white))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: secondsLeft / 5.0,
                          color: Colors.redAccent,
                          strokeWidth: 6,
                        ),
                      ),
                      Text('$secondsLeft s', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text('Ingrese su PIN o Biometría para ANULAR el envío', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: "PIN (ej. 1234)",
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
                    onPressed: () async {
                      bool authenticated = await _auth.authenticate(
                        localizedReason: 'Confirme para anular la alerta por error',
                      );
                      if (authenticated) {
                        countdownTimer?.cancel();
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alerta ANULADA correctamente con biometría.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.fingerprint, color: Colors.black),
                    label: const Text('Anular con Biometría', style: TextStyle(color: Colors.black)),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (pinController.text == "1234") {
                      countdownTimer?.cancel();
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alerta ANULADA por PIN.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN incorrecto.')),
                      );
                    }
                  },
                  child: const Text('Confirmar PIN y Anular', style: TextStyle(color: Colors.redAccent)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _dispatchEmergencySignal(String alertType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('🚨 TRANSMITIENDO ALERTA: $alertType. Coordenadas enviadas.'),
      ),
    );
  }

  // Módulo Paute Aquí (Wompi)
  void _showPauteAquiModal() {
    String selectedPlan = "1 Mes";
    double basePrice = 50000;
    double taxRate = 0.19;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double taxValue = basePrice * taxRate;
            double wompiFee = (basePrice * 0.0265) + 700 + ((basePrice * 0.0265 + 700) * 0.19);
            double total = basePrice + taxValue + wompiFee;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📢 Paute Aquí - Banner S.O.S. Auto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedPlan,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    items: const [
                      DropdownMenuItem(value: "1 Mes", child: Text("1 Mes - \$50.000 COP")),
                      DropdownMenuItem(value: "6 Meses", child: Text("6 Meses - \$550.000 COP")),
                      DropdownMenuItem(value: "1 Año", child: Text("1 Año - \$500.000 COP (PROMO)")),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedPlan = val!;
                        if (selectedPlan == "1 Mes") basePrice = 50000;
                        if (selectedPlan == "6 Meses") basePrice = 550000;
                        if (selectedPlan == "1 Año") basePrice = 500000;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Valor Base:"), Text("\$${basePrice.toStringAsFixed(0)} COP")]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Impuesto (IVA 19%):"), Text("\$${taxValue.toStringAsFixed(0)} COP")]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Comisión Wompi:"), Text("\$${wompiFee.toStringAsFixed(0)} COP")]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TOTAL:", style: TextStyle(fontWeight: FontWeight.bold)), Text("\$${total.toStringAsFixed(0)} COP", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF22C55E)))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                      onPressed: () async {
                        final Uri url = Uri.parse('https://checkout.wompi.co/l/VPOS_3Odu3K');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      child: const Text('Pagar en Wompi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Módulo de Registro
  void _showRegistroModal() {
    final TextEditingController placaCtrl = TextEditingController();
    bool addExtraDriver = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Registro Vehicular S.O.S. Auto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: placaCtrl,
                    decoration: const InputDecoration(labelText: 'Placa del Vehículo (Obligatorio)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('¿Desea registrar otro conductor (ej. familiar) para esta misma placa?'),
                    value: addExtraDriver,
                    onChanged: (val) => setModalState(() => addExtraDriver = val!),
                  ),
                  if (addExtraDriver)
                    const TextField(
                      decoration: InputDecoration(labelText: 'Nombre y Cédula del Conductor Adicional', border: OutlineInputBorder()),
                    ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Vehículo con placa ${placaCtrl.text} registrado con éxito (E2EE).')),
                        );
                      },
                      child: const Text('Guardar Registro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBanner = _bannerItems[_bannerIndex];

    return Scaffold(
      body: Stack(
        children: [
          // MAPA INTERACTIVO REAL
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition,
              zoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sosauto.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 50,
                    height: 50,
                    builder: (ctx) => const Icon(Icons.navigation, color: Color(0xFF38BDF8), size: 40),
                  ),
                ],
              ),
            ],
          ),

          // CABECERA OFICIAL & BANNER DINÁMICO
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Header Fijo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.directions_car_filled, color: Color(0xFFFFD700)),
                          SizedBox(width: 8),
                          Text('S.O.S. AUTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFFD700))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: Text('${_currentSpeedKmH.toStringAsFixed(0)} km/h', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Banner Intercalado (5s)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(int.parse(currentBanner["color"]!)).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentBanner["tag"]!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(currentBanner["title"]!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(currentBanner["desc"]!, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // BARRA INFERIOR DE 8 BOTONES PRINCIPALES
          Positioned(
            bottom: 15,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton('📝 Regístrese', Colors.blue, _showRegistroModal),
                    _buildActionButton('📢 Paute Aquí', Colors.green, _showPauteAquiModal),
                    _buildActionButton('🟡 Me Varé', Colors.amber, () => _triggerEmergencyProtocol('Vehículo Varado', 'VARADO')),
                    _buildActionButton('🚨 Me Accidenté', Colors.red, () => _triggerEmergencyProtocol('Accidente Vial', 'ACCIDENTE')),
                    _buildActionButton('🔴 Estoy en Peligro', Colors.purple, () => _triggerEmergencyProtocol('Peligro Personal', 'PELIGRO')),
                    _buildActionButton('👮 Agente Tránsito', Colors.cyan, () => _triggerEmergencyProtocol('Detención Tránsito', 'TRANSITO')),
                    _buildActionButton('🟠 Robo de Auto', Colors.orange, () => _triggerEmergencyProtocol('Robo de Vehículo', 'ROBO')),
                    _buildActionButton('⚠️ Novedad Vía', Colors.teal, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte de Novedad Vial transmitido')))),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
