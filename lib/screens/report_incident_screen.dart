import 'package:flutter/material.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String _tipoNovedad = 'Vía cerrada / Obra / Derrumbe';
  final TextEditingController _ubicacionCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades en la Vía'),
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('¿Qué ocurre en la vía?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tipoNovedad,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Vía cerrada / Obra / Derrumbe', child: Text('Vía cerrada / Obra / Derrumbe')),
              DropdownMenuItem(value: 'Congestión vehicular fuerte', child: Text('Congestión vehicular fuerte')),
              DropdownMenuItem(value: 'Inundación / Árbol caído', child: Text('Inundación / Árbol caído')),
              DropdownMenuItem(value: 'Hueco peligroso / Mancha de aceite', child: Text('Hueco peligroso / Mancha de aceite')),
            ],
            onChanged: (v) => setState(() => _tipoNovedad = v!),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ubicacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Sector, avenida o kilómetro',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57C00), foregroundColor: Colors.white),
              icon: const Icon(Icons.campaign),
              label: const Text('PUBLICAR EN BANNER Y MAPA', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Novedad vial publicada para conductores cercanos.')),
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
