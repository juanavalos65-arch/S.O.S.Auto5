import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro base para evitar grises por defecto
      body: SafeArea(
        child: Stack(
          children: [
            // 1. FONDO O CONTENEDOR PRINCIPAL
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  'Mapa Interactivo S.O.S. Auto',
                  style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // 2. CABECERA INSTITUCIONAL Y BANNER DINÁMICO SUPERIOR
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Logotipo Oficial e Identidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.security, color: Colors.redAccent, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'S.O.S. Auto',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Banner Dinámico Informativo / Comercial
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ S.O.S. Auto - Red Vial Activa',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. PARRILLA INFERIOR CON LOS 8 BOTONES PRINCIPALES (4 columnas x 2 filas)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView.count(
                  crossAxisCount: 4, // Exactamente 4 columnas
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Fijo, sin scroll interno
                  mainAxisSpacing: 6.0,
                  crossAxisSpacing: 6.0,
                  childAspectRatio: 0.95,
                  children: [
                    _buildButton('Regístrese', Icons.person_add, Colors.blue, () => _onTap('Regístrese')),
                    _buildButton('Paute Aquí', Icons.campaign, Colors.amber, () => _onTap('Paute Aquí')),
                    _buildButton('Me Varé', Icons.car_repair, Colors.orange, () => _onTap('Me Varé')),
                    _buildButton('Accidente', Icons.car_crash, Colors.red, () => _onTap('Me Accidenté')),
                    _buildButton('Peligro', Icons.warning, Colors.deepOrange, () => _onTap('Estoy en Peligro')),
                    _buildButton('Tránsito', Icons.local_police, Colors.indigo, () => _onTap('Agente de Tránsito')),
                    _buildButton('Robo Auto', Icons.local_shipping, Colors.redAccent, () => _onTap('Robo de Auto')),
                    _buildButton('Novedades', Icons.announcement, Colors.teal, () => _onTap('Novedades en Vía')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar optimizado
  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Acción: $title'), duration: const Duration(milliseconds: 600)),
    );
  }
}
