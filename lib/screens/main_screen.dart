import 'package:flutter/material.dart';
// Importa aquí tu banner dinámico que acabas de crear en la carpeta screen:
// import 'banner_dinamico.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definición de los 8 botones oficiales de S.O.S. Auto
    final List> botonesEmergencia = [
      {'titulo': 'Regístrese', 'icono': Icons.person_add, 'color': Colors.indigo},
      {'titulo': 'Paute Aquí', 'icono': Icons.campaign, 'color': Colors.purple},
      {'titulo': 'Me Varé', 'icono': Icons.car_repair, 'color': Colors.amber.shade800},
      {'titulo': 'Me Accidenté', 'icono': Icons.car_crash, 'color': Colors.red},
      {'titulo': 'En Peligro', 'icono': Icons.security, 'color': Colors.deepOrange},
      {'titulo': 'Tránsito', 'icono': Icons.local_police, 'color': Colors.blueGrey},
      {'titulo': 'Robo Auto', 'icono': Icons.search, 'color': Colors.deepPurple},
      {'titulo': 'Novedades', 'icono': Icons.warning, 'color': Colors.orange.shade800},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 1. CABECERA: LOGOTIPO, SLOGAN Y BANNER
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logotipo oficial (Asegúrate de tener tu asset configurado)
                      Image.asset(
                        'assets/icon/icon_sos.png', 
                        height: 32, 
                        width: 32,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.shield_rounded, color: Colors.red, size: 32),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'S.O.S. Auto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Red Vial Activa',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Aquí colocas tu Banner Dinámico en movimiento
                  // const BannerDinamico(),
                ],
              ),
            ),

            // ==========================================
            // 2. MAPA CENTRAL (Expandido sin interferencia)
            // ==========================================
            Expanded(
              child: Stack(
                children: [
                  // Aquí va tu widget de Mapa actual de América / Ubicación
                  Container(
                    color: Colors.green.shade50, // Color base de prueba del mapa
                    child: const Center(
                      child: Text(
                        'Mapa Interactivo\n(Posición real y calles en desarrollo)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // 3. SECCIÓN INFERIOR: LOS 8 BOTONES OFICIALES
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: botonesEmergencia.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 columnas x 2 filas = 8 botones perfectamente alineados
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final boton = botonesEmergencia[index];
                  return InkWell(
                    onTap: () {
                      // Acción para cada uno de los 8 botones
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: boton['color'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(boton['icono'], color: Colors.white, size: 22),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              boton['titulo'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
