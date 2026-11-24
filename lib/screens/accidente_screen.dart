import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';
import '../services/vehicle_session.dart';

class AccidenteScreen extends StatefulWidget {
  const AccidenteScreen({super.key});
  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isCountingDown = false;
  bool _alertSent = false;
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  String _selectedSeverity = 'Choque leve';
  final TextEditingController _otherPlatesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String _placaReal = 'SIN PLACA';
  String _vehiculoReal = 'Vehículo S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  double? _lat;
  double? _lng;
  String? _docId;
  String? _bannerId;
  String _estadoNube = 'Listo para publicar accidente en el banner';

  final List _severityLevels = [
    {'id': 'Choque leve', 'title': 'Choque leve (solo daños menores)', 'subtitle': 'Sin heridos, vehículos movilizables', 'icon': Icons.car_crash_outlined, 'color': Colors.amber},
    {'id': 'Daños graves', 'title': 'Daños graves al vehículo', 'subtitle': 'Vehículo inmovilizado, requiere grúa', 'icon': Icons.minor_crash, 'color': Colors.deepOrange},
    {'id': 'Personas lesionadas', 'title': 'Personas lesionadas', 'subtitle': 'Se requiere ambulancia y atención médica', 'icon': Icons.medical_services, 'color': Colors.red},
    {'id': 'Con víctimas fatales', 'title': 'Con víctimas fatales', 'subtitle': 'Emergencia crítica - No mover escena', 'icon': Icons.warning_amber_rounded, 'color': const Color(0xFF8B0000)},
  ];

  @override
  void initState() {
    super.initState();
    _cargarVehiculoYGps();
  }

  Future<void> _cargarVehiculoYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        final v = d['vehicle'] as Map? ?? {};
        final l = d['location'] as Map? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ?? VehicleSession.plate).toString().toUpperCase();
            if (_placaReal.isEmpty) _placaReal = 'SIN PLACA';
            _vehiculoReal = '${v['type'] ?? ''} ${v['brand'] ?? ''} ${v['color'] ?? ''}'.trim();
            if (_vehiculoReal.isEmpty) _vehiculoReal = 'Vehículo S.O.S. Auto';
            _ciudadReal = (l['city'] ?? VehicleSession.city).toString();
            if (_ciudadReal.isEmpty) _ciudadReal = 'Colombia';
          });
        }
      } else if (VehicleSession.hasVehicle && mounted) {
        setState(() {
          _placaReal = VehicleSession.plate.toUpperCase();
          _vehiculoReal = '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.color}'.trim();
          _ciudadReal = VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Colombia';
        });
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium).timeout(const Duration(seconds: 4));
        if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otherPlatesController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _startEmergencyCountdown() {
    if (_isCountingDown || _alertSent) return;
    setState(() { _isCountingDown = true; _secondsRemaining = 5; });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _publicarAccidenteReal();
      }
    });
  }

  void _publicarAccidenteReal() {
    final otrasPlacas = _otherPlatesController.text.trim().toUpperCase();
    final detalle = _detailsController.text.trim();
    final docRef = FirebaseFirestore.instance.collection('accidentes_viales').doc();
    _docId = docRef.id;
    _bannerId = 'acc_${docRef.id}';

    final extra = [
      if (otrasPlacas.isNotEmpty) 'Involucrados: $otrasPlacas',
      if (detalle.isNotEmpty) detalle,
    ].join(' • ');

    // IGUAL QUE NOVEDADES: directo de VehicleSession
    final String placa = VehicleSession.hasVehicle ? VehicleSession.plate.toUpperCase() : _placaReal;
    final String ciudad = VehicleSession.city.isNotEmpty ? VehicleSession.city : _ciudadReal;
    final String tituloBanner = '$_vehiculoReal ($placa)${extra.isNotEmpty ? ' • $extra' : ''}';

    unawaited(docRef.set({
      'placa': placa,
      'vehiculo': _vehiculoReal,
      'ciudad': ciudad,
      'gravedad': _selectedSeverity,
      'otrasPlacas': otrasPlacas,
      'detalle': detalle,
      'latitud': _lat,
      'longitud': _lng,
      'activa': true,
      'creadaEn': FieldValue.serverTimestamp(),
    }).catchError((_) {}));

    unawaited(
      BannerFeedService.publishAlert(
        id: _bannerId!,
        category: 'incident',
        tag: '🚨 ACCIDENTE VIAL ($_selectedSeverity) — $ciudad',
        title: tituloBanner,
        city: ciudad,
        plate: placa,
        lat: _lat,
        lng: _lng,
        gravedad: _selectedSeverity,
      ).catchError((_) {}),
    );

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _alertSent = true;
        _estadoNube = '✅ Accidente publicado en el Banner en vivo';
      });
    }
  }

  void _cancelOrDeactivateAlert() {
    _countdownTimer?.cancel();
    if (_bannerId != null) unawaited(BannerFeedService.deactivateAlert(_bannerId!).catchError((_) {}));
    if (_docId != null) {
      unawaited(FirebaseFirestore.instance.collection('accidentes_viales').doc(_docId).update({'activa': false, 'cerradaEn': FieldValue.serverTimestamp()}).catchError((_) {}));
    }
    setState(() { _isCountingDown = false; _alertSent = false; _secondsRemaining = 5; _estadoNube = 'Alerta desactivada y retirada del banner'; });
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Accidente', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _alertSent ? const Color(0xFF8B0000) : Colors.red.shade700, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Icon(_alertSent ? Icons.notifications_active : Icons.car_crash, color: Colors.white, size: 46),
                  const SizedBox(height: 8),
                  Text(_isCountingDown ? 'PUBLICANDO EN BANNER EN $_secondsRemaining s...' : (_alertSent ? '¡ACCIDENTE PUBLICADO EN BANNER!' : 'REPORTAR ACCIDENTE EN VÍA'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_vehiculoReal • Placa: $_placaReal\n$_estadoNube', textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                  const SizedBox(height: 14),
                  if (!_isCountingDown && !_alertSent)
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900), onPressed: _startEmergencyCountdown, icon: const Icon(Icons.sos), label: const Text('ACTIVAR ALERTA AHORA', style: TextStyle(fontWeight: FontWeight.bold))))
                  else
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87), onPressed: _cancelOrDeactivateAlert, icon: const Icon(Icons.cancel_outlined), label: Text(_isCountingDown ? 'CANCELAR CUENTA REGRESIVA' : 'DESACTIVAR ALERTA (SIN PIN)', style: const TextStyle(fontWeight: FontWeight.bold)))),
                  if (_alertSent) ...[
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: _llamar123, icon: const Icon(Icons.call), label: const Text('LLAMAR DE INMEDIATO AL 123', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('1. Gravedad del accidente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._severityLevels.map((item) {
              final String id = item['id'] as String;
              final bool isSelected = _selectedSeverity == id;
              final Color itemColor = item['color'] as Color;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? itemColor : Colors.grey.shade300, width: isSelected ? 2 : 1)),
                child: ListTile(
                  leading: Icon(item['icon'] as IconData, color: itemColor),
                  title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(item['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                  trailing: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? itemColor : Colors.grey),
                  onTap: () => setState(() => _selectedSeverity = id),
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(controller: _otherPlatesController, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Placa(s) de otros vehículos involucrados (opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _detailsController, decoration: const InputDecoration(labelText: 'Punto de referencia o detalle breve (opcional)', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}
