import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vehicle_session.dart';

class MeVareScreen extends StatefulWidget {
  const MeVareScreen({super.key});

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  String _selectedIssue = 'Batería descargada / No enciende';
  final TextEditingController _referenceController = TextEditingController();
  bool _alertSent = false;

  String get _registeredPlate =>
      VehicleSession.hasVehicle ? VehicleSession.plate : 'SIN PLACA';

  String get _registeredVehicle => VehicleSession.hasVehicle
      ? '${VehicleSession.vehicleType} ${VehicleSession.brand} ${VehicleSession.model} ${VehicleSession.color}'.trim()
      : 'Registra tu vehículo en el botón Registro';

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

  final List<dynamic> _nearbyAllies = [
    {
      'name': 'Royman — Auxilio Mecánico y Desvare',
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
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _callOrWhatsApp(String phone, {bool whatsapp = false}) async {
    final String msg = Uri.encodeComponent(
      'Hola, necesito asistencia vial desde S.O.S. Auto.\n'
      'Vehículo: $_registeredVehicle (Placa: $_registeredPlate)\n'
      'Falla: $_selectedIssue\n'
      'Referencia: ${_referenceController.text.isEmpty ? "Ubicación GPS actual" : _referenceController.text}',
    );
    final Uri uri = whatsapp
        ? Uri.parse('https://wa.me/$phone?text=$msg')
        : Uri.parse('tel:+$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendAlert() {
    setState(() {
      _alertSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        content: Text(
          'Alerta de varada enviada para $_registeredPlate ($_selectedIssue) a aliados y contactos.',
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
                    const Icon(Icons.directions_car, color: Color(0xFFFBC02D), size: 32),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        Icon(Icons.health_and_safety, color: Color(0xFFE65100), size: 20),
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
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    '✓ Ubicación GPS y ficha de varada compartidas. Acuerda el precio directamente con el aliado sin intermediarios.',
                    style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                ally['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ally['distance'] as String,
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
                          ally['category'] as String,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                ),
                                onPressed: () => _callOrWhatsApp(ally['phone'] as String),
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
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                ),
                                onPressed: () =>
                                    _callOrWhatsApp(ally['phone'] as String, whatsapp: true),
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
