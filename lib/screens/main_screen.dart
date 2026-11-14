import 'package:flutter/material.dart';
import 'allies_screen.dart';
import 'banner_dinamico.dart';
import 'bottom_action_grid.dart';
import 'map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _buildHomeStack() {
    return Stack(
      children: [
        // 1. Capa Base: El Mapa Interactivo (ocupa toda la pantalla)
        const Positioned.fill(
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
          bottom: 16,
          left: 16,
          right: 16,
          child: BottomActionGrid(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeStack(),
          const AlliesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey.shade700,
        backgroundColor: Colors.white,
        elevation: 12,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Inicio S.O.S.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Directorio Aliados',
          ),
        ],
      ),
    );
  }
}
