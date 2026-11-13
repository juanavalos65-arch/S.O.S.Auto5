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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _bannerIndex = 0;

  final List> _bannerItems = [
    {
      'title': '📢 Pauta Comercial Wompi',
      'subtitle': 'Afilie su taller o grúa hoy mismo desde $50.000 COP'
    },
    {
      'title': '🚨 Alerta: Vehículo robado',
      'subtitle': 'Placa HXU874 | Chevrolet Aveo gris en Medellín'
    },
    {
      'title': '⚠️ Novedad en Vía',
      'subtitle': 'Derrumbe habilitado a un carril en la vía Sincelejo'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
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
          // 1. Banner Dinámico Informativo y Comercial
          GestureDetector(
            onTap: () {
              setState(() {
                _bannerIndex = (_bannerIndex + 1) % _bannerItems.length;
              });
              if (_bannerIndex == 0) {
                _showWompiInfo(context);
              }
            },
            child: Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.orange, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bannerItems[_bannerIndex]['title']!,
                          style: TextStyle(
                            color: Colors.brown[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _bannerItems[_bannerIndex]['subtitle']!,
                          style: TextStyle(
                            color: Colors.brown[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.touch_app, color: Colors.brown, size: 18),
                ],
              ),
            ),
          ),
          
          // 2. Mapa Interactivo Central
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
                        const SizedBox(height: 5),
                        Text(
                          'GPS Activo | Sincronización en tiempo real',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 3. Los 8 Botones Flotantes Permanentes
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
                          () => _showActionModal(context, 'Registro de Usuario y Placa', 'Ingrese los datos del conductor y placa autorizada.')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Paute Aquí', 
                          Icons.star, 
                          Colors.amber.shade800,
                          () => _showWompiInfo(context)
                        ),
                        _buildFloatingButton(
                          context, 
                          'Me Varé', 
                          Icons.build, 
                          Colors.orange,
                          () => _showActionModal(context, 'Asistencia Vial (Me Varé)', 'Conectando directamente con grúas y talleres cercanos sin comisiones de intermediación.')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Accidente', 
                          Icons.car_crash, 
                          Colors.red,
                          () => _showEmergencyModal(context, '¡Accidente Detectado!')
                        ),
                        _buildFloatingButton(
                          context, 
                          'En Peligro', 
                          Icons.warning, 
                          Colors.deepOrange,
                          () => _showEmergencyModal(context, 'Alerta: Estoy en Peligro')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Tránsito', 
                          Icons.local_police, 
                          Colors.indigo,
                          () => _showEmergencyModal(context, 'Control de Tránsito / Retén')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Robo Auto', 
                          Icons.security, 
                          Colors.purple,
                          () => _showActionModal(context, 'Reporte de Robo a la Red', 'Su alerta será difundida inmediatamente al banner y a la central de seguridad.')
                        ),
                        _buildFloatingButton(
                          context, 
                          'Novedades', 
                          Icons.traffic, 
                          Colors.green,
                          () => _showActionModal(context, 'Novedades en la Vía', 'Reporte derrumbes, clima o cierres viales a la comunidad.')
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

  void _showActionModal(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWompiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📢 Paute Aquí con Wompi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Planes publicitarios oficiales para talleres y aliados:'),
            SizedBox(height: 8),
            Text('• 1 Mes: $50.000 COP + Impuestos'),
            Text('• 6 Meses: $550.000 COP + Impuestos'),
            Text('• 1 Año: $500.000 COP + Impuestos'),
            SizedBox(height: 12),
            Text('Enlace de pago oficial Wompi:\nhttps://checkout.wompi.co/l/VPOS_3Odu3K',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('⚠️ Alerta activada. Cuenta regresiva de 5 segundos. Ingrese PIN o huella biométrica para cancelar falsos positivos antes del envío de coordenadas GPS.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar (PIN/Biometría)', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Alerta transmitida con éxito a soporte.applay65@gmail.com!')),
              );
            },
            child: const Text('Confirmar Alerta'),
          ),
        ],
      ),
    );
  }
}
