import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_alert_store.dart';
import '../services/vehicle_session.dart';
import '../widget/banner_dinamico.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});
  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final TextEditingController _detalleCtrl = TextEditingController();

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
  String? _publishedBannerId;
  String _estadoNube = 'Cuenta regresiva de seguridad (5s)...';

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudadReal';

  @override
  void initState() {
    super.initState();
    _precargarDatosYGps();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        _activarAlertaReal();
      }
    });
  }

  Future<void> _precargarDatosYGps() async {
    try {
      final reg = await EmergencyAlertStore.getRegisteredVehicle();
      if (reg != null) {
        final placa =
            (reg['plate'] ?? reg['placa'] ?? '').toString().toUpperCase();
        final tipo =
            (reg['vehicleType'] ?? reg['tipoVehiculo'] ?? '').toString();
        final marca = (reg['brand'] ?? reg['marca'] ?? '').toString();
        final modelo = (reg['model'] ?? reg['modelo'] ?? '').toString();
        final color = (reg['color'] ?? '').toString();
        final ciudad = (reg['city'] ?? reg['ciudad'] ?? '').toString();
        final propietario =
            (reg['ownerName'] ?? reg['propietario'] ?? '').toString();

        final rawContacts =
            reg['emergencyContacts'] ?? reg['contactosEmergencia'];
        final List parsedContacts = [];
        if (rawContacts is Iterable) {
          for (final c in rawContacts) {
            if (c is Map) {
              parsedContacts.add({
                'name': (c['name'] ?? c['nombre'] ?? 'Contacto').toString(),
                'fullPhone': (c['phone'] ?? c['telefono'] ?? '').toString(),
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _placaReal = placa.isNotEmpty ? placa : 'SIN PLACA';
            final armado = '$tipo $marca $modelo $color'
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            _vehiculoReal = armado.isNotEmpty ? armado : 'Vehículo S.O.S. Auto';
            _propietarioReal = propietario.isNotEmpty
                ? propietario
                : 'Conductor S.O.S. Auto';
            _ciudadReal = ciudad.isNotEmpty ? ciudad : 'Colombia';
            _contactosEmergencia = parsedContacts;
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
            _gpsTxt =
                '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
      }
    } catch (_) {
      if (mounted && _lat == null) {
        setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
      }
    }
  }

  void _activarAlertaReal() {
    final detalleExtra = _detalleCtrl.text.trim();
    final idUnico = 'sos_${_placaReal}_${DateTime.now().millisecondsSinceEpoch}';
    _sosDocId = idUnico;
    _publishedBannerId = idUnico;

    final amenazaCompleta =
        detalleExtra.isNotEmpty ? '$_amenaza ($detalleExtra)' : _amenaza;
    final textoBanner =
        '🆘 SOS PELIGRO ($_ciudadReal): $amenazaCompleta • $_vehiculoReal [$_placaReal]';

    // 1. PUBLICA AL INSTANTE EN BANNER DINÁMICO Y DISPARA SIRENA (0 ms)
    unawaited(
      BannerDinamico.publicarLocal(
        id: idUnico,
        texto: textoBanner,
        color: const Color(0xFF8E0000),
        icono: Icons.notifications_active,
        tipo: 'emergencia',
      ),
    );

    // 2. GUARDA EN FIRESTORE EN SEGUNDO PLANO EN 'emergencias_sos'
    unawaited(
      FirebaseFirestore.instance.collection('emergencias_sos').doc(idUnico).set({
        'id': idUnico,
        'placa': _placaReal,
        'detalleVehiculo': _vehiculoReal,
        'propietario': _propietarioReal,
        'ciudad': _ciudadReal,
        'amenaza': amenazaCompleta,
        'detalle': detalleExtra,
        'lat': _lat,
        'lng': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).catchError((_) {}),
    );

    if (mounted) {
      setState(() {
        _seconds = 0;
        _alertaActiva = true;
        _estadoNube = '✅ Alerta SOS publicada en el Banner y Sirena activada';
      });
    }
  }

  void _sincronizarCambiosEnVivo() {
    if (!_alertaActiva || _publishedBannerId == null) return;
    final detalleExtra = _detalleCtrl.text.trim();
    final amenazaCompleta =
        detalleExtra.isNotEmpty ? '$_amenaza ($detalleExtra)' : _amenaza;
    final textoBanner =
        '🆘 SOS PELIGRO ($_ciudadReal): $amenazaCompleta • $_vehiculoReal [$_placaReal]';

    unawaited(
      BannerDinamico.publicarLocal(
        id: _publishedBannerId!,
        texto: textoBanner,
        color: const Color(0xFF8E0000),
        icono: Icons.notifications_active,
        tipo: 'emergencia',
      ),
    );

    if (_sosDocId != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(_sosDocId)
            .update({
              'amenaza': amenazaCompleta,
              'detalle': detalleExtra,
              'actualizadaEn': FieldValue.serverTimestamp(),
            })
            .catchError((_) {}),
      );
    }

    if (mounted) {
      setState(() => _estadoNube = '✅ Alerta SOS actualizada en el Banner');
    }
  }

  Future<void> _cancelarYDesactivar() async {
    _timer?.cancel();
    if (_publishedBannerId != null) {
      unawaited(BannerDinamico.quitarLocal(_publishedBannerId!));
      unawaited(EmergencyAlertStore.dismissAlert(_publishedBannerId!));
    }
    if (_sosDocId != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(_sosDocId)
            .update({'activa': false, 'cerradaEn': FieldValue.serverTimestamp()})
            .catchError((_) {}),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _enviarWhatsAppContacto(Map contacto) async {
    final fullPhone =
        (contacto['fullPhone'] ?? contacto['phone'] ?? '').toString();
    final digits = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final nombre = (contacto['name'] ?? 'Contacto').toString();
    final msg = Uri.encodeComponent(
      '🆘 *EMERGENCIA S.O.S. AUTO — ESTOY EN PELIGRO* 🆘\n'
      'Hola $nombre, soy *$_propietarioReal*. Activé una alerta:\n'
      '• *Situación:* $_amenaza\n'
      '• *Vehículo:* $_vehiculoReal (Placa *$_placaReal*)\n'
      '• *Ubicación GPS:* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$msg');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detalleCtrl.dispose();
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
              Icon(
                _alertaActiva ? Icons.notifications_active : Icons.timer,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                _alertaActiva
                    ? '¡ALERTA SOS ACTIVA EN BANNER!'
                    : 'Tienes $_seconds s para cancelar antes de publicar en el banner...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _estadoNube,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
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
                    value: 'Me están agrediendo',
                    child: Text('Me están agrediendo'),
                  ),
                  DropdownMenuItem(
                    value: 'Me están amenazando',
                    child: Text('Me están amenazando'),
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
                  if (v != null && v != _amenaza) {
                    setState(() => _amenaza = v);
                    _sincronizarCambiosEnVivo();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detalleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onSubmitted: (_) => _sincronizarCambiosEnVivo(),
                decoration: InputDecoration(
                  hintText: 'Detalle rápido opcional...',
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black26,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: _alertaActiva
                      ? IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.amberAccent,
                          ),
                          onPressed: _sincronizarCambiosEnVivo,
                        )
                      : null,
                ),
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
                  child: Text(
                    _alertaActiva
                        ? 'DESACTIVAR ALERTA Y QUITAR DEL BANNER'
                        : 'CANCELAR ANTES DE ENVIAR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
