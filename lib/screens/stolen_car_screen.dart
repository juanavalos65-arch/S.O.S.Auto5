import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';
import '../services/emergency_alert_store.dart';
import '../services/emergency_sound_service.dart';
import '../services/vehicle_session.dart';

class StolenCarScreen extends StatefulWidget {
  const StolenCarScreen({super.key});
  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(length: 2, vsync: this);
    _cargarVehiculoYGps();
  }

  Future _cargarVehiculoYGps() async {
    try {
      Map? data;

      final reg = await EmergencyAlertStore.getRegisteredVehicle();
      if (reg != null) {
        data = Map.from(reg);
      } else {
        final rawSec = await _storage.read(key: 'sos_auto_registered_vehicle');
        if (rawSec != null && rawSec.isNotEmpty) {
          final decoded = jsonDecode(rawSec);
          if (decoded is Map) data = decoded;
        }
      }

      if (data == null) {
        final prefs = await SharedPreferences.getInstance();
        final rawVehiculo = prefs.getString('sos_auto_registered_vehicle') ??
            prefs.getString('sos_auto_vehicle_session') ??
            prefs.getString('vehiculo_registrado');
        if (rawVehiculo != null && rawVehiculo.isNotEmpty) {
          final decoded = jsonDecode(rawVehiculo);
          if (decoded is Map) data = decoded;
        }
      }

      if (data != null) {
        final placa =
            (data['plate'] ?? data['placa'] ?? '').toString().toUpperCase();
        final tipo = (data['vehicleType'] ??
                data['tipoVehiculo'] ??
                data['tipo'] ??
                'Vehículo')
            .toString();
        final marca = (data['brand'] ?? data['marca'] ?? '').toString();
        final modelo = (data['model'] ?? data['modelo'] ?? '').toString();
        final color = (data['color'] ?? '').toString();
        final ciudad = (data['city'] ?? data['ciudad'] ?? '').toString();

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
          _tipoReal = VehicleSession.vehicleType;
          _marcaReal = VehicleSession.brand;
          _modeloReal = VehicleSession.model;
          _colorReal = VehicleSession.color;
          final armado =
              '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.model} ${VehicleSession.color}'
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
          _vehiculoReal = armado.isNotEmpty ? armado : 'Vehículo S.O.S. Auto';
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
    _tabController.dispose();
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
        ? 'stolen_$_placaReal'
        : 'stolen_${DateTime.now().millisecondsSinceEpoch}';
    _docId = docId;
    _bannerId = docId;

    final extra = [
      if (detalle.isNotEmpty) detalle,
      if (ultimaUbicacion.isNotEmpty) 'Última ubicación: $ultimaUbicacion',
    ].join(' • ');

    final tituloBanner =
        '$_vehiculoReal • Placa $_placaReal ($_ciudadReal)${extra.isNotEmpty ? " • $extra" : ""}';

    unawaited(
      BannerFeedService.publishAlert(
        id: docId,
        category: 'stolen',
        tag: '🚨 VEHÍCULO ROBADO — $_ciudadReal',
        title: tituloBanner,
        city: _ciudadReal,
        plate: _placaReal,
        lat: _lat,
        lng: _lng,
        gravedad: 'critica',
      ),
    );

    final mensajeVoz =
        'Alerta de robo de auto. Vehículo $_vehiculoReal, placa $_placaReal.';
    unawaited(
      EmergencySoundService.startSiren(
        mensaje: mensajeVoz,
      ),
    );

    unawaited(
      FirebaseFirestore.instance.collection('vehiculos_robados').doc(docId).set(
        {
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
        },
        SetOptions(merge: true),
      ).catchError((_) {}),
    );

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _alertSent = true;
        _estadoNube = '✅ Robo publicado en el Banner y alerta activada';
      });
    }
  }

  void _cancelOrDeactivate() {
    _countdownTimer?.cancel();
    unawaited(EmergencySoundService.stopSiren());
    if (_bannerId != null) {
      unawaited(BannerFeedService.deactivateAlert(_bannerId!));
      unawaited(EmergencyAlertStore.dismissAlert(_bannerId!));
    }
    if (_docId != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_docId)
            .update({
          'activa': false,
          'cerradaEn': FieldValue.serverTimestamp(),
        }).catchError((_) {}),
      );
    }
    setState(() {
      _isCountingDown = false;
      _alertSent = false;
      _secondsRemaining = 5;
      _estadoNube = 'Alerta desactivada y retirada del banner';
    });
  }

  Future _llamar123() async {
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
          'Robo de Auto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Reportar robo'),
            Tab(icon: Icon(Icons.directions_car), text: 'Vehículos robados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _alertSent
                        ? const Color(0xFFB71C1C)
                        : Colors.red.shade700,
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
          _ListaVehiculosRobados(),
        ],
      ),
    );
  }
}

class _ListaVehiculosRobados extends StatelessWidget {
  Future _avisarAvistamiento(String placa, String vehiculo, String ciudad) async {
    final msg = Uri.encodeComponent(
      '🚨 *AVISTAMIENTO VEHÍCULO ROBADO — S.O.S. AUTO*\n'
      'Acabo de ver el vehículo reportado como robado:\n'
      '• *Vehículo:* $vehiculo\n'
      '• *Placa:* $placa\n'
      '• *Ciudad:* $ciudad',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future _llamar123() async {
    final uri = Uri.parse('tel:123');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('vehiculos_robados')
          .where('activa', isEqualTo: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final querySnap = snapshot.data as QuerySnapshot?;
        final docs = querySnap?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay vehículos reportados como robados en este momento.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map;
            final String placa =
                (data['placa'] ?? data['plate'] ?? 'SIN PLACA').toString();
            final String vehiculo =
                (data['detalleVehiculo'] ?? data['vehiculo'] ?? 'Vehículo')
                    .toString();
            final String ciudad =
                (data['ciudad'] ?? 'Colombia').toString();
            final String ultimaUbicacion =
                (data['ultimaUbicacion'] ?? '').toString();
            final String detalle = (data['detalle'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade300, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFB71C1C), size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$vehiculo • Placa $placa',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ciudad,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ultimaUbicacion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Última ubicación: $ultimaUbicacion',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (detalle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(detalle,
                          style: const TextStyle(color: Colors.black87)),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _llamar123,
                          icon: const Icon(Icons.call,
                              size: 17, color: Color(0xFF0D47A1)),
                          label: const Text(
                            '123',
                            style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _avisarAvistamiento(placa, vehiculo, ciudad),
                          icon: const Icon(Icons.share,
                              size: 17, color: Color(0xFFEF6C00)),
                          label: const Text(
                            'Lo vi',
                            style: TextStyle(
                                color: Color(0xFFEF6C00),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await doc.reference.update({
                              'activa': false,
                              'cerradaEn': FieldValue.serverTimestamp(),
                            });
                            await BannerFeedService.deactivateAlert(doc.id);
                            await BannerFeedService.deactivateAlert(
                                'stolen_$placa');
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 17, color: Colors.green),
                          label: const Text(
                            'Recuperado',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
