import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccidenteScreen extends StatefulWidget {
  const AccidenteScreen({super.key});

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  // Estados de alerta y cuenta regresiva (sin PIN)
  bool _isCountingDown = false;
  bool _alertSent = false;
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  // Clasificación de gravedad del accidente
  String _selectedSeverity = 'Choque leve';

  // Controladores de texto
  final TextEditingController _otherPlatesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

    // Bitácora del modo simulacro
  final _simulationLogs = <String>[];

  final List _severityLevels = [
    {
      'id': 'Choque leve',
      'title': 'Choque leve (solo daños menores)',
      'subtitle': 'Sin heridos, vehículos movilizables',
      'icon': Icons.car_crash_outlined,
      'color': Colors.amber,
    },
    {
      'id': 'Daños graves',
      'title': 'Daños graves al vehículo',
      'subtitle': 'Vehículo inmovilizado, requiere grúa',
      'icon': Icons.minor_crash,
      'color': Colors.deepOrange,
    },
    {
      'id': 'Personas lesionadas',
      'title': 'Personas lesionadas',
      'subtitle': 'Se requiere ambulancia y atención médica',
      'icon': Icons.medical_services,
      'color': Colors.red,
    },
    {
      'id': 'Con víctimas fatales',
      'title': 'Con víctimas fatales',
      'subtitle': 'Emergencia crítica - No mover escena',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFF8B0000),
    },
  ];

  final List _nearbyAllies = [
    {
      'name': 'Ambulancias Vital SOS 24/7',
      'category': 'Ambulancia',
      'distance': '1.2 km',
      'phone': '123',
    },
    {
      'name': 'Grúas Cama Baja El Rápido',
      'category': 'Grúa',
      'distance': '2.4 km',
      'phone': '+57 300 555 0192',
    },
    {
      'name': 'Asesoría Legal Vial & Tránsito',
      'category': 'Abogado de Tránsito',
      'distance': '3.1 km',
      'phone': '+57 311 555 0148',
    },
    {
      'name': 'Taller Colisión & Latonería Express',
      'category': 'Latonería',
      'distance': '3.8 km',
      'phone': '+57 315 555 0177',
    },
  ];

  }

  void _startEmergencyCountdown() {
    if (_isCountingDown || _alertSent) return;

    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _triggerSimulatedAlert();
      }
    });
  }

  void _cancelOrDeactivateAlert() {
    _countdownTimer?.cancel();
    final String timestamp = _formatCurrentTime();

    setState(() {
      if (_alertSent) {
        _simulationLogs.insert(
          0,
          '[$timestamp] Alerta de accidente DESACTIVADA por el conductor (sin PIN).',
        );
      }
      _isCountingDown = false;
      _alertSent = false;
      _secondsRemaining = 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de accidente desactivada.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _triggerSimulatedAlert() {
    final String timestamp = _formatCurrentTime();
    final String plates = _otherPlatesController.text.trim().isEmpty
        ? 'No reportadas'
        : _otherPlatesController.text.trim().toUpperCase();

    setState(() {
      _isCountingDown = false;
      _alertSent = true;
      _simulationLogs.clear();
      _simulationLogs.addAll(<String>[
        '[$timestamp] MODO SIMULACRO ACTIVO - Nivel: $_selectedSeverity',
        '[$timestamp] SMS/WhatsApp enviado a Contactos de Emergencia con ubicación GPS.',
        '[$timestamp] Despacho notificado a Línea 123 / Autoridades de Tránsito.',
        '[$timestamp] Alerta publicada en Banner Dinámico S.O.S. Auto (Placas invol.: $plates).',
        '[$timestamp] Notificación enviada a conductores S.O.S. Auto en un radio de 5 km.',
      ]);
    });
  }

  String _formatCurrentTime() {
    final DateTime now = DateTime.now();
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la llamada a $phone')),
        );
      }
    }
  }

  List<String> _getDynamicProtocol(String severity) {
    switch (severity) {
      case 'Choque leve':
        return <String>[
          'Enciende de inmediato las luces estacionarias y coloca los triángulos/conos a 30 metros.',
          'Toma fotos y video panorámico de ambos vehículos, placas, señalización y daños antes de moverlos.',
          'Si no hay heridos, despeja la vía siguiendo la normativa de choques simples (Ley 2251 en Colombia).',
          'Intercambia datos básicos con el otro conductor y contacta a tu aseguradora.',
        ];
      case 'Daños graves':
        return <String>[
          'Verifica que ningún ocupante tenga dolor en cuello, espalda o golpes internos.',
          'Desconecta el encendido del vehículo si percibes olor a gasolina o humo en el motor.',
          'NO muevas el vehículo si compromete la investigación del croquis de tránsito; espera al agente.',
          'Solicita una grúa cama baja desde el directorio inferior para evitar daños en la transmisión.',
        ];
      case 'Personas lesionadas':
        return <String>[
          'PRIMEROS AUXILIOS: No muevas a los heridos ni retires cascos (si hay motociclistas) salvo riesgo de incendio.',
          'Mantén a los lesionados abrigados, conscientes y en calma mientras llega la ambulancia.',
          'Si hay sangrado visible, aplica presión directa con un paño limpio sin retirar gasas empapadas.',
          'No abandones el lugar del siniestro: retirarte puede constituir delito de omisión de socorro.',
        ];
      case 'Con víctimas fatales':
        return <String>[
          'PROTOCOLO CRÍTICO: No muevas vehículos, objetos ni cuerpos; la escena queda bajo custodia judicial.',
          'Asegura el perímetro para evitar un segundo atropello o colisión en cadena.',
          'Comunícate de inmediato con la Línea 123 / Policía Judicial de Tránsito y un abogado penal/vial.',
          'Mantén la calma y brinda únicamente información objetiva a las autoridades al llegar.',
        ];
      default:
        return <String>[];
    }
  }

  Widget _buildEmergencyControlCard() {
    Color cardColor = Colors.red.shade700;
    String title = 'ACTIVAR ALERTA DE ACCIDENTE';
    String subtitle = 'Cuenta regresiva de 5s antes de notificar emergencia';
    IconData icon = Icons.emergency_share;

    if (_isCountingDown) {
      cardColor = Colors.orange.shade800;
      title = 'ENVIANDO EN $_secondsRemaining SEGUNDOS...';
      subtitle = 'Toca cancelar si presionaste por error (sin PIN)';
      icon = Icons.timer;
    } else if (_alertSent) {
      cardColor = const Color(0xFF8B0000);
      title = '¡ALERTA DE ACCIDENTE ACTIVA!';
      subtitle = 'Bitácora de emergencia generada y contactos alertados';
      icon = Icons.notifications_active;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 46),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (!_isCountingDown && !_alertSent)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                ),
                onPressed: _startEmergencyCountdown,
                icon: const Icon(Icons.sos),
                label: const Text(
                  'ACTIVAR ALERTA AHORA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                onPressed: _cancelOrDeactivateAlert,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(
                  _isCountingDown
                      ? 'CANCELAR CUENTA REGRESIVA'
                      : 'DESACTIVAR ALERTA (SIN PIN)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimulationInspectorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.greenAccent.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Bitácora de Notificaciones (Simulacro)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          ..._simulationLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                log,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentProtocol = _getDynamicProtocol(_selectedSeverity);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reporte de Accidente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.science_outlined, color: Colors.deepOrange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo Simulacro Activo: Las alertas registran bitácora de prueba sin saturar líneas reales.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildEmergencyControlCard(),
            const SizedBox(height: 16),

            if (_simulationLogs.isNotEmpty) ...<Widget>[
              _buildSimulationInspectorCard(),
              const SizedBox(height: 16),
            ],

            const Text(
              '1. Clasifica la gravedad del accidente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._severityLevels.map((Map<String, dynamic> item) {
              final String id = item['id'] as String;
              final bool isSelected = _selectedSeverity == id;
              final Color itemColor = item['color'] as Color;

              return Card(
                elevation: isSelected ? 3 : 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? itemColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: itemColor.withValues(alpha: 0.15),
                    child: Icon(item['icon'] as IconData, color: itemColor),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? itemColor : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSeverity = id;
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 14),
            const Text(
              '2. Datos adicionales del siniestro (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otherPlatesController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa(s) de otros vehículos involucrados',
                hintText: 'Ej. ABC123, XYZ987',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción breve o punto de referencia',
                hintText: 'Ej. Av. Principal frente a estación de servicio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '3. Protocolo recomendado ($_selectedSeverity)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: currentProtocol.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              '4. Aliados cercanos y líneas de apoyo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._nearbyAllies.map((ally) {
              final phone = ally['phone'] ?? '123';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.support_agent, color: Color(0xFF0D47A1)),
                  ),
                  title: Text(
                    ally['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${ally['category']} • A ${ally['distance']} (Acuerdo directo sin comisiones)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () => _callPhone(phone),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
