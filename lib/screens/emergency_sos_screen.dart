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
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
  String _estadoNube = 'Iniciando cuenta regresiva de seguridad (5s)...';

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
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        final v = d['vehicle'] as Map? ?? {};
        final o = d['owner'] as Map? ?? {};
        final l = d['location'] as Map? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ??
                    (VehicleSession.hasVehicle
                        ? VehicleSession.plate
                        : 'SIN PLACA'))
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
                    (VehicleSession.city.isNotEmpty
                        ? VehicleSession.city
                        : 'Colombia'))
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
      if (p == LocationPermission.always ||
          p == LocationPermission.whileInUse) {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && mounted) {
          setState(() {
            _lat = lastPos.latitude;
            _lng = lastPos.longitude;
            _gpsTxt =
                '${lastPos.latitude.toStringAsFixed(5)}, ${lastPos.longitude.toStringAsFixed(5)}';
          });
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));

        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _gpsTxt =
                '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });

          if (_alertaActiva && _sosDocId != null) {
            await FirebaseFirestore.instance
                .collection('emergencias_sos')
                .doc(_sosDocId)
                .update({
              'latitud': _lat,
              'longitud': _lng,
              'mapsUrl': _mapsUrl,
              'actualizadaEn': FieldValue.serverTimestamp(),
            });
          }
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

  Future<void> _activarAlertaReal() async {
    setState(() {
      _seconds = 0;
      _alertaActiva = true;
      _estadoNube = 'Transmitiendo alerta SOS en vivo a la red y banner...';
    });

    final detalleExtra = _detalleCtrl.text.trim();

    try {
      final ref = await FirebaseFirestore.instance
          .collection('emergencias_sos')
          .add({
        'placa': _placaReal,
        'vehiculo': _vehiculoReal,
        'propietario': _propietarioReal,
        'ciudad': _ciudadReal,
        'amenaza': _amenaza,
        'detalle': detalleExtra,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));

      _sosDocId = ref.id;
    } catch (e) {
      if (mounted) {
        setState(() {
          _estadoNube =
              '⚠️ Alerta local activa (sin respuesta de Firestore: $e)';
        });
      }
    }

    _publishedBannerId =
        'sos_${_sosDocId ?? '${_placaReal}_${DateTime.now().millisecondsSinceEpoch}'}';

    final tituloBanner = detalleExtra.isNotEmpty
        ? '$_amenaza ($detalleExtra) • $_vehiculoReal ($_placaReal)'
        : '$_amenaza • $_vehiculoReal ($_placaReal)';

    try {
      await BannerFeedService.publishAlert(
        id: _publishedBannerId!,
        category: 'emergency',
        tag: '🚨 EMERGENCIA SOS ACTIVA — $_ciudadReal',
        title: tituloBanner,
        city: _ciudadReal,
        plate: _placaReal,
      );

      if (mounted) {
        setState(() {
          _estadoNube = _sosDocId != null
              ? '✅ Alerta SOS activa en Banner y Nube (ID: $_sosDocId)'
              : '✅ Alerta SOS publicada en Banner en vivo';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estadoNube = '⚠️ Error publicando en Banner: $e';
        });
      }
    }
  }

  Future<void> _sincronizarCambiosEnVivo() async {
    if (!_alertaActiva) return;

    final detalleExtra = _detalleCtrl.text.trim();
    final tituloBanner = detalleExtra.isNotEmpty
        ? '$_amenaza ($detalleExtra) • $_vehiculoReal ($_placaReal)'
        : '$_amenaza • $_vehiculoReal ($_placaReal)';

    try {
      if (_sosDocId != null) {
        await FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(_sosDocId)
            .update({
          'amenaza': _amenaza,
          'detalle': detalleExtra,
          'actualizadaEn': FieldValue.serverTimestamp(),
        });
      }

      if (_publishedBannerId != null) {
        await BannerFeedService.publishAlert(
          id: _publishedBannerId!,
          category: 'emergency',
          tag: '🚨 EMERGENCIA SOS ACTIVA — $_ciudadReal',
          title: tituloBanner,
          city: _ciudadReal,
          plate: _placaReal,
        );
      }

      if (mounted) {
        setState(() {
          _estadoNube = '✅ Alerta y Banner actualizados en vivo';
        });
      }
    } catch (_) {}
  }

  Future<void> _cancelarYDesactivar() async {
    _timer?.cancel();

    try {
      if (_publishedBannerId != null) {
        await BannerFeedService.deactivateAlert(_publishedBannerId!);
      }
      if (_sosDocId != null) {
        await FirebaseFirestore.instance
            .collection('emergencias_sos')
            .doc(_sosDocId)
            .update({
          'activa': false,
          'cerradaEn': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _enviarWhatsAppContacto(Map contacto) async {
    final fullPhone =
        (contacto['fullPhone'] ?? contacto['phone'] ?? '').toString();
    final digits = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final nombre = (contacto['name'] ?? 'Contacto').toString();
    final detalleExtra = _detalleCtrl.text.trim();
    final lineaDetalle =
        detalleExtra.isNotEmpty ? '\n• *Detalle:* $detalleExtra' : '';

    final msg = Uri.encodeComponent(
      '🆘 *EMERGENCIA S.O.S. AUTO — ESTOY EN PELIGRO* 🆘\n'
      'Hola $nombre, soy *$_propietarioReal*. Activé una alerta de emergencia:\n'
      '• *Situación:* $_amenaza$lineaDetalle\n'
      '• *Vehículo:* $_vehiculoReal (Placa *$_placaReal*)\n'
      '• *Mi ubicación GPS en vivo:* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$msg');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo abrir WhatsApp en este dispositivo.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WhatsApp no está disponible o bloqueado.')),
        );
      }
    }
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo abrir el marcador telefónico.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al intentar marcar al 123.')),
        );
      }
    }
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
              const SizedBox(height: 8),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sincronizarCambiosEnVivo(),
                decoration: InputDecoration(
                  hintText:
                      'Detalle rápido opcional (ej. moto negra 2 sujetos)...',
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
                          icon: const Icon(Icons.send,
                              color: Colors.amberAccent),
                          tooltip: 'Actualizar en banner',
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
