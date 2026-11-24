import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerDinamico extends StatefulWidget {
  const BannerDinamico({super.key});

  /// Permite insertar o quitar alertas al instante desde cualquier pantalla
  static final ValueNotifier<List> alertasLocales = ValueNotifier<List>([]);

  static void publicarLocal({
    required String id,
    required String texto,
    required Color color,
    required IconData icono,
  }) {
    final actual = List.from(alertasLocales.value);
    actual.removeWhere((e) => (e as Map)['id'] == id);
    actual.insert(0, {
      'id': id,
      'texto': texto,
      'color': color,
      'icono': icono,
    });
    alertasLocales.value = actual;
  }

  static void quitarLocal(String id) {
    final actual = List.from(alertasLocales.value);
    actual.removeWhere((e) => (e as Map)['id'] == id);
    alertasLocales.value = actual;
  }

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final List _mensajesBase = [
    {
      'texto': '🏢 Pauta Aquí: Anuncie su taller o grúa — Wompi / Bre-B',
      'color': const Color(0xFF1B5E20),
      'icono': Icons.business,
    },
    {
      'texto': '🚨 S.O.S. Auto: Red activa de seguridad y asistencia 24/7',
      'color': const Color(0xFF0A192F),
      'icono': Icons.shield_outlined,
    },
  ];

  List _pautasVivas = [];
  List _robosVivos = [];
  List _accidentesVivos = [];
  List _emergenciasVivas = [];
  List _novedadesVivas = [];

  StreamSubscription? _pautasSub;
  StreamSubscription? _robosSub;
  StreamSubscription? _accidentesSub;
  StreamSubscription? _emergenciasSub;
  StreamSubscription? _novedadesSub;

  int _currentIndex = 0;
  Timer? _timer;

  List get _mensajes {
    final lista = [];
    // Prioridad 1: Alertas disparadas en esta sesión (instantáneas)
    lista.addAll(BannerDinamico.alertasLocales.value);
    // Prioridad 2: Alertas en tiempo real desde Firestore
    lista.addAll(_emergenciasVivas);
    lista.addAll(_robosVivos);
    lista.addAll(_accidentesVivos);
    lista.addAll(_novedadesVivas);
    lista.addAll(_pautasVivas);

    if (lista.isEmpty) {
      return _mensajesBase;
    }
    return [...lista, ..._mensajesBase];
  }

  @override
  void initState() {
    super.initState();
    BannerDinamico.alertasLocales.addListener(_onLocalAlertChanged);
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

  void _onLocalAlertChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _conectarFirestore() {
    try {
      if (Firebase.apps.isEmpty) return;
      final db = FirebaseFirestore.instance;

      // 1. Pautas comerciales aprobadas
      _pautasSub = db
          .collection('pautas_comerciales')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargadas = snap.docs.map((doc) {
          final d = doc.data();
          final nombre =
              (d['nombreComercio'] ?? 'Aliado S.O.S. Auto').toString();
          final servicio =
              (d['mensajeBanner'] ?? 'Asistencia 24/7').toString();
          return {
            'texto': '🏢 Aliado: $nombre — $servicio',
            'color': const Color(0xFF1B5E20),
            'icono': Icons.storefront,
          };
        }).toList();
        if (mounted) {
          setState(() => _pautasVivas = cargadas);
        }
      }, onError: (_) {});

      // 2. Vehículos robados activos
      _robosSub = db
          .collection('vehiculos_robados')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargados = snap.docs.map((doc) {
          final d = doc.data();
          final vehiculo =
              (d['detalleVehiculo'] ?? d['vehiculo'] ?? 'Vehículo').toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          return {
            'texto':
                '🚨 ROBO ACTIVO ($ciudad): $vehiculo ${placa.isNotEmpty ? "[$placa]" : ""}',
            'color': const Color(0xFFB71C1C),
            'icono': Icons.warning_amber_rounded,
          };
        }).toList();
        if (mounted) {
          setState(() => _robosVivos = cargados);
        }
      }, onError: (_) {});

      // 3. Accidentes activos en vía
      _accidentesSub = db
          .collection('accidentes')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargados = snap.docs.map((doc) {
          final d = doc.data();
          final gravedad = (d['gravedad'] ?? 'Accidente en vía').toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          return {
            'texto': '🚑 ACCIDENTE ($ciudad): $gravedad • Placa $placa',
            'color': const Color(0xFFC62828),
            'icono': Icons.car_crash,
          };
        }).toList();
        if (mounted) {
          setState(() => _accidentesVivos = cargados);
        }
      }, onError: (_) {});

      // 4. Emergencias SOS ("Estoy en peligro") activas
      _emergenciasSub = db
          .collection('emergencias_sos')
          .where('activa', isEqualTo: true)
          .snapshots()
          .listen((snap) {
        final cargadas = snap.docs.map((doc) {
          final d = doc.data();
          final amenaza = (d['amenaza'] ?? 'Emergencia SOS').toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          return {
            'texto': '🆘 SOS PELIGRO ($ciudad): $amenaza • Placa $placa',
            'color': const Color(0xFF8E0000),
            'icono': Icons.notifications_active,
          };
        }).toList();
        if (mounted) {
          setState(() => _emergenciasVivas = cargadas);
        }
      }, onError: (_) {});

      // 5. Novedades viales vigentes
      _novedadesSub = db
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(20)
          .snapshots()
          .listen((snap) {
        final ahora = DateTime.now();
        final cargadas = [];

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

          final tipo = (d['tipo'] ?? 'Novedad en vía').toString();
          final sector = (d['sector'] ?? '').toString();
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
          setState(() => _novedadesVivas = cargadas);
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    BannerDinamico.alertasLocales.removeListener(_onLocalAlertChanged);
    _timer?.cancel();
    _pautasSub?.cancel();
    _robosSub?.cancel();
    _accidentesSub?.cancel();
    _emergenciasSub?.cancel();
    _novedadesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _mensajes;
    final safeIndex = _currentIndex % lista.length;
    final mensajeActual = lista[safeIndex] as Map;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey('${safeIndex}_${mensajeActual['texto']}'),
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
