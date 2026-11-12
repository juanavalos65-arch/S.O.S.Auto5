import 'dart:async';
import 'package:flutter/material.dart';

class BannerDinamico extends StatefulWidget {
  const BannerDinamico({Key? key}) : super(key: key);

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final List> _mensajes = [
    {
      'texto': '🏢 Pauta Aquí: Anuncie su taller o grúa - Wompi',
      'color': Colors.amber.shade850,
      'icono': Icons.business,
    },
    {
      'texto': '🚨 Alerta Robo: Chevrolet Aveo Placa HXU874 (Ver detalles)',
      'color': Colors.red.shade700,
      'icono': Icons.warning_amber_rounded,
    },
    {
      'texto': '⚠️ Novedad en Vía: Cierre parcial por mantenimiento en la vía',
      'color': Colors.blue.shade850,
      'icono': Icons.traffic,
    },
  ];

  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Rotación automática cada 4 segundos para el banner dinámico
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _mensajes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mensajeActual = _mensajes[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(_currentIndex),
        margin: const EdgeInsets.symmetric(horizontal: 16, py: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mensajeActual['color'],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(mensajeActual['icono'], color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensajeActual['texto'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
