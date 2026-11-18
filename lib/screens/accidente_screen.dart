import 'package:flutter/material.dart';

class AccidenteScreen extends StatefulWidget {
  const AccidenteScreen({super.key});

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  String _gravedad = 'Solo daños materiales (Choque simple)';
  bool _requiereAmbulancia = false;
  final TextEditingController _placaCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Accidente Vial'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nivel del incidente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _gravedad,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Solo daños materiales (Choque simple)', child: Text('Solo daños materiales (Choque simple)')),
              DropdownMenuItem(value: 'Accidente con heridos leves', child: Text('Accidente con heridos leves')),
              DropdownMenuItem(value: 'Emergencia grave / Volcamiento', child: Text('Emergencia grave / Volcamiento')),
            ],
            onChanged: (v) => setState(() => _gravedad = v!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Solicitar ambulancia prioritaria'),
            value: _requiereAmbulancia,
            activeColor: const Color(0xFFC62828),
            onChanged: (v) => setState(() => _requiereAmbulancia = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo involucrado',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.emergency),
              label: const Text('ACTIVAR ALERTA DE ACCIDENTE', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alerta de accidente transmitida con coordenadas GPS.')),
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
