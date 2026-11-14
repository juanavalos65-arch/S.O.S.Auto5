import 'dart:async';
import 'package:flutter/material.dart';

class _BannerItem {
  final String tipo;
  final String titulo;
  final String subtitulo;
  final Color color;
  final IconData icono;

  const _BannerItem({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.icono,
  });
}

class _EmergencyButtonItem {
  final String label;
  final IconData icon;
  final Color color;

  const _EmergencyButtonItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  static const List<_BannerItem> _bannerItems = [
    _BannerItem(
      tipo: 'ALIADO COMERCIAL',
      titulo: 'Grúas y Talleres 24/7 en Medellín y Sincelejo',
      subtitulo: '20% de descuento presentando tu app S.O.S. Auto',
      color: Color(0xFF1565C0),
      icono: Icons.local_shipping,
    ),
    _BannerItem(
      tipo: 'ALERTA VEHÍCULO ROBADO',
      titulo: 'Mazda 3 Gris - Placa KLM-456',
      subtitulo: 'Reportado hace 15 min. Si lo ves, toca aquí',
      color: Color(0xFFC62828),
      icono: Icons.warning_amber_rounded,
    ),
    _BannerItem(
      tipo: 'NOVEDAD EN LA VÍA',
      titulo: 'Paso restringido Troncal de Occidente',
      subtitulo: 'Cierre parcial por mantenimiento vial - Conduzca con precaución',
      color: Color(0xFFEF6C00),
      icono: Icons.traffic,
    ),
  ];

  final List<_EmergencyButtonItem> _emergencyButtons = [
    _EmergencyButtonItem(label: 'Pánico / Robo', icon: Icons.gpp_maybe, color: Colors.red.shade700),
    _EmergencyButtonItem(label: 'Accidente', icon: Icons.car_crash, color: Colors.deepOrange.shade700),
    _EmergencyButtonItem(label: 'Grúa', icon: Icons.local_shipping, color: Colors.blue.shade800),
    _EmergencyButtonItem(label: 'Mecánico', icon: Icons.build, color: Colors.indigo.shade700),
    _EmergencyButtonItem(label: 'Batería', icon: Icons.battery_charging_full, color: Colors.amber.shade800),
    _EmergencyButtonItem(label: 'Llanta', icon: Icons.tire_repair, color: Colors.teal.shade700),
    _EmergencyButtonItem(label: 'Cerrajero', icon: Icons.vpn_key, color: Colors.purple.shade700),
    _EmergencyButtonItem(label: 'Ambulancia', icon: Icons.medical_services, color: Colors.pink.shade700),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _bannerItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _triggerEmergency(String serviceName, Color color) {
    int secondsLeft = 5;
    Timer? countdownTimer;
    final TextEditingController pinController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (secondsLeft > 1) {
                setDialogState(() {
                  secondsLeft--;
                });
              } else {
                timer.cancel();
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                _showAlertSentConfirmation(serviceName);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.notifications_active, color: color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alerta: $serviceName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enviando alerta GPS en $secondsLeft segundos...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingresa tu PIN de seguridad (1234) para cancelar:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'PIN (1234)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value == '1234') {
                        countdownTimer?.cancel();
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Alerta cancelada correctamente mediante PIN.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
    });
  }

  void _showAlertSentConfirmation(String serviceName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡S.O.S. enviado! Asistencia de $serviceName en camino a tu ubicación.'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBanner = _bannerItems[_bannerIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'S.O.S. AUTO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'Mis Vehículos',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestión de placas y documentos')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil de usuario y recuperación')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FONDO DE MAPA EN MODO PRUEBA (Mientras se configura la API Key)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECEF),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 72, color: Colors.blueGrey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Mapa GPS en modo prueba',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Medellín / Sincelejo • Listo para API Key',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // 2. BANNER DINÁMICO SUPERIOR
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: currentBanner.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(currentBanner.icono, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBanner.tipo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          currentBanner.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentBanner.subtitulo,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. PANEL FLOTANTE INFERIOR CON LOS 8 BOTONES DE EMERGENCIA
          Positioned(
            bottom: 14,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ASISTENCIA INMEDIATA S.O.S.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _emergencyButtons.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, index) {
                      final btn = _emergencyButtons[index];
                      return InkWell(
                        onTap: () => _triggerEmergency(btn.label, btn.color),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: btn.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: btn.color.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(btn.icon, color: btn.color, size: 26),
                              const SizedBox(height: 4),
                              Text(
                                btn.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: btn.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
