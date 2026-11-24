import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_notifier_service.dart';
import '../services/vehicle_session.dart';

class TrafficStopScreen extends StatefulWidget {
  const TrafficStopScreen({super.key});

  @override
  State<TrafficStopScreen> createState() => _TrafficStopScreenState();
}

class _TrafficStopScreenState extends State<TrafficStopScreen> {
  String _selectedCountry = 'Colombia';
  String _selectedReason = 'Solicitud de documentos (Licencia, SOAT, Revisión)';
  final TextEditingController _badgeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _recordingActive = false;
  String? _videoPath;
  String _horaInicioBitacora = '';
  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo GPS...';

  String get _myPlate =>
      VehicleSession.hasVehicle ? VehicleSession.plate.toUpperCase() : 'SIN PLACA';

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación GPS no disponible';

  final List<String> _countries = [
    'Colombia',
    'México',
    'Perú',
    'Chile',
    'Ecuador',
    'Argentina',
    'Estados Unidos',
  ];

  final List<String> _reasons = [
    'Solicitud de documentos (Licencia, SOAT, Revisión)',
    'Orden de inmovilización o traslado en grúa',
    'Prueba de alcoholemia / Embriaguez',
    'Retén o puesto de control sin señalización',
    'Revisión o registro al interior del vehículo',
  ];

  final Map<String, String> _countryNorms = {
    'Colombia':
        '• Derecho a grabar: Art. 21 Ley 1801 de 2016 (Código Nacional de Policía). Ningún agente puede impedirte grabar ni decomisar tu celular.\n'
        '• Documentos digitales: Circular 20221010000601 del MinTransporte avala mostrar Licencia, SOAT y Tecnomecánica en línea desde el RUNT.\n'
        '• Subsanación antes de grúa: Art. 125 Ley 769. Si corriges la falta en el sitio (antes de enganchar), no procede la inmovilización.',
    'México':
        '• Identificación obligatoria: El agente debe portar nombre y placa visible e indicar el artículo exacto del Reglamento de Tránsito infringido.\n'
        '• Prohibición de retener documentos: Salvo infracciones graves tipificadas, no pueden retener licencia o placas como garantía informal.\n'
        '• Derecho a grabar el acto de autoridad en vía pública.',
    'Perú':
        '• Reglamento Nacional de Tránsito (D.S. 016-2009-MTC): El efectivo PNP debe identificarse y explicar la papeleta antes de solicitar documentos.\n'
        '• Puedes grabar el procedimiento policial en la vía pública sin obstruir la intervención.',
    'Chile':
        '• Ley de Tránsito 18.290: Carabineros puede fiscalizar licencia, permiso de circulación y SOAP.\n'
        '• El funcionario debe portar identificación visible y entregar copia del parte con citación al Juzgado de Policía Local.',
    'Ecuador':
        '• Ley Orgánica de Transporte Terrestre (LOTTTSV): El agente civil o vigilante debe portar credencial visible y explicar la contravención.\n'
        '• Tienes derecho a grabar el procedimiento y a impugnar la citación dentro de los 3 días hábiles siguientes.',
    'Argentina':
        '• Ley Nacional de Tránsito 24.449: Documentación exigible: DNI, licencia vigente, cédula verde/azul, comprobante de seguro y VTV.\n'
        '• El puesto de control debe estar debidamente señalizado con conos y personal identificado.',
    'Estados Unidos':
        '• Mantén ambas manos visibles sobre el volante y enciende la luz interior si es de noche.\n'
        '• Entrega licencia, registro y seguro cuando el oficial lo solicite. Tienes derecho a guardar silencio (5ta Enmienda) y a grabar sin interferir.',
  };

  final Map<String, String> _reasonGuidance = {
    'Solicitud de documentos (Licencia, SOAT, Revisión)':
        'Entrega o muestra en pantalla tus documentos vigentes con calma. No entregues llaves ni dinero.',
    'Orden de inmovilización o traslado en grúa':
        'Graba el inventario completo del vehículo (carrocería, llantas, interior) antes de que la grúa lo toque y exige copia firmada del inventario.',
    'Prueba de alcoholemia / Embriaguez':
        'Exige que la boquilla del alcoholímetro sea nueva, sellada y abierta frente a ti. Negarse a la prueba conlleva la sanción máxima.',
    'Retén o puesto de control sin señalización':
        'Graba el entorno mostrando la ausencia de conos, señales o patrulla identificada, y anota el número de placa del agente.',
    'Revisión o registro al interior del vehículo':
        'Tienes derecho a presenciar toda la inspección visual junto al funcionario y grabarla para evitar irregularidades.',
  };

  @override
  void initState() {
    super.initState();
    _obtenerGps();
  }

  Future<void> _obtenerGps() async {
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
        setState(() => _gpsTxt = 'Sin permiso de GPS');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = 'GPS no disponible');
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _activarYGrabarVideo() async {
    final hora = _horaActual();
    final badge = _badgeController.text.trim().isEmpty
        ? 'No registrada'
        : _badgeController.text.trim();

    setState(() {
      _recordingActive = true;
      _horaInicioBitacora = hora;
    });

    // 1. Notificar a soporte.applay65@gmail.com
    AdminNotifierService.notificarCorreo(
      modulo: 'Agente de Tránsito',
      titulo: 'Bitácora de procedimiento ($_myPlate)',
      detalle:
          'País: $_selectedCountry • Motivo: $_selectedReason • Agente/Patrulla: $badge • Hora: $hora • GPS: $_gpsTxt',
      placa: _myPlate,
      ciudad: _selectedCountry,
      mapsUrl: _mapsUrl,
    );

    // 2. Guardar respaldo en Firestore
    try {
      await FirebaseFirestore.instance
          .collection('procedimientos_transito')
          .doc()
          .set({
        'placa': _myPlate,
        'pais': _selectedCountry,
        'motivo': _selectedReason,
        'agentePlaca': badge,
        'horaInicio': hora,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}

    // 3. Abrir cámara de video nativa para grabar el procedimiento
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted) return;
      if (video != null) {
        setState(() {
          _videoPath = video.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B5E20),
            content: Text(
              '✅ Video del procedimiento guardado como evidencia en tu dispositivo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir la cámara de video: $e'),
        ),
      );
    }
  }

  Future<void> _shareLocationWithContact() async {
    final String badge = _badgeController.text.trim().isEmpty
        ? 'No registrada aún'
        : _badgeController.text.trim();
    final String msg = Uri.encodeComponent(
      '⚠️ *ALERTA DE PROCEDIMIENTO DE TRÁNSITO — S.O.S. AUTO*\n'
      '• *Vehículo:* $_myPlate\n'
      '• *País:* $_selectedCountry\n'
      '• *Motivo:* $_selectedReason\n'
      '• *Placa/Patrulla agente:* $badge\n'
      '• *Ubicación GPS:* $_mapsUrl\n'
      'Estoy grabando el procedimiento para respaldo legal.',
    );
    final Uri uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        title: const Text(
          'Procedimiento Agente de Tránsito',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                  color: _recordingActive
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF0A192F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _recordingActive
                              ? Icons.fiber_manual_record
                              : Icons.videocam,
                          color: _recordingActive
                              ? Colors.white
                              : const Color(0xFFFBC02D),
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _recordingActive
                                    ? 'BITÁCORA ACTIVA ($_horaInicioBitacora)'
                                    : 'Grabar Procedimiento en Video',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GPS: $_gpsTxt',
                                style: const TextStyle(
                                    color: Colors.amberAccent, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          activeColor: Colors.white,
                          value: _recordingActive,
                          onChanged: (v) {
                            if (v) {
                              _activarYGrabarVideo();
                            } else {
                              setState(() => _recordingActive = false);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB71C1C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _activarYGrabarVideo,
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: Text(
                          _videoPath != null
                              ? 'GRABAR OTRO VIDEO DE EVIDENCIA'
                              : 'ABRIR CÁMARA Y GRABAR PROCEDIMIENTO',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    if (_videoPath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb
                            ? '✓ Video capturado correctamente.'
                            : '✓ Evidencia guardada: ${File(_videoPath!).uri.pathSegments.last}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'País del procedimiento:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: _countries.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCountry = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Motivo de la detención:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: _reasons.map((item) {
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
                    setState(() => _selectedReason = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF9FA8DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield, color: Color(0xFF283593), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Recomendación Inmediata',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF283593),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _reasonGuidance[_selectedReason] ?? '',
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel,
                            color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tus Derechos y Normativa — $_selectedCountry',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _countryNorms[_selectedCountry] ?? '',
                      style: const TextStyle(
                          fontSize: 13, height: 1.45, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _badgeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Número de placa / chaleco o patrulla del agente',
                  hintText: 'Ej: Placa 04821 — Patrulla 12-45',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF283593),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _shareLocationWithContact,
                  icon: const Icon(Icons.share_location, size: 22),
                  label: const Text(
                    'COMPARTIR UBICACIÓN Y DATOS POR WHATSAPP',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
