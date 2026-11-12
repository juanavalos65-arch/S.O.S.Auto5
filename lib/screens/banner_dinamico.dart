import 'dart:async';
import 'package:flutter/material.dart';

class BannerDinamico extends StatefulWidget {
  const BannerDinamico({super.key});

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final List _mensajes = [
    {
      'texto': '🏢 Pauta Aquí: Anuncie su taller o grúa - Wompi',
      'color': Colors.amber,
      'icono': Icons.business,
    },
    {
      'texto': '🚨 Alerta Robo: Vehículo reportado en red',
      'color': Colors.red,
      'icono': Icons.warning_amber_rounded,
    },
    {
      'texto': '⚠️ Novedad en Vía: Cierre parcial',
      'color': Colors.blue,
      'icono': Icons.traffic,
    },
  ];

  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _mensajes.length;
        });
      }
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
      child: Container(
        key: ValueKey(_currentIndex),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mensajeActual['color'],
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              mensajeActual['icono'],
              color: Colors.white,
              size: 22,
            ),
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
