import 'dart:async';
import 'package:flutter/material.dart';

import 'register_vehicle_screen.dart';
import 'paute_aqi_screen.dart';
import 'me_vare_screen.dart';
import 'repot_incident_screen.dart';
import 'stolen_car_screen.dart';
import 'emergency_sos_screen.dart';

class BottomActionGrid extends StatelessWidget {
  const BottomActionGrid({super.key});

  static const List> _botones = [
    {
      'titulo': 'Registro',
      'icono': Icons.app_registration,
      'color': Color(0xFF1E40AF),
      'bgColor': Color(0xFFDBEAFE),
      'esEmergencia': false,
    },
    {
      'titulo': 'Paute aquí',
      'icono': Icons.campaign,
      'color': Color(0xFF065F46),
      'bgColor': Color(0xFFD1FAE5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Me varé',
      'icono': Icons.car_repair,
      'color': Color(0xFF9A3412),
      'bgColor': Color(0xFFFFEDD5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Accidente',
      'icono': Icons.car_crash,
      'color': Color(0xFF991B1B),
      'bgColor': Color(0xFFFEE2E2),
      'esEmergencia': true,
    },
    {
      'titulo': 'Estoy en peligro',
      'icono': Icons.gpp_maybe,
      'color': Color(0xFF7F1D1D),
      'bgColor': Color(0xFFFECACA),
      'esEmergencia': true,
    },
    {
      'titulo': 'Robo de auto',
      'icono': Icons.no_crash,
      'color': Color(0xFF881337),
      'bgColor': Color(0xFFFFE4E6),
      'esEmergencia': true,
    },
    {
      'titulo': 'Novedades en la vía',
      'icono': Icons.alt_route,
      'color': Color(0xFF3730A3),
      'bgColor': Color(0xFFE0E7FF),
      'esEmergencia': false,
    },
    {
      'titulo': 'Agente de tránsito',
      'icono': Icons.local_police,
      'color': Color(0xFF1F2937),
      'bgColor': Color(0xFFE5E7EB),
      'esEmergencia': true,
    },
  ];

  void _alPresionarBoton(BuildContext context, Map<String, dynamic> boton) {
    final String titulo = boton['titulo'] as String;
    final bool esEmergencia = boton['esEmergencia'] as bool;

    if (esEmergencia) {
      _mostrarDialogo5Segundos(context, titulo);
    } else {
      _navegarAPantalla(context, titulo);
    }
  }

  void _navegarAPantalla(BuildContext context, String titulo) {
    Widget? destino;

    switch (titulo) {
      case 'Registro':
        destino = const RegisterVehicleScreen();
        break;
      case 'Paute aquí':
        destino = const PauteAquiScreen();
        break;
      case 'Me varé':
        destino = const MeVareScreen();
        break;
      case 'Novedades en la vía':
        destino = const ReportIncidentScreen();
        break;
      case 'Robo de auto':
        destino = const StolenCarScreen();
        break;
      case 'Estoy en peligro':
      case 'Accidente':
      case 'Agente de tránsito':
        destino = const EmergencySosScreen();
        break;
    }

    if (destino != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destino!),
      );
    }
  }

  void _mostrarDialogo5Segundos(BuildContext rootContext, String tipoAlerta) {
    int segundosRestantes = 5;
    Timer? cuentaRegresiva;
    bool cancelada = false;

    showDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            cuentaRegresiva ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!dialogContext.mounted || cancelada) {
                t.cancel();
                return;
              }
              if (segundosRestantes > 1) {
                setDialogState(() {
                  segundosRestantes--;
                });
              } else {
                cancelada = true;
                t.cancel();
                Navigator.of(dialogContext).pop();
                _dispararAlertaConfirmada(rootContext, tipoAlerta);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alerta: $tipoAlerta',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enviando alerta GPS en $segundosRestantes segundos...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tienes 5 segundos para cancelar la alerta si la presionaste por error.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cancelada = true;
                        cuentaRegresiva?.cancel();
                        Navigator.of(dialogContext).pop();
                        if (rootContext.mounted) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Alerta desactivada.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'DESACTIVAR ALERTA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => cuentaRegresiva?.cancel());
  }

  void _dispararAlertaConfirmada(BuildContext context, String tipoAlerta) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Alerta "$tipoAlerta" enviada con ubicación GPS.'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
    _navegarAPantalla(context, tipoAlerta);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _botones.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          final btn = _botones[index];
          final Color colorPrincipal = btn['color'] as Color;
          final Color colorFondo = btn['bgColor'] as Color;

          return InkWell(
            onTap: () => _alPresionarBoton(context, btn),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorPrincipal.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    btn['icono'] as IconData,
                    color: colorPrincipal,
                    size: 26,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    btn['titulo'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorPrincipal,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
