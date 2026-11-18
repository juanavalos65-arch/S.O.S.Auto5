import 'package:flutter/material.dart';

class TrafficStopScreen extends StatelessWidget {
  const TrafficStopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procedimiento Agente de Tránsito'),
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.videocam, color: Color(0xFF283593)),
              title: Text('Derecho a grabar (Ley 1801 / Código de Policía)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Todo procedimiento en vía pública puede ser grabado por el ciudadano sin obstruir la labor.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.badge, color: Color(0xFF283593)),
              title: Text('Identificación del funcionario', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('El agente debe portar placa visible y orden de servicio o jurisdicción vigente.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.phone_android, color: Color(0xFF283593)),
              title: Text('Documentos digitales válidos (Circular RUNT)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Licencia de conducción, SOAT y Revisión Tecnomecánica pueden verificarse en línea en el RUNT.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.gavel, color: Color(0xFF283593)),
              title: Text('Inmovilización y subsanación', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Si la causa se subsana en el sitio dentro de los 60 minutos, no procede el traslado a patios.'),
            ),
          ),
        ],
      ),
    );
  }
}
