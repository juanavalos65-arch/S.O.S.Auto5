import 'package:flutter/material.dart';

class MeVareScreen extends StatefulWidget {
  const MeVareScreen({super.key});

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  String _fallaSeleccionada = 'Batería descargada / No enciende';
  final TextEditingController _placaCtrl = TextEditingController();
  final TextEditingController _detalleCtrl = TextEditingController();

  final List<String> _fallas = [
    'Batería descargada / No enciende',
    'Llanta pinchada / Sin repuesto',
    'Falla mecánica / Motor detenido',
    'Sin combustible',
    'Llaves dentro del vehículo',
    'Necesito servicio de grúa',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Varé — Solicitar Asistencia'),
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tipo de varada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _fallaSeleccionada,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _fallas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => setState(() => _fallaSeleccionada = v!),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo (Ej: HXU874)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _detalleCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Punto de referencia o detalle adicional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6C00),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
              label: const Text('ENVIAR ALERTA A ALIADOS Y CONTACTOS', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solicitud de asistencia enviada con tu ubicación GPS.')),
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
