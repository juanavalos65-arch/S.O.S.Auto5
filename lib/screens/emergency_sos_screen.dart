import 'package:flutter/material.dart';

class EmergencySosScreen extends StatelessWidget {
  final String emergencyType;
  
  const EmergencySosScreen({super.key, this.emergencyType = 'Asistencia General'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergencia: $emergencyType'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Protocolo Activo: $emergencyType',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Cuenta regresiva de 5 segundos iniciada. Ingrese su PIN o biometría para cancelar de ser necesario.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alerta de emergencia emitida a la red de S.O.S. Auto.')),
                );
              },
              icon: const Icon(Icons.sos),
              label: const Text('Confirmar Emergencia Ahora', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
