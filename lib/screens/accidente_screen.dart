import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vehicle_session.dart';

class AccidenteScreen extends StatefulWidget {
  const AccidenteScreen({super.key});

  @override
  State createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State {
  String _severity = 'Solo daños materiales (Choque leve)';
  bool _needAmbulance = false;
  final TextEditingController _otherPlateController = TextEditingController();

  String get _myPlate =>
      VehicleSession.hasVehicle ? VehicleSession.plate : 'SIN PLACA';

  String get _myVehicle => VehicleSession.hasVehicle
      ? '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.model} ${VehicleSession.color}'.trim()
      : 'Vehículo no registrado aún';

  bool _countingDown = false;
  int _secondsLeft = 5;
  bool _alertActive = false;
  Timer? _timer;

  final List _severities = [
    'Solo daños materiales (Choque leve)',
    'Daños materiales graves (Vehículo inmovilizado)',
    'Accidente con personas lesionadas',
    'Accidente grave con víctimas fatales',
  ];

  final Map _protocols = {
    'Solo daños materiales (Choque leve)':
        '1. Enciende estacionarias y toma fotos panorámicas de placas, posición de vehículos y señales antes de moverlos.\n2. En Colombia (Ley 2251), si no hay heridos y los autos pueden moverse, retíralos a un lado tras tomar evidencia para evitar comparendo por obstrucción.\n3. Intercambia datos de SOAT y licencia.',
    'Daños materiales graves (Vehículo inmovilizado)':
        '1. Asegura la zona con triángulos a 30 m y mantente fuera de la calzada.\n2. Reporta a Tránsito y a tu aseguradora para inspección en sitio.\n3. Solicita grúa cama baja (plataforma) para no dañar la transmisión.',
    'Accidente con personas lesionadas':
        '1. NO muevas a los heridos salvo riesgo de incendio o explosión.\n2. Llama de inmediato a emergencias (123) y solicita ambulancia prioritaria.\n3. Mantén inmovilizados los vehículos hasta que llegue la autoridad de tránsito.',
    'Accidente grave con víctimas fatales':
        '1. No alteres la escena ni muevas los vehículos.\n2. Contacta de inmediato a Policía Judicial / Tránsito (123) y a un abogado penalista de tránsito.\n3. Guarda copia de videos y testigos presenciales.',
  };

  @override
  void dispose() {
    _timer?.cancel();
    _otherPlateController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countingDown = true;
      _secondsLeft = 5;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft == 5 || _secondsLeft == 4 || _secondsLeft == 3 || _secondsLeft == 2) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        setState(() {
          _countingDown = false;
          _alertActive = true;
        });
      }
    });
  }

  void _cancelOrStopAlert() {
    _timer?.cancel();
    setState(() {
      _countingDown = false;
      _alertActive = false;
      _secondsLeft = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de accidente desactivada.'),
      ),
    );
  }

  Future _callEmergency(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        title: const Text(
          'Reportar Accidente',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehículo propio cargado automáticamente desde VehicleSession
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.car_crash, color: Color(0xFFFF5252), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu vehículo: $_myVehicle ($_myPlate)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Nivel del incidente:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField(
                value: _severity,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _severities.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _severity = val as String;
                      if (_severity.contains('lesionadas') || _severity.contains('fatales')) {
                        _needAmbulance = true;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Protocolo dinámico según gravedad
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_services, color: Color(0xFFB71C1C), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Primeros Auxilios y Protocolo Legal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _protocols[_severity] as String,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: SwitchListTile(
                  activeColor: const Color(0xFFC62828),
                  title: const Text(
                    'Solicitar ambulancia prioritaria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Notifica urgencia médica junto con tus coordenadas GPS',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _needAmbulance,
                  onChanged: (v) => setState(() => _needAmbulance = v),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _otherPlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Placa del otro vehículo involucrado (opcional)',
                  hintText: 'Ej: ABC-123',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              if (_countingDown) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enviando alerta en $_secondsLeft s...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB71C1C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _cancelOrStopAlert,
                          child: const Text(
                            'CANCELAR ENVÍO (SIN CLAVE)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_alertActive) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚨 ALERTA DE ACCIDENTE ENVIADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Contactos de emergencia notificados con GPS.\n'
                        '• Conductores S.O.S. Auto en un radio de 3 km alertados.\n'
                        '• Ambulancia prioritaria: ${_needAmbulance ? "SOLICITADA" : "No requerida"}.',
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          onPressed: _cancelOrStopAlert,
                          child: const Text('FINALIZAR / DESACTIVAR ALERTA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _startCountdown,
                    icon: const Icon(Icons.warning_amber_rounded, size: 22),
                    label: const Text(
                      'ACTIVAR ALERTA DE ACCIDENTE',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const Text(
                'Líneas Directas de Emergencia y Apoyo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _callEmergency('123'),
                      icon: const Icon(Icons.local_hospital, size: 18),
                      label: const Text('Línea 123 / Ambulancia', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF37474F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _callEmergency('#767'),
                      icon: const Icon(Icons.support_agent, size: 18),
                      label: const Text('Tránsito #767', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
