import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_notifier_service.dart';
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

  String get _registeredPlate =>
      VehicleSession.hasVehicle ? VehicleSession.plate.toUpperCase() : 'SIN PLACA';

  String get _registeredVehicle => VehicleSession.hasVehicle
      ? '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.model} ${VehicleSession.color}'
          .trim()
      : 'Registra tu vehículo en el botón Registro';

  String get _city =>
      VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Sincelejo';

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación GPS actual ($_city)';

  final List<String> _issues = [
    'Batería descargada / No enciende',
    'Llanta pinchada / Estallada',
    'Sin combustible / Gasolina',
    'Recalentamiento del motor',
    'Falla mecánica / Eléctrica',
    'Falla en frenos o dirección',
    'Llaves dentro del vehículo (Cerrajería)',
    'Necesito grúa / Remolque urgente',
  ];

  final Map<String, String> _safetyTips = {
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

  final List> _nearbyAllies = [
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
    _cargarContactosYGps();
  }

  Future<void> _cargarContactosYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        if (mounted) {
          setState(() {
            _contactosEmergencia = d['emergencyContacts'] as List? ?? [];
          });
        }
      } else if (VehicleSession.emergencyContactPhone.isNotEmpty && mounted) {
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
    } catch (_) {}

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

  Future<void> _callOrWhatsApp(String phone, {bool whatsapp = false}) async {
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

  Future<void> _sendAlert() async {
    setState(() {
      _alertSent = true;
    });

    final ref = _referenceController.text.trim();
    final detalleCompleto =
        'Falla: $_selectedIssue • Vehículo: $_registeredVehicle ($_registeredPlate)'
        '${ref.isNotEmpty ? ' • Ref: $ref' : ''} • GPS: $_gpsTxt';

    // 1. Notificar a soporte.applay65@gmail.com
    AdminNotifierService.notificarCorreo(
      modulo: 'Me Varé (Asistencia Vial)',
      titulo: '$_selectedIssue ($_registeredPlate)',
      detalle: detalleCompleto,
      placa: _registeredPlate,
      ciudad: _city,
      mapsUrl: _mapsUrl,
    );

    // 2. Guardar registro en Firestore
    try {
      await FirebaseFirestore.instance.collection('asistencias_viales').doc().set({
        'placa': _registeredPlate,
        'vehiculo': _registeredVehicle,
        'falla': _selectedIssue,
        'referencia': ref,
        'ciudad': _city,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        content: Text(
          'Alerta de varada enviada para $_registeredPlate ($_selectedIssue) a soporte y nube.',
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
                            VehicleSession.hasVehicle
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
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
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
                      _safetyTips[_selectedIssue] ?? '',
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
                    'REGISTRAR VARADA Y AVISAR A SOPORTE',
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
                    '✓ Ficha de varada enviada a soporte.applay65@gmail.com y guardada en la nube. Selecciona abajo un aliado o contacto para abrir WhatsApp directo:',
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
              ..._nearbyAllies.map((ally) {
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
                                ally['name']!,
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
                                ally['distance']!,
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
                          ally['category']!,
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
                                onPressed: () =>
                                    _callOrWhatsApp(ally['phone']!),
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
                                onPressed: () => _callOrWhatsApp(ally['phone']!,
                                    whatsapp: true),
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
