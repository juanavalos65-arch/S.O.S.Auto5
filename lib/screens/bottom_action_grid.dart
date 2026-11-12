import 'package:flutter/material.dart';

class BottomActionGrid extends StatelessWidget {
  const BottomActionGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1 (4 Botones Principales de Emergencia y Acción)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniButton(
                icon: Icons.warning_amber_rounded,
                label: "S.O.S.",
                color: Colors.red,
                onTap: () { /* Acción Alerta S.O.S. */ },
              ),
              _buildMiniButton(
                icon: Icons.mic,
                label: "Voz",
                color: Colors.orange,
                onTap: () { /* Acción Alerta por Voz */ },
              ),
              _buildMiniButton(
                icon: Icons.camera_alt,
                label: "Cámara",
                color: Colors.deepOrange,
                onTap: () { /* Acción Grabación Cámara */ },
              ),
              _buildMiniButton(
                icon: Icons.local_shipping,
                label: "Aliados",
                color: Colors.blue,
                onTap: () { /* Ver Aliados */ },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fila 2 (4 Botones de Gestión y Utilidades)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniButton(
                icon: Icons.security,
                label: "Tránsito",
                color: Colors.indigo,
                onTap: () { /* Reporte Tránsito */ },
              ),
              _buildMiniButton(
                icon: Icons.car_rental,
                label: "Robados",
                color: Colors.purple,
                onTap: () { /* Vehículos Robados */ },
              ),
              _buildMiniButton(
                icon: Icons.app_registration,
                label: "Registro",
                color: Colors.green,
                onTap: () { /* Registrar Placa */ },
              ),
              _buildMiniButton(
                icon: Icons.campaign,
                label: "Pauta",
                color: Colors.amber.shade800,
                onTap: () { /* Pauta / Info */ },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.opacitizedOrTint(0.15), // o color.withOpacity(0.15)
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
