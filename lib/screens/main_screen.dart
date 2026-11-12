import 'package:flutter/material.dart';
import 'banner_dinamico.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List botonesEmergencia = [
      {'titulo': 'Regístrese', 'icono': Icons.person_add, 'color': Colors.indigo},
      {'titulo': 'Paute Aquí', 'icono': Icons.campaign, 'color': Colors.purple},
      {'titulo': 'Me Varé', 'icono': Icons.car_repair, 'color': Colors.amber},
      {'titulo': 'Me Accidenté', 'icono': Icons.car_crash, 'color': Colors.red},
      {'titulo': 'En Peligro', 'icono': Icons.security, 'color': Colors.deepOrange},
      {'titulo': 'Tránsito', 'icono': Icons.local_police, 'color': Colors.blueGrey},
      {'titulo': 'Robo Auto', 'icono': Icons.search, 'color': Colors.deepPurple},
      {'titulo': 'Novedades', 'icono': Icons.warning, 'color': Colors.orange},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. CABECERA: LOGO, SLOGAN Y BANNER DINÁMICO
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                  const BannerDinamico(),
                ],
              ),
            ),

            // 2. MAPA CENTRAL (Sin interferencia de botones)
            Expanded(
              child: Container(
                color: Colors.green.shade50,
                child: const Center(
                  child: Text(
                    'Mapa Interactivo S.O.S. Auto',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            // 3. SECCIÓN INFERIOR: 8 BOTONES ALINEADOS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: botonesEmergencia.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final boton = botonesEmergencia[index];
                  return InkWell(
                    onTap: () {},
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: boton['color'] as Color,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(boton['icono'] as IconData, color: Colors.white, size: 22),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              boton['titulo'] as String,
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
