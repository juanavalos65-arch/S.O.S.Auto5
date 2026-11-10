import 'package:flutter/material.dart';

class TrafficStopScreen extends StatelessWidget {
  const TrafficStopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me Detuvo un Agente de Tránsito'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.local_police, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Control y Registro de Procedimiento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Activa el registro del procedimiento y mantén la seguridad respaldada por la red.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grabación y registro de retención iniciados.')),
                );
              },
              icon: const Icon(Icons.fiber_manual_record, color: Colors.redAccent),
              label: const Text('Iniciar Registro / Audio', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
