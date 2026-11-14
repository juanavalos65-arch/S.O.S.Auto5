import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreakdownProvider {
  final String name;
  final String serviceType;
  final String distance;
  final String phone;
  final String status;

  const BreakdownProvider({
    required this.name,
    required this.serviceType,
    required this.distance,
    required this.phone,
    required this.status,
  });
}

class MeVareScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  final double? currentLat;
  final double? currentLng;

  const MeVareScreen({
    super.key,
    this.registrationData,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  String _selectedIssue = 'Falla mecánica / Motor';
  final List<String> _issues = [
    'Falla mecánica / Motor',
    'Batería descargada (Paso de corriente)',
    'Llanta pinchada / Repuesto',
    'Sin combustible',
    'Llaves dentro del vehículo',
    'Necesito servicio de grúa',
  ];

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // Estado de alerta y cuenta regresiva de 5 segundos
  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _alertSent = false;

  // Aliados de ejemplo cercanos (se alimentarán dinámicamente por GPS)
  final List<BreakdownProvider> _nearbyProviders = const [
    BreakdownProvider(
      name: 'Grúas y Asistencia Vial 24/7',
      serviceType: 'Grúa plataforma y planchón',
      distance: '1.4 km',
      phone: '3001112233',
      status: 'Disponible ahora',
    ),
    BreakdownProvider(
      name: 'Serviteca y Baterías Express',
      serviceType: 'Paso de corriente, baterías y montallantas',
      distance: '2.1 km',
      phone: '3114445566',
      status: 'Disponible ahora',
    ),
    BreakdownProvider(
      name: 'Taller Mecánico Automotriz El Punto',
      serviceType: 'Mecánica rápida y diagnóstico en sitio',
      distance: '3.0 km',
      phone: '3207778899',
      status: 'Disponible ahora',
    ),
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startEmergencyCountdown() {
    if (_isCountingDown || _alertSent) return;

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
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        _dispatchBreakdownAlert();
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
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Cancelar Alerta Me Varé')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu PIN de seguridad (4 dígitos) para confirmar que fue un toque accidental:',
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
            child: const Text('Continuar alerta'),
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
                    content: Text('Alerta "Me Varé" cancelada correctamente.'),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un PIN válido de 4 dígitos.'),
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

  void _dispatchBreakdownAlert() {
    setState(() {
      _isCountingDown = false;
      _alertSent = true;
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

    final String contactNames = contacts.isNotEmpty
        ? contacts.map((c) => '${c['name']} (${c['phone']})').join(' y ')
        : 'Tus 2 contactos de emergencia configurados';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Reporte "Me Varé" Enviado')),
          ],
        ),
        content: Text(
          'Se ha enviado tu ubicación GPS y estado del vehículo automáticamente:\n\n'
          '• Vehículo / Placa: $plate\n'
          '• Conductor: $driverName\n'
          '• Motivo: $_selectedIssue\n'
          '• Ubicación GPS: $mapsLink\n'
          '• Notificados: $contactNames\n\n'
          'Recuerda mantener las luces estacionarias encendidas y permanecer en un lugar seguro fuera de la vía.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ver Aliados Cercanos'),
          ),
        ],
      ),
    );
  }

  void _copyProviderPhone(BreakdownProvider provider) {
    Clipboard.setData(ClipboardData(text: provider.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Teléfono de ${provider.name} (${provider.phone}) copiado para llamar o escribir por WhatsApp.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Varé - Asistencia Vial'),
        backgroundColor: Colors.amber.shade800,
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
              // 1. PROTOCOLO DE SEGURIDAD VIAL INMEDIATA (PREVENCIÓN)
              // ========================================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '¡Tu seguridad es primero! Sigue estas indicaciones:',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSafetyTip(
                      Icons.local_parking,
                      'Orilla el vehículo: En lo posible, detente fuera de la calzada, en la berma o en una zona segura e iluminada.',
                    ),
                    _buildSafetyTip(
                      Icons.highlight,
                      'Luces estacionarias: Enciende de inmediato las luces intermitentes de parqueo.',
                    ),
                    _buildSafetyTip(
                      Icons.change_history,
                      'Conos de advertencia: Ubica los triángulos o conos reflectivos detrás del vehículo a distancia segura (mínimo 30 m en ciudad y 50–100 m en carretera).',
                    ),
                    _buildSafetyTip(
                      Icons.visibility,
                      'Mantente alerta: Usa tu chaleco reflectivo, permanece fuera de la vía lejos del flujo vehicular y atento a tu entorno.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ========================================================
              // 2. SELECCIÓN DE FALLA Y ENVÍO A CONTACTOS DE EMERGENCIA
              // ========================================================
              const Text(
                '¿Qué le ocurrió al vehículo?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIssue,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.build_circle_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _issues
                    .map((issue) => DropdownMenuItem(
                          value: issue,
                          child: Text(issue),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedIssue = val);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Punto de referencia (opcional)',
                  hintText: 'Ej: Frente a estación de servicio, km 12...',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de alerta con cuenta regresiva de 5 segundos
              if (_isCountingDown) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enviando ubicación GPS a tus 2 contactos en $_countdownSeconds s...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.red.shade800,
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
                  onPressed: _startEmergencyCountdown,
                  icon: Icon(
                    _alertSent ? Icons.check_circle : Icons.sos,
                    color: Colors.white,
                  ),
                  label: Text(
                    _alertSent
                        ? 'UBICACIÓN ENVIADA A TUS 2 CONTACTOS'
                        : 'ENVIAR ALERTA Y GPS A MIS 2 CONTACTOS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _alertSent
                        ? Colors.green.shade700
                        : Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const Divider(height: 32, thickness: 1),

              // ========================================================
              // 3. ALIADOS CERCANOS (SIN INTERMEDIACIÓN DE PAGOS)
              // ========================================================
              const Text(
                'Aliados de Asistencia Cercanos',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Contacta y acuerda el servicio directamente con el prestador. S.O.S. Auto no cobra comisiones ni intermedia pagos.',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              ..._nearbyProviders.map((provider) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(
                        Icons.car_repair,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    title: Text(
                      provider.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${provider.serviceType}\nDistancia: ${provider.distance} • ${provider.status}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.phone_in_talk, color: Colors.green),
                      tooltip: 'Copiar teléfono / WhatsApp',
                      onPressed: () => _copyProviderPhone(provider),
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

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.amber.shade900),
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
