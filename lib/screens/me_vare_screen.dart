import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MeVareScreen extends StatefulWidget {
  const MeVareScreen({super.key});

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  final _storage = const FlutterSecureStorage();
  final _detalleCtrl = TextEditingController();

  String _falla = 'Grúa / Remolque';
  final List _tiposFalla = [
    'Grúa / Remolque',
    'Batería / Paso de corriente',
    'Llanta pinchada / Montallantas',
    'Falla mecánica o eléctrica',
    'Sin combustible / Cerrajería',
  ];

  String _placa = 'SIN PLACA';
  String _vehiculo = 'Automóvil';
  String _conductor = 'Conductor S.O.S. Auto';
  String _ciudad = 'Colombia';
  List _contactos = [];

  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo GPS...';
  bool _enviando = false;
  bool _solicitudActiva = false;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudad';

  @override
  void initState() {
    super.initState();
    _cargarDatosYGps();
  }

  Future<void> _cargarDatosYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map<String, dynamic>;
        final v = d['vehicle'] as Map<String, dynamic>? ?? {};
        final o = d['owner'] as Map<String, dynamic>? ?? {};
        final l = d['location'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _placa = (v['plate'] ?? 'SIN PLACA').toString().toUpperCase();
            _vehiculo = '${v['type'] ?? 'Vehículo'} ${v['brand'] ?? ''} ${v['color'] ?? ''}'.trim();
            _conductor = (o['name'] ?? 'Conductor').toString();
            _ciudad = (l['city'] ?? 'Colombia').toString();
            _contactos = d['emergencyContacts'] as List? ?? [];
          });
        }
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _gpsTxt = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _gpsTxt = 'GPS sin permiso ($_ciudad)');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = 'Ubicación: $_ciudad');
    }
  }

  @override
  void dispose() {
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarAuxilio() async {
    if (_enviando) return;
    setState(() => _enviando = true);

    try {
      await FirebaseFirestore.instance.collection('solicitudes_asistencia').add({
        'tipo': 'ME_VARE',
        'falla': _falla,
        'detalle': _detalleCtrl.text.trim(),
        'placa': _placa,
        'vehiculo': _vehiculo,
        'conductor': _conductor,
        'ciudad': _ciudad,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      setState(() => _solicitudActiva = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud de desvare publicada! Elige un aliado abajo o avisa por WhatsApp.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar solicitud: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirWhatsApp(String telefono, String destinatario, {bool esAliado = true}) async {
    final digits = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final numFull = digits.startsWith('57') ? digits : '57$digits';
    final extra = _detalleCtrl.text.trim();
    final msg = Uri.encodeComponent(
      esAliado
          ? '🔧 *SOLICITUD DE AUXILIO S.O.S. AUTO (ME VARÉ)*\n'
              'Hola *$destinatario*, necesito asistencia:\n'
              '• *Servicio:* $_falla\n'
              '• *Vehículo:* $_vehiculo | Placa *$_placa*\n'
              '${extra.isNotEmpty ? '• *Detalle:* $extra\n' : ''}'
              '• *Mi ubicación GPS:* $_mapsUrl'
          : '🚗 *AVISO S.O.S. AUTO — ME VARÉ EN LA VÍA*\n'
              'Hola $destinatario, soy *$_conductor*. Mi vehículo ($_vehiculo, placa *$_placa*) sufrió una varada (*$_falla*).\n'
              '• *Mi ubicación GPS:* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$numFull?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _llamar(String tel) async {
    final clean = tel.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Varé — Asistencia Vial'),
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF6C00)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehículo: $_vehiculo • Placa: $_placa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('GPS: $_gpsTxt', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _falla,
                decoration: InputDecoration(
                  labelText: '¿Qué tipo de varada tienes? *',
                  prefixIcon: const Icon(Icons.car_repair),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _tiposFalla.map((f) => DropdownMenuItem<String>(value: f.toString(), child: Text(f.toString()))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _falla = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detalleCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Detalle o referencia de ubicación (opcional)',
                  hintText: 'Ej: Autopista Norte frente a estación, carro no enciende...',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _enviando ? null : _solicitarAuxilio,
                icon: const Icon(Icons.sos, color: Colors.white),
                label: Text(
                  _solicitudActiva ? 'SOLICITUD ACTIVA EN LA RED' : 'PUBLICAR SOLICITUD DE AUXILIO',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _solicitudActiva ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_contactos.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Avisar a mis contactos de emergencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ..._contactos.map((c) {
                  final map = c as Map;
                  final nombre = (map['name'] ?? 'Contacto').toString();
                  final tel = (map['fullPhone'] ?? map['phone'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirWhatsApp(tel, nombre, esAliado: false),
                      icon: const Icon(Icons.chat, color: Color(0xFF2E7D32)),
                      label: Text('Enviar GPS por WhatsApp a $nombre'),
                    ),
                  );
                }),
              ],
              const Divider(height: 28),
              const Text('Aliados Disponibles (Grúas, Talleres y Montallantas):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pautas_comerciales').where('activa', isEqualTo: true).snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text('No hay aliados pautados activos todavía en tu zona.', style: TextStyle(color: Colors.black54));
                  }
                  return Column(
                    children: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final nombre = (d['nombreComercio'] ?? 'Aliado').toString();
                      final cat = (d['categoria'] ?? '').toString();
                      final ciudad = (d['ciudad'] ?? '').toString();
                      final tel = (d['telefono'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 30),
                          title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$cat • $ciudad\nTel: $tel'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.call, color: Colors.blue), onPressed: () => _llamar(tel)),
                              IconButton(icon: const Icon(Icons.chat, color: Color(0xFF25D366)), onPressed: () => _abrirWhatsApp(tel, nombre)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
