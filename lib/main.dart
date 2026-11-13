import 'package:flutter/material.dart';

void main() {
  runApp(const SOSAutoApp());
}

class SOSAutoApp extends StatelessWidget {
  const SOSAutoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. Auto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            // Logotipo Oficial y Cabecera
            const Icon(Icons.local_shipping, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            const Text(
              'S.O.S. AUTO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Banner Dinámico Informativo y Comercial (Rotatorio Tripartito)
          Container(
            width: double.infinity,
            color: Colors.amber[100],
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: Colors.orange, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Alerta: Vehículo robado placa HXU874 | Paute aquí con Wompi',
                    style: TextStyle(
                      color: Colors.brown[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Mapa Interactivo Central (Simulado)
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.blueGrey[50],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 80, color: Colors.blueGrey[300]),
                        const SizedBox(height: 10),
                        Text(
                          'Mapa Interactivo - Medellín / Sincelejo',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 3. Los 8 Botones Flotantes Permanentes sobre el Mapa
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [
                        _buildFloatingButton(
                          context, 
                          'Regístrese', 
                          Icons.person_add, 
                          Colors.blue,
                          () => _showActionMsg(context, 'Registro de usuario y placa')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Paute Aquí', 
                          Icons.star, 
                          Colors.amber.shade800,
                          () => _showActionMsg(context, 'Pasarela Wompi - Planes publicitarios')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Me Varé', 
                          Icons.build, 
                          Colors.orange,
                          () => _showActionMsg(context, 'Asistencia vial directa')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Accidente', 
                          Icons.car_crash, 
                          Colors.red,
                          () => _showEmergencyModal(context, 'Me Accidenté (Anulación por PIN/Biometría)')
                        ),
                        _buildFloatingButton(
                          context, 
                          'En Peligro', 
                          Icons.warning, 
                          Colors.deepOrange,
                          () => _showEmergencyModal(context, 'Estoy en Peligro (Alerta de seguridad)')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Tránsito', 
                          Icons.local_police, 
                          Colors.indigo,
                          () => _showEmergencyModal(context, 'Agente de Tránsito (Grabación activada)')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Robo Auto', 
                          Icons.security, 
                          Colors.purple,
                          () => _showActionMsg(context, 'Reporte inmediato de Robo a la red')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Novedades', 
                          Icons.traffic, 
                          Colors.green,
                          () => _showActionMsg(context, 'Novedades y estado en la vía')
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showActionMsg(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showEmergencyModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('⚠️ Alerta activada. Cuenta regresiva de 5 segundos. Ingrese PIN o huella para cancelar falsos positivos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar (PIN/Biometría)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Alerta enviada a la red y soporte.applay65@gmail.com!')),
              );
            },
            child: const Text('Confirmar Emergencia'),
          ),
        ],
      ),
    );
  }
}
