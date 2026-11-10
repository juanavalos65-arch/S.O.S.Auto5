import 'package:flutter/material.dart';

class StolenCarScreen extends StatefulWidget {
  const StolenCarScreen({super.key});

  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerta de Robo de Vehículo'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Icon(Icons.directions_car_filled, size: 64, color: Colors.brown),
            const SizedBox(height: 16),
            const Text(
              'Reporte Inmediato de Hurto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta alerta se transmitirá instantáneamente a la red comunitaria y al banner superior de S.O.S. Auto.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Placa del Vehículo (Ej: HXU874)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Marca y Modelo (Ej: Chevrolet Aveo)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.car_rental),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalles del robo, color o ubicación de los hechos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Alerta de robo emitida a la red y publicada en el banner!')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.warning, color: Colors.amber),
              label: const Text('Emitir Alerta de Robo Masiva', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
