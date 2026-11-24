import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';
import '../services/vehicle_session.dart';

class StolenCarScreen extends StatefulWidget {
  const StolenCarScreen({super.key});
  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _detalleCtrl = TextEditingController();
  final TextEditingController _ultimaUbicacionCtrl = TextEditingController();

  bool _isCountingDown = false;
  bool _alertSent = false;
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  String _placaReal = 'SIN PLACA';
  String _vehiculoReal = 'Vehículo S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  double? _lat;
  double? _lng;
  String? _docId;
  String? _bannerId;
  String _estadoNube = 'Listo para reportar robo en el banner';

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
        final pos = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium).timeout(const Duration(seconds: 4));
        if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _detalleCtrl.dispose();
    _ultimaUbicacionCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_isCountingDown || _alertSent) return;
    setState(() { _isCountingDown = true; _secondsRemaining = 5; });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _publicarRoboEnBanner();
      }
    });
  }

  void _publicarRoboEnBanner() {
    final detalle = _detalleCtrl.text.trim();
    final ultimaUbicacion = _ultimaUbicacionCtrl.text.trim();
    final docRef = FirebaseFirestore.instance.collection('robos_vehiculos').doc();
    _docId = docRef.id;
    _bannerId = 'stolen_${docRef.id}';

    // IGUAL QUE NOVEDADES
    final String placa = VehicleSession.hasVehicle ? VehicleSession.plate.toUpperCase() : _placaReal;
    final String ciudad = VehicleSession.city.isNotEmpty ? VehicleSession.city : _ciudadReal;
    final String tituloBanner = 'SE BUSCA $_vehiculoReal (Placa $placa)${detalle.isNotEmpty ? ' • $detalle' : ''}${ultimaUbicacion.isNotEmpty ? ' • Última ubicación: $ultimaUbicacion' : ''}';

    unawaited(docRef.set({
      'placa': placa,
      'vehiculo': _vehiculoReal,
      'ciudad': ciudad,
      'detalle': detalle,
      'ultimaUbicacion': ultimaUbicacion,
      'latitud': _lat,
      'longitud': _lng,
      'activa': true,
      'creadaEn': FieldValue.serverTimestamp(),
    }).catchError((_) {}));

    unawaited(
      BannerFeedService.publishAlert(
        id: _bannerId!,
        category: 'stolen',
        tag: '🚨 VEHÍCULO ROBADO — $ciudad',
        title: tituloBanner,
        city: ciudad,
        plate: placa,
        lat: _lat,
        lng: _lng,
        gravedad: 'Robo de vehículo',
      ).catchError((_) {}),
    );

    if (mounted) {
      setState(() { _isCountingDown = false; _alertSent = true; _estadoNube = '✅ Robo publicado en el Banner en vivo'; });
    }
  }

  void _cancelOrDeactivate() {
    _countdownTimer?.cancel();
    if (_bannerId != null) unawaited(BannerFeedService.deactivateAlert(_bannerId!).catchError((_) {}));
    if (_docId != null) unawaited(FirebaseFirestore.instance.collection('robos_vehiculos').doc(_docId).update({'activa': false, 'cerradaEn': FieldValue.serverTimestamp()}).catchError((_) {}));
    setState(() { _isCountingDown = false; _alertSent = false; _secondsRemaining = 5; _estadoNube = 'Alerta desactivada y retirada del banner'; });
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehículo Robado', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _alertSent ? const Color(0xFFB71C1C) : Colors.red.shade700, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 46),
                  const SizedBox(height: 8),
                  Text(_isCountingDown ? 'PUBLICANDO EN BANNER EN $_secondsRemaining s...' : (_alertSent ? '¡ROBO PUBLICADO EN BANNER!' : 'REPORTAR VEHÍCULO ROBADO'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_vehiculoReal • Placa: $_placaReal\n$_estadoNube', textAlign: TextAlign.center, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                  const SizedBox(height: 14),
                  if (!_isCountingDown && !_alertSent)
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900), onPressed: _startCountdown, icon: const Icon(Icons.sos), label: const Text('REPORTAR ROBO AHORA', style: TextStyle(fontWeight: FontWeight.bold))))
                  else
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87), onPressed: _cancelOrDeactivate, icon: const Icon(Icons.cancel_outlined), label: Text(_isCountingDown ? 'CANCELAR CUENTA REGRESIVA' : 'DESACTIVAR ALERTA', style: const TextStyle(fontWeight: FontWeight.bold)))),
                  if (_alertSent) ...[
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: _llamar123, icon: const Icon(Icons.call), label: const Text('LLAMAR AL 123', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _ultimaUbicacionCtrl, decoration: const InputDecoration(labelText: 'Última ubicación vista (opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _detalleCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Detalle del robo (opcional)', hintText: 'Ej: Dos hombres en moto, sentido norte...', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}
