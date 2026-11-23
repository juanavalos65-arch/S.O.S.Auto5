import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerDinamico extends StatefulWidget {
  const BannerDinamico({super.key});

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final List> _mensajesBase = [
    {
      'texto': '🏢 Pauta Aquí: Anuncie su taller o grúa - Wompi',
      'color': const Color(0xFF1B5E20),
      'icono': Icons.business,
    },
    {
      'texto': '🚨 S.O.S. Auto: Red activa de seguridad y asistencia 24/7',
      'color': const Color(0xFF0A192F),
      'icono': Icons.shield_outlined,
    },
  ];

  List> _pautasVivas = [];
  List> _robosVivos = [];
  List> _novedadesVivas = [];

  StreamSubscription? _pautasSub;
  StreamSubscription? _robosSub;
  StreamSubscription? _novedadesSub;

  int _currentIndex = 0;
  Timer? _timer;

  List> get _mensajes {
    final lista = >[..._mensajesBase];
    final maxLen = [
      _pautasVivas.length,
      _robosVivos.length,
      _novedadesVivas.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      if (i < _pautasVivas.length) lista.add(_pautasVivas[i]);
      if (i < _robosVivos.length) lista.add(_robosVivos[i]);
      if (i < _novedadesVivas.length) lista.add(_novedadesVivas[i]);
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _conectarFirestore();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final total = _mensajes.length;
      if (total == 0) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % total;
      });
    });
  }

  void _conectarFirestore() {
    try {
      if (Firebase.apps.isEmpty) return;
      final db = FirebaseFirestore.instance;

      _pautasSub = db
          .collection('pautas_activas')
          .where('activo', isEqualTo: true)
          .where('pagoVerificado', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargadas = snap.docs.map((doc) {
          final d = doc.data();
          final nombre = d['negocio']?.toString() ?? 'Aliado S.O.S. Auto';
          final servicio = d['servicio']?.toString() ?? 'Asistencia 24/7';
          return <String, dynamic>{
            'texto': '🏢 Aliado: $nombre — $servicio',
            'color': const Color(0xFF1B5E20),
            'icono': Icons.storefront,
          };
        }).toList();
        if (mounted) {
          setState(() {
            _pautasVivas = cargadas;
            _currentIndex = 0;
          });
        }
      }, onError: (_) {});

      _robosSub = db
          .collection('vehiculos_robados')
          .where('activo', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargados = snap.docs.map((doc) {
          final d = doc.data();
          final vehiculo = d['vehiculo']?.toString() ?? 'Vehículo';
          final placa = d['placa']?.toString() ?? '';
          return <String, dynamic>{
            'texto':
                '🚨 Alerta Robo: $vehiculo ${placa.isNotEmpty ? "($placa)" : ""}',
            'color': const Color(0xFFB71C1C),
            'icono': Icons.warning_amber_rounded,
          };
        }).toList();
        if (mounted) {
          setState(() {
            _robosVivos = cargados;
            _currentIndex = 0;
          });
        }
      }, onError: (_) {});

      _novedadesSub = db
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(20)
          .snapshots()
          .listen((snap) {
        final ahora = DateTime.now();
        final cargadas = >[];

        for (final doc in snap.docs) {
          final d = doc.data();
          if (d['activo'] == false) continue;

          final bool esPermanente = d['esPermanente'] == true;
          if (!esPermanente) {
            final Timestamp? expiraTs = d['expiraEn'] as Timestamp?;
            if (expiraTs != null && expiraTs.toDate().isBefore(ahora)) {
              continue;
            }
          }

          final tipo = d['tipo']?.toString() ?? 'Novedad en vía';
          final sector = d['sector']?.toString() ?? '';
          cargadas.add({
            'texto': sector.isNotEmpty
                ? '⚠️ Novedad en Vía: $tipo · $sector'
                : '⚠️ Novedad en Vía: $tipo',
            'color': esPermanente
                ? const Color(0xFFC62828)
                : const Color(0xFFE65100),
            'icono': esPermanente ? Icons.speed : Icons.traffic,
          });
        }

        if (mounted) {
          setState(() {
            _novedadesVivas = cargadas;
            _currentIndex = 0;
          });
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pautasSub?.cancel();
    _robosSub?.cancel();
    _novedadesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _mensajes;
    final safeIndex = _currentIndex % lista.length;
    final mensajeActual = lista[safeIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Container(
        key: ValueKey(safeIndex),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mensajeActual['color'] as Color,
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
              mensajeActual['icono'] as IconData,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensajeActual['texto'] as String,
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
