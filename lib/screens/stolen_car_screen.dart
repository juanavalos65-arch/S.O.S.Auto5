import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_alert_store.dart';
import '../services/emergency_sound_service.dart';
import '../services/vehicle_session.dart';
import '../widget/banner_dinamico.dart';

class StolenCarScreen extends StatefulWidget {
  const StolenCarScreen({super.key});
  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  final TextEditingController _detalleCtrl = TextEditingController();
  final TextEditingController _ultimaUbicacionCtrl = TextEditingController();

  bool _isCountingDown = false;
  bool _alertSent = false;
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  String _placaReal = 'SIN PLACA';
  String _vehiculoReal = 'Vehículo S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  String _marcaReal = '';
  String _modeloReal = '';
  String _colorReal = '';
  String _tipoReal = 'Vehículo';
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
      final reg = await EmergencyAlertStore.getRegisteredVehicle();
      if (reg != null) {
        final placa =
            (reg['plate'] ?? reg['placa'] ?? '').toString().toUpperCase();
        final tipo =
            (reg['vehicleType'] ?? reg['tipoVehiculo'] ?? 'Vehículo').toString();
        final marca = (reg['brand'] ?? reg['marca'] ?? '').toString();
        final modelo = (reg['model'] ?? reg['modelo'] ?? '').toString();
        final color = (reg['color'] ?? '').toString();
        final ciudad = (reg['city'] ?? reg['ciudad'] ?? '').toString();

        if (mounted) {
          setState(() {
            _placaReal = placa.isNotEmpty ? placa : 'SIN PLACA';
            _tipoReal = tipo;
            _marcaReal = marca;
            _modeloReal = modelo;
            _colorReal = color;
            final armado = '$tipo $marca $modelo $color'
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            _vehiculoReal = armado.isNotEmpty ? armado : 'Vehículo S.O.S. Auto';
            _ciudadReal = ciudad.isNotEmpty ? ciudad : 'Colombia';
          });
        }
      } else if (VehicleSession.hasVehicle && mounted) {
        setState(() {
          _placaReal = VehicleSession.plate.toUpperCase();
          _vehiculoReal =
              '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.color}'
                  .trim();
          _ciudadReal =
              VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Colombia';
        });
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always ||
          p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.medium)
                .timeout(const Duration(seconds: 4));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
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
    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 5;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    final docId = _placaReal != 'SIN PLACA'
        ? _placaReal
        : 'stolen_${DateTime.now().millisecondsSinceEpoch}';
    _docId = docId;
    _bannerId = docId;

    final extra = [
      if (detalle.isNotEmpty) detalle,
      if (ultimaUbicacion.isNotEmpty) 'Última ubicación: $ultimaUbicacion',
    ].join(' • ');

    final textoBanner =
        '🚨 ROBO ACTIVO ($_ciudadReal): $_vehiculoReal [$_placaReal]${extra.isNotEmpty ? " • $extra" : ""}';

    // 1. PUBLICA AL INSTANTE EN BANNER DINÁMICO Y DISPARA SIRENA (0 ms)
    unawaited(
      BannerDinamico.publicarLocal(
        id: docId,
        texto: textoBanner,
        color: const Color(0xFFB71C1C),
        icono: Icons.warning_amber_rounded,
        tipo: 'robo',
      ),
    );
    unawaited(
      EmergencySoundService.startSiren(
        mensaje: '¡Alerta de robo de vehículo placa $_placaReal!',
      ),
    );

    // 2. GUARDA EN FIRESTORE EN SEGUNDO PLANO EN 'vehiculos_robados'
    unawaited(
      FirebaseFirestore.instance.collection('vehiculos_robados').doc(docId).set({
        'id': docId,
        'placa': _placaReal,
        'plate': _placaReal,
        'detalleVehiculo': _vehiculoReal,
        'vehiculo': _vehiculoReal,
        'tipoVehiculo': _tipoReal,
        'marca': _marcaReal,
        'modelo': _modeloReal,
        'color': _colorReal,
        'ciudad': _ciudadReal,
        'detalle': detalle,
        'ultimaUbicacion': ultimaUbicacion,
        'lat': _lat,
        'lng': _lng,
        'activa': true,
        'fechaReporte': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {}),
    );

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _alertSent = true;
        _estadoNube = '✅ Robo publicado en el Banner y Sirena activada';
      });
    }
  }

  void _cancelOrDeactivate() {
    _countdownTimer?.cancel();
    unawaited(EmergencySoundService.stopSiren());
    if (_bannerId != null) {
      unawaited(BannerDinamico.quitarLocal(_bannerId!));
      unawaited(EmergencyAlertStore.dismissAlert(_bannerId!));
    }
    if (_docId != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_docId)
            .update({'activa': false, 'cerradaEn': FieldValue.serverTimestamp()})
            .catchError((_) {}),
      );
    }
    setState(() {
      _isCountingDown = false;
      _alertSent = false;
      _secondsRemaining = 5;
      _estadoNube = 'Alerta desactivada y retirada del banner';
    });
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehículo Robado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _alertSent ? const Color(0xFFB71C1C) : Colors.red.shade700,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCountingDown
                        ? 'PUBLICANDO EN BANNER EN $_secondsRemaining s...'
                        : (_alertSent
                            ? '¡ROBO PUBLICADO EN BANNER!'
                            : 'REPORTAR VEHÍCULO ROBADO'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_vehiculoReal • Placa: $_placaReal\n$_estadoNube',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!_isCountingDown && !_alertSent)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                        ),
                        onPressed: _startCountdown,
                        icon: const Icon(Icons.sos),
                        label: const Text(
                          'REPORTAR ROBO AHORA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _cancelOrDeactivate,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          _isCountingDown
                              ? 'CANCELAR CUENTA REGRESIVA'
                              : 'DESACTIVAR ALERTA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (_alertSent) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _llamar123,
                        icon: const Icon(Icons.call),
                        label: const Text(
                          'LLAMAR AL 123',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ultimaUbicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Última ubicación vista (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detalleCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalle del robo (opcional)',
                hintText: 'Ej: Dos hombres en moto, sentido norte...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
