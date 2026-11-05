import 'package:flutter/material.dart';

class EmergencySosScreen extends StatefulWidget {
  final String emergencyType; // Ej: "Me varé", "Me accidenté", "Estoy en peligro", "Robo de auto", "Agente de tránsito"
  
  const EmergencySosScreen({super.key, required this.emergencyType});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  String? selectedSubOption;

  // Opciones específicas según el tipo de emergencia
  List> getSubOptions() {
    switch (widget.emergencyType) {
      case 'Me varé':
        return [
          {'title': 'Batería descargada', 'subtitle': 'No enciende / luces débiles'},
          {'title': 'Llanta pinchada', 'subtitle': 'Necesito cambio o inflado'},
          {'title': 'Falla de motor', 'subtitle': 'Se apagó / humo / ruido'},
          {'title': 'Me quedé sin gasolina', 'subtitle': 'Necesito combustible'},
          {'title': 'Llaves / Otro problema', 'subtitle': 'Describe lo que pasó'},
        ];
      case 'Me accidenté':
        return [
          {'title': 'Choque leve - Sin heridos', 'subtitle': 'Daños materiales, vehículos se pueden mover'},
          {'title': 'Choque grave - Con heridos', 'subtitle': 'Hay personas lesionadas, urge ambulancia'},
          {'title': 'Atropello a peatón / ciclista', 'subtitle': 'Persona en la vía necesita ayuda'},
          {'title': 'Volcamiento / Salida de vía', 'subtitle': 'Vehículo volcado o fuera de la carretera'},
          {'title': 'Moto / Otro vehículo involucrado', 'subtitle': 'Describe cuántos vehículos'},
        ];
      case 'Estoy en peligro':
        return [
          {'title': 'Me están siguiendo', 'subtitle': 'Vehículo o persona me persigue'},
          {'title': 'Intento de robo / atraco', 'subtitle': 'Me quieren robar el vehículo o pertenencias'},
          {'title': 'Me siento inseguro/a en la zona', 'subtitle': 'Zona oscura / sola / desconocida'},
          {'title': 'Violencia / Amenaza', 'subtitle': 'Alguien me amenaza o agrede'},
          {'title': 'Otro peligro', 'subtitle': 'Describe lo que está pasando'},
        ];
      case 'Robo de auto':
        return [
          {'title': 'Me robaron el vehículo', 'subtitle': 'Se llevaron mi carro / moto estando estacionado'},
          {'title': 'Me robaron en el vehículo', 'subtitle': 'Me abrieron / rompieron vidrio y robaron cosas'},
          {'title': 'Intento de robo', 'subtitle': 'Intentaron robarme, no lo lograron'},
          {'title': 'Me quitaron el vehículo', 'subtitle': 'Me amenazaron y me lo quitaron en la vía'},
          {'title': 'Robo de pertenencias / documentos', 'subtitle': 'Me robaron papeles, celular, llaves'},
        ];
      default:
        return [
          {'title': 'Retén / Control de rutina', 'subtitle': 'Control de documentos / alcoholemia'},
          {'title': 'Me piden documentos', 'subtitle': 'Licencia, SOAT, tecnomecánica, tarjeta'},
          {'title': 'Me van a poner comparendo', 'subtitle': 'Me dicen que cometí una infracción'},
          {'title': 'Me quieren inmovilizar', 'subtitle': 'Quieren llevarse el vehículo a patios'},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = getSubOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto', style: TextStyle(color: Color(0xFF0A2540))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A2540)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Dinámica
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.emergencyType == 'Estoy en peligro' || widget.emergencyType == 'Robo de auto'
                    ? Colors.red.shade50
                    : const Color(0xFFD6E4FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.emergencyType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.emergencyType == 'Estoy en peligro' || widget.emergencyType == 'Robo de auto'
                          ? Colors.red.shade900
                          : const Color(0xFF0A2540),
                    ),
                  ),
                  const Text(
                    'PASO 1/2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              '¿Qué sucedió?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A2540)),
            ),
            const Text(
              'Elige una opción para enviar ayuda a tu ubicación',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Opciones de Emergencia
            ...options.map((opt) {
              bool isSelected = selectedSubOption == opt['title'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedSubOption = opt['title'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD6E4FC) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0A2540) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0A2540),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt['subtitle']!,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF0A2540)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 15),

            // Tarjeta de Ubicación Actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sincelejo, Sucre - GPS activo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A2540)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Se compartirá con los contactos y servicios autorizados',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Tarjeta de Recomendaciones ("¿Qué hacer?")
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '⚠️ ¿QUÉ HACER MIENTRAS LLEGA AYUDA?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Enciende las estacionarias y pon triángulos a 30 metros.\n2. Aléjate a un lugar seguro, no te quedes en la vía.\n3. Mantén la calma y espera a los aliados autorizados.',
                    style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botones de Acción Final
            ElevatedButton(
              onPressed: () {
                if (selectedSubOption == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor selecciona una opción específica')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alerta enviada a contactos de emergencia')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2540),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ENVIAR ALERTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solicitando ayuda especializada...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SOLICITAR AYUDA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
