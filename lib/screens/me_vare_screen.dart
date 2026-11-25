import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vehicle_session.dart';

class MeVareScreen extends StatefulWidget {
  const MeVareScreen({super.key});

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _selectedIssue = 'Batería descargada / No enciende';
  final TextEditingController _referenceController = TextEditingController();
  bool _alertSent = false;

  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo GPS...';
  List _contactosEmergencia = [];

  String _plate = '';
  String _vehicleType = '';
  String _brand = '';
  String _model = '';
  String _color = '';
  String _cityStored = '';

  bool get _hasVehicleData =>
      _plate.trim().isNotEmpty || VehicleSession.hasVehicle;

  String get _registeredPlate {
    if (_plate.trim().isNotEmpty) return _plate.trim().toUpperCase();
    if (VehicleSession.plate.trim().isNotEmpty) {
      return VehicleSession.plate.trim().toUpperCase();
    }
    return 'SIN PLACA';
  }

  String get _registeredVehicle {
    final type = _vehicleType.isNotEmpty ? _vehicleType : VehicleSession.vehicleType;
    final brand = _brand.isNotEmpty ? _brand : VehicleSession.brand;
    final model = _model.isNotEmpty ? _model : VehicleSession.model;
    final color = _color.isNotEmpty ? _color : VehicleSession.color;

    final full = '$type $brand $model $color'.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (full.isNotEmpty) return full;
    return _hasVehicleData
        ? 'Vehículo registrado'
        : 'Registra tu vehículo en el botón Registro';
  }

  String get _city {
    if (_cityStored.trim().isNotEmpty) return _cityStored.trim();
    if (VehicleSession.city.trim().isNotEmpty) return VehicleSession.city.trim();
    return 'Sincelejo';
  }

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación GPS actual ($_city)';

  final List _issues = [
    'Batería descargada / No enciende',
    'Llanta pinchada / Estallada',
    'Sin combustible / Gasolina',
    'Recalentamiento del motor',
    'Falla mecánica / Eléctrica',
    'Falla en frenos o dirección',
    'Llaves dentro del vehículo (Cerrajería)',
    'Necesito grúa / Remolque urgente',
  ];

  final Map _safetyTips = {
    'Batería descargada / No enciende':
        '1. Enciende luces estacionarias y ubica el triángulo a 30 m.\n2. No insistas dando arranque más de 5 segundos seguidos.\n3. Verifica que los bornes no estén sulfatados o sueltos antes de pasar corriente.',
    'Llanta pinchada / Estallada':
        '1. Oríllate en zona plana y firme fuera del flujo vehicular.\n2. Pon freno de mano, estacionarias y chaleco reflectivo.\n3. Afloja los pernos ligeramente antes de subir el gato.',
    'Sin combustible / Gasolina':
        '1. Estaciona en berma segura con estacionarias encendidas.\n2. Evita dar arranque en vacío para no dañar la bomba de gasolina.\n3. Solicita suministro seguro a un aliado cercano.',
    'Recalentamiento del motor':
        '1. Apaga el aire acondicionado y detén el motor de inmediato.\n2. NUNCA abras la tapa del radiador en caliente (riesgo grave de quemadura).\n3. Espera al menos 25 minutos antes de revisar el nivel de refrigerante.',
    'Falla mecánica / Eléctrica':
        '1. Mantén las luces de parqueo activas y permanece dentro del vehículo con cinturón si estás en vía rápida.\n2. Comparte tu ubicación exacta con tu aliado o contacto de confianza.',
    'Falla en frenos o dirección':
        '1. No continúes la marcha bajo ninguna circunstancia.\n2. Usa freno de motor (baja marchas gradualmente) y freno de mano suave para detenerte.\n3. Solicita grúa cama baja.',
    'Llaves dentro del vehículo (Cerrajería)':
        '1. Verifica si alguna puerta trasera o baúl quedó sin seguro.\n2. No fuerces vidrios ni empaques; solicita cerrajero automotriz certificado.',
    'Necesito grúa / Remolque urgente':
        '1. Toma fotos del estado del vehículo antes de subirlo a la plataforma.\n2. Acuerda la tarifa directamente con el operador de grúa sin intermediarios.',
  };

  final List _nearbyAllies = [
    {
      'name': 'Royman Marín — Auxilio Mecánico y Desvare',
      'category': 'Mecánica rápida, desvare en vía y asistencia 24/7 (Sincelejo)',
      'distance': '1.1 km',
      'phone': '573107304782',
    },
    {
      'name': 'Neider Marín — Servicio Técnico Automotriz',
      'category': 'Diagnóstico mecánico, electricidad, baterías y desvare (Sincelejo)',
      'distance': '1.5 km',
      'phone': '573044670715',
    },
  ];

  @override
  void initState() {
    super.initState();
    _plate = VehicleSession.plate;
    _vehicleType = VehicleSession.vehicleType;
    _brand = VehicleSession.brand;
    _model = VehicleSession.model;
    _color = VehicleSession.color;
    _cityStored = VehicleSession.city;
    _cargarVehiculoContactosYGps();
  }

  Future _cargarVehiculoContactosYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        final plate = (d['plate'] ?? d['placa'] ?? '').toString();
        final type = (d['vehicleType'] ?? d['tipo'] ?? d['tipoVehiculo'] ?? '').toString();
        final brand = (d['brand'] ?? d['marca'] ?? '').toString();
        final model = (d['model'] ?? d['modelo'] ?? '').toString();
        final color = (d['color'] ?? '').toString();
        final city = (d['city'] ?? d['ciudad'] ?? '').toString();

        if (plate.isNotEmpty) VehicleSession.plate = plate;
        if (type.isNotEmpty) VehicleSession.vehicleType = type;
        if (brand.isNotEmpty) VehicleSession.brand = brand;
        if (model.isNotEmpty) VehicleSession.model = model;
        if (color.isNotEmpty) VehicleSession.color = color;
        if (city.isNotEmpty) VehicleSession.city = city;

        if (mounted) {
          setState(() {
            if (plate.isNotEmpty) _plate = plate;
            if (type.isNotEmpty) _vehicleType = type;
            if (brand.isNotEmpty) _brand = brand;
            if (model.isNotEmpty) _model = model;
            if (color.isNotEmpty) _color = color;
            if (city.isNotEmpty) _cityStored = city;
            _contactosEmergencia = (d['emergencyContacts'] as List?) ?? [];
          });
        }
      }
    } catch (_) {}

    if (!_hasVehicleData) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawPrefs = prefs.getString('sos_auto_registered_vehicle');
        if (rawPrefs != null && rawPrefs.isNotEmpty) {
          final d = jsonDecode(rawPrefs) as Map;
          if (mounted) {
            setState(() {
              _plate = (d['plate'] ?? d['placa'] ?? _plate).toString();
              _vehicleType = (d['vehicleType'] ?? d['tipo'] ?? _vehicleType).toString();
              _brand = (d['brand'] ?? d['marca'] ?? _brand).toString();
              _model = (d['model'] ?? d['modelo'] ?? _model).toString();
              _color = (d['color'] ?? _color).toString();
              _cityStored = (d['city'] ?? d['ciudad'] ?? _cityStored).toString();
            });
          }
        } else {
          final p = prefs.getString('placa') ?? prefs.getString('plate') ?? '';
          if (p.isNotEmpty && mounted) {
            setState(() {
              _plate = p;
              _vehicleType = prefs.getString('tipo_vehiculo') ?? prefs.getString('vehicleType') ?? '';
              _brand = prefs.getString('marca') ?? prefs.getString('brand') ?? '';
              _model = prefs.getString('modelo') ?? prefs.getString('model') ?? '';
              _color = prefs.getString('color') ?? '';
              _cityStored = prefs.getString('ciudad') ?? prefs.getString('city') ?? '';
            });
          }
        }
      } catch (_) {}
    }

    if (_contactosEmergencia.isEmpty &&
        VehicleSession.emergencyContactPhone.isNotEmpty &&
        mounted) {
      setState(() {
        _contactosEmergencia = [
          {
            'name': VehicleSession.emergencyContactName.isNotEmpty
                ? VehicleSession.emergencyContactName
                : 'Contacto de Emergencia',
            'fullPhone': VehicleSession.emergencyContactPhone,
          }
        ];
      });
    }

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always ||
          p == LocationPermission.whileInUse) {
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
        setState(() => _gpsTxt = _city);
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = _city);
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future _callOrWhatsApp(String phone, {bool whatsapp = false}) async {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10 && digits.startsWith('3')) {
      digits = '57$digits';
    }
    final ref = _referenceController.text.trim();
    final String msg = Uri.encodeComponent(
      '🔧 *SOLICITUD DE DESVARE — S.O.S. AUTO*\n'
      'Hola, necesito asistencia vial:\n'
      '• *Vehículo:* $_registeredVehicle (Placa: *$_registeredPlate*)\n'
      '• *Falla:* $_selectedIssue\n'
      '${ref.isNotEmpty ? '• *Referencia:* $ref\n' : ''}'
      '• *Ubicación GPS:* $_mapsUrl',
    );
    final Uri uri = whatsapp
        ? Uri.parse('https://wa.me/$digits?text=$msg')
        : Uri.parse('tel:+$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future _sendAlert() async {
    setState(() {
      _alertSent = true;
    });

    final ref = _referenceController.text.trim();

    unawaited(
      FirebaseFirestore.instance.collection('asistencias_viales').doc().set({
        'placa': _registeredPlate,
        'vehiculo': _registeredVehicle,
        'falla': _selectedIssue,
        'referencia': ref,
        'ciudad': _city,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'creadaEn': FieldValue.serverTimestamp(),
      }).catchError((_) {}),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        content: Text(
          'Alerta de varada lista para $_registeredPlate ($_selectedIssue). Elige un aliado o contacto abajo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
        title: const Text(
          'Me Varé — Asistencia Vial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: Color(0xFFFBC02D), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasVehicleData
                                ? 'VEHÍCULO REGISTRADO (CARGA AUTOMÁTICA)'
                                : 'VEHÍCULO NO REGISTRADO AÚN',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_registeredVehicle — Placa $_registeredPlate',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'GPS: $_gpsTxt',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Qué falla presenta tu vehículo?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIssue,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: _issues.map((item) {
                  final text = item.toString();
                  return DropdownMenuItem<String>(
                    value: text,
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedIssue = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety,
                            color: Color(0xFFE65100), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Protocolo de Seguridad y Diagnóstico',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_safetyTips[_selectedIssue] ?? '').toString(),
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _referenceController,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Punto de referencia (opcional)',
                  hintText: 'Ej: Frente a estación de servicio, carril derecho...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _sendAlert,
                  icon: const Icon(Icons.campaign, size: 22),
                  label: const Text(
                    'ENVIAR ALERTA A ALIADOS Y CONTACTOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_alertSent) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ Ubicación GPS y ficha de varada listas. Selecciona abajo un aliado o contacto para abrir WhatsApp directo (0% comisión):',
                    style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (_contactosEmergencia.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Avisar a Mis Contactos de Confianza',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._contactosEmergencia.map((c) {
                  final map = c as Map;
                  final nombre = (map['name'] ?? 'Contacto').toString();
                  final tel =
                      (map['fullPhone'] ?? map['phone'] ?? '').toString();
                  if (tel.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _callOrWhatsApp(tel, whatsapp: true),
                        icon: const Icon(Icons.chat, size: 18),
                        label: Text(
                          'ENVIAR UBICACIÓN DE VARADA A ${nombre.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              const Text(
                'Aliados Cercanos (Trato Directo — 0% Comisión)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._nearbyAllies.map((item) {
                final ally = item as Map;
                final allyName = (ally['name'] ?? '').toString();
                final allyCat = (ally['category'] ?? '').toString();
                final allyDist = (ally['distance'] ?? '').toString();
                final allyPhone = (ally['phone'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                allyName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                allyDist,
                                style: const TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          allyCat,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                ),
                                onPressed: () => _callOrWhatsApp(allyPhone),
                                icon: const Icon(Icons.phone, size: 18),
                                label: const Text(
                                  'Llamar',
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                ),
                                onPressed: () =>
                                    _callOrWhatsApp(allyPhone, whatsapp: true),
                                icon: const Icon(Icons.chat, size: 18),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'WhatsApp',
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
