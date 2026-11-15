import 'package:flutter/material.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  /// Lista estática compartida con el banner dinámico de HomeScreen
  static final List> novedadesActivas = [
    {
      'tipo': 'Cierre vial',
      'titulo': 'Cierre parcial Av. Las Palmas km 4',
      'detalle': 'Paso a un carril por mantenimiento vial. Conduzca con precaución.',
      'ubicacion': 'Medellín, Antioquia',
      'hora': 'Hace 15 min',
    },
    {
      'tipo': 'Retén / Control',
      'titulo': 'Puesto de control preventivo',
      'detalle': 'Revisión de documentos en salida norte.',
      'ubicacion': 'Vía Troncal de Occidente',
      'hora': 'Hace 32 min',
    },
  ];

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String _tipoSeleccionado = 'Cierre vial';

  final List> _tiposNovedad = [
    {'nombre': 'Cierre vial', 'icono': Icons.block, 'color': Colors.red},
    {'nombre': 'Derrumbe', 'icono': Icons.landslide, 'color': Colors.brown},
    {'nombre': 'Inundación', 'icono': Icons.water, 'color': Colors.blue},
    {'nombre': 'Tráfico pesado', 'icono': Icons.traffic, 'color': Colors.orange},
    {'nombre': 'Retén / Control', 'icono': Icons.local_police, 'color': Colors.indigo},
    {'nombre': 'Vía en mal estado', 'icono': Icons.warning_amber, 'color': Colors.amber},
  ];

  @override
  void dispose() {
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _publicarNovedad() {
    if (!_formKey.currentState!.validate()) return;

    final nuevaNovedad = {
      'tipo': _tipoSeleccionado,
      'titulo': '$_tipoSeleccionado en ${_ubicacionController.text.trim()}',
      'detalle': _descripcionController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'hora': 'Ahora mismo',
    };

    setState(() {
      ReportIncidentScreen.novedadesActivas.insert(0, nuevaNovedad);
    });

    _ubicacionController.clear();
    _descripcionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Novedad publicada en el banner dinámico de S.O.S. Auto'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades en la Vía'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportar novedad en tiempo real',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tu reporte aparecerá en el banner superior para alertar a otros conductores.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Text('Tipo de novedad:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tiposNovedad.map((item) {
                          final bool seleccionado = _tipoSeleccionado == item['nombre'];
                          return ChoiceChip(
                            label: Text(item['nombre'] as String),
                            avatar: Icon(
                              item['icono'] as IconData,
                              size: 18,
                              color: seleccionado ? Colors.white : (item['color'] as Color),
                            ),
                            selected: seleccionado,
                            selectedColor: Colors.amber.shade800,
                            labelStyle: TextStyle(
                              color: seleccionado ? Colors.white : Colors.black87,
                              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _tipoSeleccionado = item['nombre'] as String;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ubicacionController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación exacta / Vía / Kilómetro',
                          hintText: 'Ej. Troncal de Occidente km 12, vía Sincelejo',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa la ubicación de la novedad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción de la situación',
                          hintText: 'Ej. Árbol caído bloqueando el carril derecho',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Describe brevemente lo que ocurre en la vía';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _publicarNovedad,
                          icon: const Icon(Icons.campaign),
                          label: const Text(
                            'PUBLICAR ALERTA VIAL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Novedades activas reportadas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ReportIncidentScreen.novedadesActivas.length,
              itemBuilder: (context, index) {
                final novedad = ReportIncidentScreen.novedadesActivas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(Icons.warning_rounded, color: Colors.amber.shade900),
                    ),
                    title: Text(
                      novedad['titulo'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(novedad['detalle'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          '${novedad['ubicacion']} • ${novedad['hora']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }
}
