import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class _LegalGuide {
  final String norma;
  final String directriz;
  final String defensa;

  const _LegalGuide({
    required this.norma,
    required this.directriz,
    required this.defensa,
  });
}

class _SponsoredLawyer {
  final String nombre;
  final String especialidad;
  final String ciudad;
  final String telefono;
  final String badge;

  const _SponsoredLawyer({
    required this.nombre,
    required this.especialidad,
    required this.ciudad,
    required this.telefono,
    required this.badge,
  });
}

class TrafficStopScreen extends StatefulWidget {
  const TrafficStopScreen({super.key});

  @override
  State<TrafficStopScreen> createState() => _TrafficStopScreenState();
}

class _TrafficStopScreenState extends State<TrafficStopScreen> {
  String _selectedReason = 'Puesto de control / Retén';

  final Map<String, _LegalGuide> _legalGuides = const {
    'Puesto de control / Retén': _LegalGuide(
      norma:
          'Ley 769 de 2002 (Arts. 7, 134, 135) y Resolución Mintransporte 20223040045295 de 2022.',
      directriz:
          '• Todo puesto de control debe estar debidamente señalizado con conos, vallas visibles e iluminación nocturna, y contar con orden de servicio vigente.\n'
          '• Los agentes deben portar uniforme reglamentario, placa de identificación visible y chaleco reflectivo.\n'
          '• Grabar el procedimiento es un derecho ciudadano protegido constitucionalmente (actividad pública); ningún agente puede decomisar tu celular ni prohibir la grabación.',
      defensa:
          'Si el retén carece de señalización reglamentaria o el agente no se identifica, deja constancia en video (enfocando el entorno vial y la placa) para solicitar nulidad en audiencia de cargos y descargos.',
    ),
    'Revisión de documentos (SOAT / RTM / Licencia)': _LegalGuide(
      norma:
          'Ley 769 de 2002 (Arts. 30, 42, 50) y Circular Mintransporte sobre consulta en línea en el RUNT.',
      directriz:
          '• Puedes presentar tu licencia de conducción, SOAT y Revisión Técnico-Mecánica en formato digital o mediante consulta directa en la plataforma oficial del RUNT.\n'
          '• Si la falla es subsanable en el sitio (ej. luces o equipo de prevención), tienes derecho al tiempo prudencial establecido antes de ordenar grúa.',
      defensa:
          'Graba la consulta en el RUNT con fecha y hora en pantalla. Si el agente impone comparendo pese a estar vigentes en el sistema, solicita audiencia de impugnación dentro de los 5 días hábiles siguientes.',
    ),
    'Prueba de embriaguez / Alcoholemia': _LegalGuide(
      norma:
          'Ley 1696 de 2013 y Resolución Medicina Legal 1844 de 2015 (Guía para medición indirecta de alcoholemia).',
      directriz:
          '• Antes de soplar, el operador debe garantizarte plenitud de garantías: informar alcance de la prueba, mostrar boquilla nueva sellada y certificado de calibración vigente del alcohosensor.\n'
          '• Deben transcurrir al menos 15 minutos desde la última ingesta o vómito antes de la medición.',
      defensa:
          'Graba todo el protocolo previo y la pantalla del equipo. La omisión de las garantías previas o calibración vencida invalida la sanción en audiencia.',
    ),
    'Inmovilización / Grúa': _LegalGuide(
      norma:
          'Ley 769 de 2002 (Art. 125) y Manual de Infracciones de Tránsito.',
      directriz:
          '• Si el conductor o propietario está presente antes de que la grúa enganche e inicie marcha (en infracciones como mal parqueo C02), solo procede el comparendo, NO la inmovilización.\n'
          '• Exige inventario detallado del estado del vehículo antes de subirlo a la plataforma.',
      defensa:
          'Toma fotos y video 360° del vehículo (carrocería, llantas, interior y kilometraje) y del enganche de la grúa antes del traslado.',
    ),
    'Otro comparendo en vía': _LegalGuide(
      norma:
          'Ley 769 de 2002 (Arts. 135 y 136, modificado por Ley 1383 de 2010 y Ley 1843 de 2017).',
      directriz:
          '• Firmar la orden de comparendo NO significa aceptar la culpa; solo certifica que fuiste notificado.\n'
          '• Puedes exigir que en la casilla de "Observaciones" el agente consigne tu versión o dejar constancia de tu inconformidad.',
      defensa:
          'Tienes 5 días hábiles siguientes a la notificación para comparecer ante el organismo de tránsito y solicitar formalmente audiencia pública de cargos y descargos.',
    ),
  };

  final List<_SponsoredLawyer> _sponsoredLawyers = const [
    _SponsoredLawyer(
      nombre: 'Defensa Vial Colombia - Abogados Especialistas',
      especialidad: 'Impugnación de comparendos, fotomultas y audiencias',
      ciudad: 'Atención Nacional / Medellín y Costa Caribe',
      telefono: '573116479280',
      badge: 'ALIADO PAUTANTE DESTACADO',
    ),
    _SponsoredLawyer(
      nombre: 'Jurídica Tránsito & Transporte S.A.S.',
      especialidad: 'Nulidad de procedimientos, alcoholemia e inmovilizaciones',
      ciudad: 'Asesoría Virtual Inmediata 24/7',
      telefono: '573116479280',
      badge: 'ALIADO VERIFICADO',
    ),
  ];

  Future<void> _contactLawyerWhatsApp(
      String lawyerName, String phone, String reason) async {
    final String text = Uri.encodeComponent(
      'Hola $lawyerName, vengo de la app S.O.S. Auto. '
      'Me acaba de detener un agente de tránsito por motivo: "$reason". '
      'Necesito asesoría legal para el procedimiento y eventual audiencia de cargos y descargos.',
    );
    final Uri uri = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callLawyer(String phone) async {
    final Uri telUri = Uri.parse('tel:+$phone');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _LegalGuide currentGuide = _legalGuides[_selectedReason]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGENTE DE TRÁNSITO'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Colors.black87),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PROTOCOLO INMEDIATO DE PROTECCIÓN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. NO discutas ni confrontes verbalmente al agente.\n'
                    '2. Activa la cámara de tu celular y graba todo el procedimiento con voz clara.\n'
                    '3. Toma fotos nítidas del rostro de los agentes, el número de placa/chaleco y la patrulla o motocicleta.\n'
                    '4. Pregunta con respeto: "¿Cuál es el motivo exacto de la detención y el código de la infracción?"',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Indica el motivo de la detención:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _legalGuides.keys
                  .map(
                    (reason) => DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReason = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CÓDIGO DE TRÁNSITO Y DIRECTRICES VIGENTES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Base Legal: ${currentGuide.norma}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentGuide.directriz,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cómo defenderte / Audiencia de Cargos y Descargos:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentGuide.defensa,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Abogados de Tránsito Pautantes (Asesoría Inmediata)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Contacta un abogado aliado para revisar tu caso o representarte en audiencia:',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ..._sponsoredLawyers.map(
              (lawyer) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lawyer.badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lawyer.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lawyer.especialidad,
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        lawyer.ciudad,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _contactLawyerWhatsApp(
                                lawyer.nombre,
                                lawyer.telefono,
                                _selectedReason,
                              ),
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callLawyer(lawyer.telefono),
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Llamar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
