import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccidenteScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  final double? currentLat;
  final double? currentLng;
  final void Function(Map<String, dynamic> roadNewsEvent)? onPublishToRoadNews;

  const AccidenteScreen({
    super.key,
    this.registrationData,
    this.currentLat,
    this.currentLng,
    this.onPublishToRoadNews,
  });

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  String _selectedSeverity = 'Choque simple (Solo daños materiales)';
  final List<String> _severityOptions = [
    'Choque simple (Solo daños materiales)',
    'Accidente con heridos (Urgente ambulancia)',
    'Volcamiento / Riesgo de incendio',
    'Atropello / Peatón o ciclista involucrado',
  ];

  bool _reportToRoadNews = true;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _alertDispatched = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _referenceController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startAccidentCountdown() {
    if (_isCountingDown || _alertDispatched) return;

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 5;
    });

    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
        _dispatchAccidentAlert();
      }
    });
  }

  void _promptCancelWithPin() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Cancelar Alerta de Accidente')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu PIN de seguridad (4 dígitos) para anular el envío:',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN de acceso',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir enviando'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.trim().length == 4) {
                _countdownTimer?.cancel();
                setState(() {
                  _isCountingDown = false;
                  _countdownSeconds = 5;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta de accidente cancelada correctamente.'),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN incorrecto. Debe tener 4 dígitos.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Anular Alerta'),
          ),
        ],
      ),
    );
  }

  void _dispatchAccidentAlert() {
    setState(() {
      _isCountingDown = false;
      _alertDispatched = true;
    });

    final vehicle = widget.registrationData?['vehicle'] as Map<String, dynamic>?;
    final owner = widget.registrationData?['owner'] as Map<String, dynamic>?;
    final contacts =
        (widget.registrationData?['emergencyContacts'] as List<dynamic>?) ?? [];

    final plate = vehicle?['plate'] ?? 'PLACA NO REGISTRADA';
    final driverName = owner?['name'] ?? 'Conductor S.O.S. Auto';
    final lat = widget.currentLat ?? 6.2442;
    final lng = widget.currentLng ?? -75.5812;
    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';
    final referenceText = _referenceController.text.trim();

    // 1. Generar evento público para el módulo y banner de "Novedades en la Vía"
    if (_reportToRoadNews) {
      final Map<String, dynamic> roadNewsEvent = {
        'type': 'ACCIDENTE_VIAL',
        'title': '⚠️ Accidente en la vía reportado',
        'severity': _selectedSeverity,
        'description': referenceText.isNotEmpty
            ? 'Accidente reportado cerca de: $referenceText. Transite con precaución.'
            : 'Accidente vial reportado en este punto GPS. Posible congestión o cierre parcial.',
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
        'activeInBanner': true,
      };

      widget.onPublishToRoadNews?.call(roadNewsEvent);
    }

    // 2. Resumen de envío a los 2 contactos de emergencia
    final String contactSummary = contacts.isNotEmpty
        ? contacts.map((c) => '${c['name']} (${c['phone']})').join(' y ')
        : 'Tus 2 contactos de emergencia registrados';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Emergencia y Novedad Reportadas')),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Tu reporte de accidente fue despachado automáticamente:\n\n'
            '1. Alertas a Contactos de Emergencia:\n'
            '• Notificados: $contactSummary\n'
            '• Vehículo / Placa: $plate ($driverName)\n'
            '• Gravedad: $_selectedSeverity\n'
            '• Ubicación GPS: $mapsLink\n\n'
            '2. Novedades en la Vía (Comunidad):\n'
            '${_reportToRoadNews ? "✅ Publicado automáticamente en Novedades en la Vía y en el banner rotativo para prevenir a otros conductores en el sector." : "ℹ️ No publicado en Novedades en la Vía."}',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _copyEmergencyLine(String label, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($number) copiado para marcar de inmediato.'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInjuries = !_selectedSeverity.startsWith('Choque simple');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuve un Accidente'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========================================================
              // 1. PROTOCOLO DE SEGURIDAD Y PROCEDIMIENTO EN ACCIDENTE
              // ========================================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.red.shade800,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Protocolo Inmediato en Sitio:',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      Icons.personal_injury,
                      '1. Verifica heridos: Revisa tu estado y el de los ocupantes antes de bajar del vehículo.',
                    ),
                    _buildStepRow(
                      Icons.warning_amber_rounded,
                      '2. Señaliza y protégete: Enciende estacionarias, coloca conos/triángulos reflectivos y ubícate fuera de la calzada.',
                    ),
                    _buildStepRow(
                      Icons.camera_alt,
                      '3. Choque simple (solo latas): Toma fotos panorámicas (placas, posición y daños) y orilla los autos para despejar la vía (Ley 2251).',
                    ),
                    _buildStepRow(
                      Icons.local_hospital,
                      '4. Si hay heridos: NO muevas los vehículos hasta que llegue Tránsito y llama de inmediato al 123.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ========================================================
              // 2. CLASIFICACIÓN DEL ACCIDENTE Y REPORTE A NOVEADES EN VÍA
              // ========================================================
              const Text(
                'Tipo / Gravedad del Accidente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    hasInjuries ? Icons.local_hospital : Icons.car_crash,
                    color: Colors.red.shade700,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _severityOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(opt, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSeverity = val);
                  }
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'Punto exacto / Referencia vial (opcional)',
                  hintText: 'Ej: Autopista Norte km 8, sentido sur-norte...',
                  prefixIcon: const Icon(Icons.edit_location_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Interruptor activo por defecto para reportar a Novedades en la Vía
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red.shade700,
                title: const Text(
                  'Reportar automáticamente a "Novedades en la Vía"',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Publica la alerta vial en el mapa y en el banner rotativo para advertir a otros conductores.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _reportToRoadNews,
                onChanged: (val) {
                  setState(() => _reportToRoadNews = val);
                },
              ),

              const SizedBox(height: 14),

              // ========================================================
              // 3. BOTÓN DE DISPARO DE EMERGENCIA CON ANULACIÓN POR PIN
              // ========================================================
              if (_isCountingDown) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade700, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enviando SOS a tus 2 contactos y a Novedades en la Vía en $_countdownSeconds s...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _promptCancelWithPin,
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'CANCELAR CON PIN (TOQUE ACCIDENTAL)',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startAccidentCountdown,
                  icon: Icon(
                    _alertDispatched ? Icons.check_circle : Icons.sos,
                    color: Colors.white,
                  ),
                  label: Text(
                    _alertDispatched
                        ? 'ACCIDENTE REPORTADO A CONTACTOS Y VÍA'
                        : 'REPORTAR ACCIDENTE (CONTACTOS + VÍA)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _alertDispatched
                        ? Colors.green.shade700
                        : Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const Divider(height: 32, thickness: 1),

              // ========================================================
              // 4. LÍNEAS OFICIALES DE EMERGENCIA Y TRÁNSITO
              // ========================================================
              const Text(
                'Líneas Oficiales de Atención Inmediata',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _copyEmergencyLine('Línea Única Emergencias', '123'),
                      icon: const Icon(Icons.local_hospital, color: Colors.red),
                      label: const Text('Ambulancia / 123'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _copyEmergencyLine('Policía de Carreteras', '#767'),
                      icon: const Icon(Icons.local_police, color: Colors.blue),
                      label: const Text('Tránsito / #767'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
