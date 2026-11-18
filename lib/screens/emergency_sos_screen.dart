import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';
import '../services/vehicle_session.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _seconds = 5;
  bool _alertaActiva = false;
  Timer? _timer;
  String _amenaza = 'Intento de hurto / Atraco en vía';

  String _placaReal = 'SIN PLACA';
  String _vehiculoReal = 'Vehículo S.O.S. Auto';
  String _propietarioReal = 'Conductor S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  List _contactosEmergencia = [];

  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo ubicación GPS...';
  String? _sosDocId;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudadReal';

  @override
  void initState() {
    super.initState();
    _precargarDatosYGps();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds == 5 || _seconds == 4 || _seconds == 3 || _seconds == 2) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        _activarAlertaReal();
      }
    });
  }

  Future _precargarDatosYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        final v = d['vehicle'] as Map? ?? {};
        final o = d['owner'] as Map? ?? {};
        final l = d['location'] as Map? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ??
                    (VehicleSession.hasVehicle ? VehicleSession.plate : 'SIN PLACA'))
                .toString()
                .toUpperCase();
            final tipo = (v['type'] ?? VehicleSession.vehicleType).toString();
            final marca = (v['brand'] ?? VehicleSession.brand).toString();
            final color = (v['color'] ?? VehicleSession.color).toString();
            _vehiculoReal = '$tipo $marca $color'.trim();
            _propietarioReal = (o['name'] ??
                    (VehicleSession.driverName.isNotEmpty
                        ? VehicleSession.driverName
                        : 'Conductor'))
                .toString();
            _ciudadReal = (l['city'] ??
                    (VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Colombia'))
                .toString();
            _contactosEmergencia = d['emergencyContacts'] as List? ?? [];
          });
        }
      } else if (VehicleSession.hasVehicle && mounted) {
        setState(() {
          _placaReal = VehicleSession.plate.toUpperCase();
          _vehiculoReal =
              '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.color}'
                  .trim();
          _propietarioReal = VehicleSession.driverName.isNotEmpty
              ? VehicleSession.driverName
              : 'Conductor';
          _ciudadReal =
              VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Colombia';
          if (VehicleSession.emergencyContactPhone.isNotEmpty) {
            _contactosEmergencia = [
              {
                'name': VehicleSession.emergencyContactName.isNotEmpty
                    ? VehicleSession.emergencyContactName
                    : 'Contacto de Emergencia',
                'fullPhone': VehicleSession.emergencyContactPhone,
              }
            ];
          }
        });
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _gpsTxt =
                '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
    }
  }

  Future _activarAlertaReal() async {
    setState(() {
      _seconds = 0;
      _alertaActiva = true;
    });

    try {
      final ref = await FirebaseFirestore.instance
          .collection('emergencias_sos')
          .add({
        'placa': _placaReal,
        'vehiculo': _vehiculoReal,
        'ciudad': _ciudadReal,
        'amenaza': _amenaza,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      _sosDocId = ref.id;

      await BannerFeedService.publishAlert(
        id: 'sos_${_sosDocId ?? _placaReal}',
        category: 'stolen',
        tag: 'EMERGENCIA SOS ACTIVA — $_ciudadReal',
        title: '$_amenaza • $_vehiculoReal ($_placaReal)',
        city: _ciudadReal,
        plate: _placaReal,
      );
    } catch (_) {}
  }

  Future _cancelarYDesactivar() async {
    _timer?.cancel();
    if (_sosDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(_sosDocId)
            .update({
          'activa': false,
          'cerradaEn': FieldValue.serverTimestamp(),
        });
        await BannerFeedService.deactivateAlert('sos_$_sosDocId');
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future _enviarWhatsAppContacto(Map contacto) async {
    final fullPhone = (contacto['fullPhone'] ?? contacto['phone'] ?? '').toString();
    final digits = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final nombre = (contacto['name'] ?? 'Contacto').toString();
    final msg = Uri.encodeComponent(
      '🆘 *EMERGENCIA S.O.S. AUTO — ESTOY EN PELIGRO* 🆘\n'
      'Hola $nombre, soy *$_propietarioReal*. Activé una alerta de emergencia:\n'
      '• *Situación:* $_amenaza\n'
      '• *Vehículo:* $_vehiculoReal (Placa *$_placaReal*)\n'
      '• *Mi ubicación GPS en vivo:* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future _llamar123() async {
    final uri = Uri.parse('tel:123');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8E0000),
      appBar: AppBar(
        title: const Text(
          'ESTOY EN PELIGRO — SOS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF5F0000),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Icon(
                _alertaActiva ? Icons.notifications_active : Icons.timer,
                color: Colors.white,
                size: 68,
              ),
              const SizedBox(height: 14),
              Text(
                _alertaActiva
                    ? '¡ALERTA SOS ENVIADA EN VIVO!'
                    : 'Enviando alerta silenciosa en $_seconds s...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$_vehiculoReal • Placa: $_placaReal\nGPS: $_gpsTxt',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField(
                value: _amenaza,
                isExpanded: true,
                dropdownColor: const Color(0xFF5F0000),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Tipo de amenaza o emergencia',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Intento de hurto / Atraco en vía',
                    child: Text('Intento de hurto / Atraco en vía'),
                  ),
                  DropdownMenuItem(
                    value: 'Persecución sospechosa',
                    child: Text('Persecución sospechosa'),
                  ),
                  DropdownMenuItem(
                    value: 'Retén ilegal / Zona insegura',
                    child: Text('Retén ilegal / Zona insegura'),
                  ),
                  DropdownMenuItem(
                    value: 'Emergencia médica urgente',
                    child: Text('Emergencia médica urgente'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _amenaza = v as String);
                  }
                },
              ),
              const SizedBox(height: 18),

              if (_alertaActiva) ...[
                if (_contactosEmergencia.isNotEmpty)
                  ..._contactosEmergencia.map((c) {
                    final map = c as Map;
                    final nombre = (map['name'] ?? 'Contacto').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _enviarWhatsAppContacto(map),
                          icon: const Icon(Icons.chat, size: 19),
                          label: Text(
                            'ENVIAR UBICACIÓN A ${nombre.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _llamar123,
                    icon: const Icon(Icons.call, size: 19),
                    label: const Text(
                      'LLAMAR DE INMEDIATO AL 123',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8E0000),
                  ),
                  onPressed: _cancelarYDesactivar,
                  child: const Text(
                    'CANCELAR / DESACTIVAR ALERTA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
