import 'package:flutter/material.dart';
import 'bottom_action_grid.dart'; // Importa la grilla de los 8 botones fijos
import 'banner_dinamico.dart';   // Importa tu banner dinámico rotativo
import 'map_screen.dart';        // Importa tu mapa interactivo

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Capa Base: El Mapa Interactivo (ocupa toda la pantalla)
          Positioned.fill(
            child: MapScreen(),
          ),

          // 2. Capa Superior: Banner Dinámico / Alertas en la vía
          const Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                BannerDinamico(),
              ],
            ),
          ),

          // 3. Capa Inferior: Los 8 botones fijos y visibles a primera vista sin scroll
          const Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: BottomActionGrid(),
          ),
        ],
      ),
    );
  }
}
