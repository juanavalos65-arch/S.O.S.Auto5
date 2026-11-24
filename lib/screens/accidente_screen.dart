import 'dart:async';
import 'package:flutter/material.dart';

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
  final List<String> _simulationLogs = <String>[];

  final List> _severityLevels = >[
    <String, dynamic>{
      'id': 'Choque leve',
      'title': 'Choque leve (solo daños menores)',
      'subtitle': 'Sin heridos, vehículos movilizables',
      'icon': Icons.car_crash_outlined,
      'color': Colors.amber,
    },
    <String, dynamic>{
      'id': 'Daños graves',
      'title': 'Daños graves al vehículo',
      'subtitle': 'Vehículo inmovilizado, requiere grúa',
      'icon': Icons.minor_crash,
      'color': Colors.deepOrange,
    },
    <String, dynamic>{
      'id': 'Personas lesionadas',
      'title': 'Personas lesionadas',
      'subtitle': 'Se requiere ambulancia y atención médica',
      'icon': Icons.medical_services,
      'color': Colors.red,
    },
    <String, dynamic>{
      'id': 'Con víctimas fatales',
      'title': 'Con víctimas fatales',
      'subtitle': 'Emergencia crítica - No mover escena',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFF8B0000),
    },
  ];

  final List> _nearbyAllies = >[
    <String, String>{
      'name': 'Ambulancias Vital SOS 24/7',
      'category': 'Ambulancia',
      'distance': '1.2 km',
      'phone': '123',
    },
    <String, String>{
      'name': 'Grúas Cama Baja El Rápido',
      'category': 'Grúa',
      'distance': '2.4 km',
      'phone': '+57 300 555 0192',
    },
    <String, String>{
      'name': 'Asesoría Legal Vial & Tránsito',
      'category': 'Abogado de Tránsito',
      'distance': '3.1 km',
      'phone': '+57 311 555 0148',
    },
    <String, String>{
      'name': 'Taller Colisión & Latonería Express',
      'category': 'Latonería',
      'distance': '3.8 km',
      'phone': '+57 315 555 0177',
    },
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otherPlatesController.dispose();
    _detailsController.dispose();
    super.dispose();
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
        '[$timestamp] MODO SIMULACRO ACTIVO - Nivel:$_selectedSeverity',
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
            // Banner informativo de Modo Simulacro
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

            // Botón principal de emergencia / cuenta regresiva 5s / desactivar sin PIN
            _buildEmergencyControlCard(),
            const SizedBox(height: 16),

            // Inspector de eventos enviados (visible cuando la alerta está activa)
            if (_simulationLogs.isNotEmpty) ...<Widget>[
              _buildSimulationInspectorCard(),
              const SizedBox(height: 16),
            ],

            // Clasificación de gravedad
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
                    backgroundColor: itemColor.withOpacity(0.15),
                    child: Icon(item['icon'] as IconData, color: itemColor),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? itemColor : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      
