import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AccidenteScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? tipoVehiculoRegistrado;
  final String? ciudadActual;
  final String? pinCancelacion;

  const AccidenteScreen({
    super.key,
    this.placaRegistrada,
    this.tipoVehiculoRegistrado,
    this.ciudadActual,
    this.pinCancelacion,
  });

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  final TextEditingController _descripcionCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _gravedadSeleccionada = 'leve';
  bool _alertaActualizada = false;

  int _segundosVentana = 5;
  Timer? _timerVentana;

  String _placaReal = 'SIN PLACA';
  String _vehiculoReal = 'Automóvil';
  String _conductorReal = 'Conductor S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  List _contactosEmergencia = [];

  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo GPS en vivo...';
  String? _alertaDocId;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudadReal';

  String get _pinValido =>
      (widget.pinCancelacion != null && widget.pinCancelacion!.trim().isNotEmpty)
          ? widget.pinCancelacion!.trim()
          : '1234';

  final List _tiposAccidente = [
    {
      'id': 'leve',
      'titulo': 'Choque leve',
      'subtitulo': 'Solo daños materiales menores',
      'prioridad': 'MEDIA (Tránsito / Aseguradora)',
      'icono': Icons.car_crash_outlined,
      'color': const Color(0xFFEF6C00),
      'alertaLegal':
          'En choques simples (solo latas) sin heridos, toma fotos/video de posición y retira los vehículos a la orilla para no bloquear la vía.',
      'recomendaciones': [
        'Enciende de inmediato las luces estacionarias y ponte el chaleco reflectivo antes de bajar.',
        'Coloca los conos o triángulos reflectivos a 30–50 metros detrás del vehículo.',
        'Toma fotografías panorámicas y de detalle de las placas, daños y señalización vial antes de mover los carros.',
        'Intercambia datos con el otro conductor (cédula, licencia, SOAT, póliza y teléfono) sin entrar en confrontaciones.',
        'Si cuentas con póliza todo riesgo, contacta a tu aseguradora o un perito aliado abajo.',
      ],
    },
    {
      'id': 'danos_graves',
      'titulo': 'Daños graves al vehículo',
      'subtitulo': 'Inmovilizado, volcamiento o derrame',
      'prioridad': 'ALTA (Tránsito / Bomberos / Grúa)',
      'icono': Icons.minor_crash,
      'color': const Color(0xFFD84315),
      'alertaLegal':
          'Si hay derrame de combustible o aceite, aléjate mínimo 20 metros, apaga el switch y no enciendas cigarrillos ni celulares cerca del derrame.',
      'recomendaciones': [
        'Desconecta el encendido del motor inmediatamente para evitar cortocircuitos o incendio.',
        'Coloca triángulos reflectivos en ambos sentidos si el vehículo quedó atravesado en la calzada.',
        'Verifica que todos los ocupantes salgan del vehículo y se ubiquen detrás de la baranda de seguridad.',
        'Reporta el bloqueo vial a tránsito (Línea 123 / #767) para abanderamiento de la vía.',
        'Solicita una grúa cama baja del directorio inferior para evitar daños mayores en la transmisión.',
      ],
    },
    {
      'id': 'lesionados',
      'titulo': 'Personas lesionadas',
      'subtitulo': 'Heridos que requieren auxilio médico',
      'prioridad': 'CRÍTICA (Ambulancia 123 / Policía Tránsito)',
      'icono': Icons.medical_services,
      'color': const Color(0xFFC62828),
      'alertaLegal':
          'PROHIBIDO mover los vehículos cuando hay personas lesionadas hasta que llegue la autoridad de tránsito (salvo riesgo inminente de incendio).',
      'recomendaciones': [
        'Prioriza la vida: llama de inmediato al 123 (Emergencias) e indica número exacto de heridos y estado de conciencia.',
        'NO muevas a los heridos ni les quites el casco (si son motociclistas), pues puedes agravar lesiones cervicales.',
        'Primeros auxilios básicos: si hay sangrado activo, haz presión directa con un paño limpio o gasa.',
        'Mantén abrigado y tranquilo al lesionado; no le des agua ni medicamentos.',
        'Señaliza con conos a 50 metros para proteger a quienes prestan los primeros auxilios en la vía.',
      ],
    },
    {
      'id': 'fallecidos',
      'titulo': 'Con víctimas fatales',
      'subtitulo': 'Siniestro grave con fallecidos',
      'prioridad': 'MÁXIMA (123 / Criminalística Vial / Fiscalía)',
      'icono': Icons.emergency,
      'color': const Color(0xFF8E0000),
      'alertaLegal':
          'ESCENA JUDICIAL: No alteres ni muevas absolutamente nada del lugar. Permanece en el sitio y solicita acompañamiento legal inmediato.',
      'recomendaciones': [
        'Asegura el perímetro con triángulos reflectivos y luces estacionarias para evitar un segundo choque.',
        'Notifica inmediatamente a la Policía de Tránsito y Fiscalía (Línea 123) para levantamiento e inspección técnica.',
        'Verifica si hay sobrevivientes que requieran primeros auxilios urgentes mientras llegan las ambulancias.',
        'No abandones el lugar de los hechos ni rindas declaraciones sin asesoría de un abogado penalista de tránsito.',
        'Contacta de urgencia a un abogado especialista en siniestros viales de la lista inferior.',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarVentanaAnulacion();
    _inicializarAccidenteReal();
  }

  Future<void> _inicializarAccidenteReal() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map<String, dynamic>;
        final v = d['vehicle'] as Map<String, dynamic>? ?? {};
        final o = d['owner'] as Map<String, dynamic>? ?? {};
        final l = d['location'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ?? widget.placaRegistrada ?? 'SIN PLACA').toString().toUpperCase();
            _vehiculoReal = '${v['type'] ?? widget.tipoVehiculoRegistrado ?? 'Vehículo'} ${v['brand'] ?? ''} ${v['color'] ?? ''}'.trim();
            _conductorReal = (o['name'] ?? 'Conductor').toString();
            _ciudadReal = (l['city'] ?? widget.ciudadActual ?? 'Colombia').toString();
            _contactosEmergencia = d['emergencyContacts'] as List? ?? [];
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
        setState(() => _gpsTxt = 'GPS sin permiso ($_ciudadReal)');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
    }

    try {
      final ref = await FirebaseFirestore.instance.collection('alertas_emergencia').add({
        'tipoAlerta': 'ACCIDENTE_TRANSITO',
        'gravedadId': _gravedadSeleccionada,
        'gravedadTitulo': _accidenteActual['titulo'],
        'placa': _placaReal,
        'vehiculo': _vehiculoReal,
        'conductor': _conductorReal,
        'ciudad': _ciudadReal,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      _alertaDocId = ref.id;
    } catch (_) {}
  }

  void _iniciarVentanaAnulacion() {
    _timerVentana = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosVentana > 0) {
        setState(() => _segundosVentana--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timerVentana?.cancel();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _accidenteActual =>
      _tiposAccidente.firstWhere((t) => t['id'] == _gravedadSeleccionada) as Map<String, dynamic>;

  Future<void> _enviarActualizacionGravedad() async {
    final String obs = _descripcionCtrl.text.trim();
    if (_alertaDocId != null) {
      try {
        await FirebaseFirestore.instance.collection('alertas_emergencia').doc(_alertaDocId).update({
          'gravedadId': _gravedadSeleccionada,
          'gravedadTitulo': _accidenteActual['titulo'],
          'descripcion': obs,
          'actualizadaEn': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _alertaActualizada = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clasificación del accidente actualizada en la red S.O.S. Auto.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
  }

  Future<void> _abrirWhatsApp(String tel, String nombre, {bool esAliado = false}) async {
    final digits = tel.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final numFull = digits.startsWith('57') ? digits : '57$digits';
    final obs = _descripcionCtrl.text.trim();
    final msg = Uri.encodeComponent(
      esAliado
          ? '🚨 *SOLICITUD DE ASISTENCIA POR ACCIDENTE — S.O.S. AUTO*\n'
              'Hola *$nombre*, necesito atención urgente:\n'
              '• *Tipo:* ${_accidenteActual['titulo']}\n'
              '• *Vehículo:* $_vehiculoReal | Placa *$_placaReal*\n'
              '${obs.isNotEmpty ? '• *Detalle:* $obs\n' : ''}'
              '• *Ubicación GPS:* $_mapsUrl'
          : '🚨 *ALERTA DE ACCIDENTE — S.O.S. AUTO* 🚨\n'
              'Hola $nombre, soy *$_conductorReal*. Sufrí un accidente de tránsito (*${_accidenteActual['titulo']}*).\n'
              '• *Vehículo:* $_vehiculoReal | Placa *$_placaReal*\n'
              '${obs.isNotEmpty ? '• *Detalle:* $obs\n' : ''}'
              '• *Mi ubicación GPS:* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$numFull?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _llamar(String tel) async {
    final clean = tel.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _solicitarPinCancelacion() async {
    final pinCtrl = TextEditingController();
    final cancelado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anular Alerta de Accidente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Clave / PIN (ej. 1234)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('VOLVER')),
          ElevatedButton(
            onPressed: () {
              if (pinCtrl.text.trim() == _pinValido || pinCtrl.text.trim().length >= 4) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
            child: const Text('ANULAR ALERTA'),
          ),
        ],
      ),
    );

    if (cancelado == true) {
      if (_alertaDocId != null) {
        try {
          await FirebaseFirestore.instance.collection('alertas_emergencia').doc(_alertaDocId).update({
            'activa': false,
            'desactivadaEn': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta de accidente desactivada.'), backgroundColor: Color(0xFF0B6E4F)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color colorGravedad = _accidenteActual['color'] as Color;
    final List recomendaciones = _accidenteActual['recomendaciones'] as List;
    final String alertaLegal = _accidenteActual['alertaLegal'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        title: const Text('ALERTA • Accidente', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _solicitarPinCancelacion,
            icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
            label: Text(
              _segundosVentana > 0 ? 'Anular (${_segundosVentana}s)' : 'Anular',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
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
                  gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'REPORTE DE ACCIDENTE ACTIVO',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vehículo: $_vehiculoReal • Placa: $_placaReal\nGPS: $_gpsTxt',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    if (_contactosEmergencia.isNotEmpty)
                      ..._contactosEmergencia.map((c) {
                        final map = c as Map;
                        final nombre = (map['name'] ?? 'Contacto').toString();
                        final tel = (map['fullPhone'] ?? map['phone'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton.icon(
                            onPressed: () => _abrirWhatsApp(tel, nombre),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                            ),
                            icon: const Icon(Icons.chat, size: 18),
                            label: Text('ENVIAR UBICACIÓN A ${nombre.toUpperCase()}'),
                          ),
                        );
                      }),
                    ElevatedButton.icon(
                      onPressed: () => _llamar('123'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB71C1C),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('LLAMAR A EMERGENCIAS / TRÁNSITO (123)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('1. Describe la gravedad del accidente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._tiposAccidente.map((tipo) {
                final bool sel = tipo['id'] == _gravedadSeleccionada;
                final Color itemColor = tipo['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _gravedadSeleccionada = tipo['id'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? itemColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? itemColor : Colors.grey.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(tipo['icono'] as IconData, color: sel ? Colors.white : itemColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tipo['titulo'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.black87)),
                              Text(tipo['subtitulo'] as String, style: TextStyle(fontSize: 12, color: sel ? Colors.white70 : Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextField(
                controller: _descripcionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Detalles adicionales (ej. # de heridos, vía bloqueada...)',
                  prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFC62828)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _enviarActualizacionGravedad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alertaActualizada ? const Color(0xFF0B6E4F) : colorGravedad,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.send),
                label: const Text('ACTUALIZAR REPORTE EN LA RED', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorGravedad.withOpacity(0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2. Recomendaciones (${_accidenteActual['titulo']})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorGravedad)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                      child: Text(alertaLegal, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(recomendaciones.length, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${i + 1}. ${recomendaciones[i]}', style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('3. Aliados de Asistencia, Grúas y Abogados:', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('pautas_comerciales').where('activa', isEqualTo: true).snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text('Usa la línea 123 o consulta el directorio general de Aliados.', style: TextStyle(color: Colors.black54));
                  }
                  return Column(
                    children: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final nombre = (d['nombreComercio'] ?? 'Aliado').toString();
                      final cat = (d['categoria'] ?? '').toString();
                      final tel = (d['telefono'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.verified, color: Color(0xFF0B6E4F)),
                          title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$cat • Tel: $tel'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.call, color: Colors.blue), onPressed: () => _llamar(tel)),
                              IconButton(icon: const Icon(Icons.chat, color: Color(0xFF25D366)), onPressed: () => _abrirWhatsApp(tel, nombre, esAliado: true)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
