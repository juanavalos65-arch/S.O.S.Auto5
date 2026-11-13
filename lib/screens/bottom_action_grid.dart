import 'package:flutter/material.dart';

class BottomActionGrid extends StatelessWidget {
  final Function(String actionId)? onActionSelected;

  const BottomActionGrid({Key? key, this.onActionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: 4, // 4 columnas (2 filas para los 8 botones)
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Fijo, sin scroll interno
            mainAxisSpacing: 6.0,
            crossAxisSpacing: 6.0,
            childAspectRatio: 1.02, // Relación equilibrada para evitar iconos pequeños
            children: [
              _buildActionItem(
                icon: Icons.mic,
                label: 'Voz',
                onTap: () => onActionSelected?.call('voice_recording'),
              ),
              _buildActionItem(
                icon: Icons.camera_alt,
                label: 'Cámara',
                onTap: () => onActionSelected?.call('quick_camera'),
              ),
              _buildActionItem(
                icon: Icons.car_crash,
                label: 'Accidente',
                onTap: () => onActionSelected?.call('accident'),
              ),
              _buildActionItem(
                icon: Icons.warning_amber_rounded,
                label: 'Peligro',
                onTap: () => onActionSelected?.call('danger'),
              ),
              _buildActionItem(
                icon: Icons.local_police,
                label: 'Robo Auto',
                onTap: () => onActionSelected?.call('stolen_car'),
              ),
              _buildActionItem(
                icon: Icons.traffic,
                label: 'Tránsito',
                onTap: () => onActionSelected?.call('traffic_stop'),
              ),
              _buildActionItem(
                icon: Icons.sos,
                label: 'SOS 7',
                onTap: () => onActionSelected?.call('sos_general'),
              ),
              _buildActionItem(
                icon: Icons.support_agent,
                label: 'Soporte',
                onTap: () => onActionSelected?.call('support'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.redAccent),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
