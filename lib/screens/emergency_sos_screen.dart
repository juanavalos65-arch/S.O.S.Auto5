import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';
import '../services/emergency_sound_service.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final List<String> _amenazas = [
    'Intento de atraco / encierro en vía',
    'Persecución sospechosa',
    'Falla mecánica en zona insegura',
    'Emergencia médica al volante',
    'Retén o situación irregular',
  ];

  String _amenazaSeleccionada = 'Intento de atraco / encierro en vía';
  final TextEditingController _detalleController = TextEditingController();

  int _segundosRestantes = 5;
  Timer? _countdownTimer;
  bool _alertaEnviada = false;
  bool _cancelada = false;
  String? _alertaActivaId;
  Position? _posicionActual;
  String _placa = '';
  String _vehiculo = '';
  String _ciudad = 'Colombia';
  List _contactos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosYGPS();
    _iniciarConteo();
  }

  Future<void> _cargarDatosYGPS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawVehiculo = prefs.getString('sos_auto_vehicle_session') ??
          prefs.getString('vehiculo_registrado');
      if (rawVehiculo != null && rawVehiculo.isNotEmpty) {
        final data = jsonDecode(rawVehiculo);
        if (data is Map) {
          _placa = (data['placa'] ?? data['plate'] ?? '').toString().toUpperCase();
          final marca = (data['marca'] ?? data['brand'] ?? '').toString();
          final modelo = (data['modelo'] ?? data['model'] ?? '').toString();
          final color = (data['color'] ?? '').toString();
          final ciudad = (data['ciudad'] ?? data['city'] ?? '').toString();
          _vehiculo = '$marca $modelo $color'.trim();
          if (ciudad.isNotEmpty) _ciudad = ciudad;

          final rawContactos = data['contactos'];
          if (rawContactos is List) {
            _contactos = rawContactos
                .where((c) => c is Map)
                .map((c) => {
                      'nombre': (c['nombre'] ?? '').toString(),
                      'telefono': (c['telefono'] ?? '').toString(),
                    })
                .where((c) => (c['telefono'] ?? '').isNotEmpty)
                .toList();
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        if (mounted) setState(() => _posicionActual = pos);
      }
    } catch (_) {}
  }

  void _iniciarConteo() {
    _countdownTimer?.cancel();
    _segundosRestantes = 5;
    _cancelada = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() => _segundosRestantes = 0);
        _dispararAlertaSOS();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  Future<void> _desactivarAlerta() async {
    _countdownTimer?.cancel();
    unawaited(EmergencySoundService.stopSiren());

    if (_alertaActivaId != null) {
      unawaited(BannerFeedService.deactivateAlert(_alertaActivaId!));
      if (Firebase.apps.isNotEmpty) {
        unawaited(
          FirebaseFirestore.instance
              .collection('emergencias_sos')
              .doc(_alertaActivaId)
              .update({
            'activa': false,
            'estado': 'cancelado',
            'cerradaEn': FieldValue.serverTimestamp(),
          }).catchError((_) {}),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _cancelada = true;
      _alertaEnviada = false;
      _alertaActivaId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta SOS desactivada.'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
  }

  void _dispararAlertaSOS() {
    if (_alertaEnviada || _cancelada) return;
    setState(() => _alertaEnviada = true);

    final id = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    _alertaActivaId = id;

    final detalle = _detalleController.text.trim();
    final amenazaTexto = detalle.isNotEmpty
        ? '$_amenazaSeleccionada ($detalle)'
        : _amenazaSeleccionada;

    final tituloBanner =
        '$amenazaTexto${_placa.isNotEmpty ? " • Placa $_placa" : ""}${_vehiculo.isNotEmpty ? " ($_vehiculo)" : ""}';

    // 1. PUBLICA AL INSTANTE EN EL BANNER (0 ms) Y GUARDA EN 'banner_alerts'
    unawaited(
      BannerFeedService.publishAlert(
        id: id,
        category: 'incident',
        tag: '🆘 ESTOY EN PELIGRO — $_ciudad',
        title: tituloBanner,
        city: _ciudad,
        plate: _placa,
        lat: _posicionActual?.latitude,
        lng: _posicionActual?.longitude,
        gravedad: 'critica',
      ),
    );

    // 2. DISPARA SIRENA DE EMERGENCIA AL INSTANTE
    unawaited(
      EmergencySoundService.startSiren(
        mensaje: '¡Alerta de emergencia S.O.S. Auto activada!',
      ),
    );

    // 3. GUARDA TAMBIÉN EN 'emergencias_sos' EN SEGUNDO PLANO
    if (Firebase.apps.isNotEmpty) {
      unawaited(
        FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(id)
            .set({
          'id': id,
          'amenaza': amenazaTexto,
          'placa': _placa,
          'vehiculo': _vehiculo,
          'ciudad': _ciudad,
          'lat': _posicionActual?.latitude,
          'lng': _posicionActual?.longitude,
          'activa': true,
          'estado': 'activo',
          'creadaEn': FieldValue.serverTimestamp(),
        }).catchError((_) {}),
      );
    }
  }

  Future<void> _llamar123() async {
    final uri = Uri(scheme: 'tel', path: '123');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _avisarWhatsApp() async {
    final ubicacion = _posicionActual != null
        ? 'https://maps.google.com/?q=${_posicionActual!.latitude},${_posicionActual!.longitude}'
        : 'Ubicación GPS en proceso';
    final mensaje = Uri.encodeComponent(
      '🆘 *ALERTA S.O.S. AUTO - ESTOY EN PELIGRO*\n'
      'Situación: $_amenazaSeleccionada\n'
      '${_placa.isNotEmpty ? "Placa: $_placa ($_vehiculo)\n" : ""}'
      'Ubicación: $ubicacion',
    );

    String telefono = '';
    if (_contactos.isNotEmpty) {
      telefono =
          _contactos.first['telefono'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (telefono.length == 10) telefono = '57$telefono';
    }

    final url = telefono.isNotEmpty
        ? Uri.parse('https://wa.me/$telefono?text=$mensaje')
        : Uri.parse('https://wa.me/?text=$mensaje');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    EmergencySoundService.stopSiren();
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E0000),
        foregroundColor: Colors.white,
        title: const Text(
          '🆘 ESTOY EN PELIGRO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _alertaEnviada
                      ? const Color(0xFFB71C1C)
                      : (_cancelada
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF3E0A0A)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      _alertaEnviada
                          ? '🚨 ALERTA SOS TRANSMITIDA A LA RED'
                          : (_cancelada
                              ? '✅ ALERTA DESACTIVADA'
                              : 'Tiene 5 segundos para cancelar la alerta'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_alertaEnviada && !_cancelada) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Enviando automáticamente en $_segundosRestantes s...',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (!_cancelada)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _desactivarAlerta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF8E0000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.cancel, size: 24),
                          label: const Text(
                            'DESACTIVAR ALERTA',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _iniciarConteo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: const Text('REACTIVAR ALERTA SOS'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tipo de situación:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _amenazas.map((item) {
                  final selected = _amenazaSeleccionada == item;
                  return ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    selectedColor: const Color(0xFFD32F2F),
                    backgroundColor: const Color(0xFF261212),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) =>
                        setState(() => _amenazaSeleccionada = item),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _detalleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Punto de referencia o detalle rápido (opcional)',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF261212),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.greenAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _posicionActual != null
                            ? 'GPS activo: ${_posicionActual!.latitude.toStringAsFixed(5)}, ${_posicionActual!.longitude.toStringAsFixed(5)}${_placa.isNotEmpty ? " • Placa $_placa" : ""}'
                            : 'Obteniendo coordenadas GPS...${_placa.isNotEmpty ? " • Placa $_placa" : ""}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _llamar123,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 24),
                  label: const Text(
                    'LLAMAR YA AL 123 (EMERGENCIAS)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _avisarWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share_location, size: 24),
                  label: const Text(
                    'ENVIAR UBICACIÓN POR WHATSAPP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
