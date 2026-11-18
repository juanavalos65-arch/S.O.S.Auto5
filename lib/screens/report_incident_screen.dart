import 'package:flutter/material.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String _selectedType = 'Vía cerrada / Obra / Derrumbe';
  String _severity = 'Paso restringido (1 carril)';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final List _incidentTypes = [
    'Vía cerrada / Obra / Derrumbe',
    'Congestión vehicular fuerte',
    'Inundación / Árbol caído',
    'Hueco peligroso / Mancha de aceite',
    'Accidente en la vía (Tráfico lento)',
    'Puesto de control / Retén',
    'Cámara de fotodetección / Radar',
    'Manifestación / Bloqueo vial',
  ];

  final List _severities = [
    'Precaución leve (Tránsito fluido)',
    'Paso restringido (1 carril)',
    'Cierre total de la vía (Tomar desvío)',
  ];

  final List _activeReports = [
    {
      'type': 'Vía cerrada / Obra / Derrumbe',
      'location': 'Av. Regional — Altura Puente Horacio Toro',
      'severity': 'Paso restringido (1 carril)',
      'time': 'Hace 12 min',
      'confirmations': 7,
      'cleared': false,
    },
    {
      'type': 'Hueco peligroso / Mancha de aceite',
      'location': 'Autopista Sur — Carril izquierdo sentido Norte',
      'severity': 'Precaución leve (Tránsito fluido)',
      'time': 'Hace 28 min',
      'confirmations': 4,
      'cleared': false,
    },
    {
      'type': 'Inundación / Árbol caído',
      'location': 'Vía Las Palmas — Km 5',
      'severity': 'Cierre total de la vía (Tomar desvío)',
      'time': 'Hace 45 min',
      'confirmations': 11,
      'cleared': false,
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _publishIncident() {
    final String loc = _locationController.text.trim().isEmpty
        ? 'Ubicación GPS actual'
        : _locationController.text.trim();

    setState(() {
      _activeReports.insert(0, {
        'type': _selectedType,
        'location': loc,
        'severity': _severity,
        'time': 'Justo ahora',
        'confirmations': 1,
        'cleared': false,
      });
      _locationController.clear();
      _detailsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        content: Text(
          'Novedad publicada en el banner rotativo y mapa: $_selectedType ($loc).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF57C00),
          foregroundColor: Colors.white,
          title: const Text(
            'Novedades en la Vía',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_alert), text: 'Reportar novedad'),
              Tab(icon: Icon(Icons.list_alt), text: 'Conocer novedades'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // PESTAÑA 1: REPORTAR NOVEDAD
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de novedad vial:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField(
                      value: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _incidentTypes.map((item) {
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
                          setState(() => _selectedType = val as String);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Estado del paso vehicular:',
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
                          setState(() => _severity = val as String);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Sector, vía o kilómetro (opcional)',
                        hintText: 'Ej: Calle 30 con Carrera 46, sentido Oriente...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _detailsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Detalle adicional para otros conductores',
                        hintText: 'Ej: Tomar vía alterna por el puente...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _publishIncident,
                        icon: const Icon(Icons.campaign, size: 22),
                        label: const Text(
                          'PUBLICAR EN BANNER Y MAPA',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PESTAÑA 2: CONOCER NOVEDADES
              ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _activeReports.length,
                itemBuilder: (context, index) {
                  final item = _activeReports[index];
                  final bool isCleared = item['cleared'] as bool;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCleared ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: isCleared ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['type'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Text(
                                item['time'] as String,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '📍 ${item['location']}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCleared
                                ? 'Estado: Vía despejada reportada por la comunidad'
                                : 'Estado: ${item['severity']} (${item['confirmations']} confirmaciones)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCleared ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isCleared
                                      ? null
                                      : () {
                                          setState(() {
                                            item['confirmations'] =
                                                (item['confirmations'] as int) + 1;
                                          });
                                        },
                                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                                  label: const Text('Sigue activa', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: isCleared
                                      ? null
                                      : () {
                                          setState(() {
                                            item['cleared'] = true;
                                          });
                                        },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Vía despejada', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
