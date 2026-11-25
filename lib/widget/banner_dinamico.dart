import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/emergency_sound_service.dart';

class BannerDinamico extends StatefulWidget {
  final void Function(Map<String, dynamic> item)? onTapItem;

  const BannerDinamico({
    super.key,
    this.onTapItem,
  });

  static const String _prefsKey = 'sos_auto_alertas_persistentes_v1';

  /// Canal instantáneo en memoria + persistencia automática en disco
  static final ValueNotifier<List>> alertasLocales =
      ValueNotifier<List>>([]);

  static bool _cargadoDesdeDisco = false;

  static Future<void> cargarPersistentes() async {
    if (_cargadoDesdeDisco) return;
    _cargadoDesdeDisco = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw) as List<dynamic>;
      final restauradas = decoded.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return <String, dynamic>{
          'id': m['id'] ?? '',
          'texto': m['texto'] ?? '',
          'color': Color((m['colorValue'] as int?) ?? 0xFFB71C1C),
          'icono': IconData(
            (m['iconCode'] as int?) ?? Icons.warning_amber_rounded.codePoint,
            fontFamily: 'MaterialIcons',
          ),
          'tipo': m['tipo'] ?? 'local',
        };
      }).toList();

      alertasLocales.value = restauradas;
    } catch (_) {}
  }

  static Future<void> _guardarEnDisco(List> lista) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializable = lista.map((m) {
        final color = m['color'] as Color? ?? const Color(0xFFB71C1C);
        final icono = m['icono'] as IconData? ?? Icons.warning_amber_rounded;
        return {
          'id': m['id'],
          'texto': m['texto'],
          'colorValue': color.value,
          'iconCode': icono.codePoint,
          'tipo': m['tipo'] ?? 'local',
        };
      }).toList();
      await prefs.setString(_prefsKey, jsonEncode(serializable));
    } catch (_) {}
  }

  static Future<void> publicarLocal({
    required String id,
    required String texto,
    required Color color,
    required IconData icono,
    String? tipo,
  }) async {
    await cargarPersistentes();
    final actual = List>.from(alertasLocales.value);
    actual.removeWhere((e) => e['id'] == id);
    actual.insert(0, {
      'id': id,
      'texto': texto,
      'color': color,
      'icono': icono,
      'tipo': tipo ?? 'local',
    });
    alertasLocales.value = actual;

    // Dispara sirena + vibración inmediatamente si es robo, accidente o peligro
    final t = (tipo ?? 'local').toLowerCase();
    if (t == 'robo' || t == 'accidente' || t == 'emergencia' || t == 'local') {
      final cat = (t == 'robo') ? 'stolen' : 'incident';
      unawaited(EmergencySoundService.checkAndSound([
        {'id': id, 'category': cat},
      ]));
    }

    await _guardarEnDisco(actual);
  }

  static Future<void> quitarLocal(String id) async {
    await cargarPersistentes();
    final actual = List>.from(alertasLocales.value);
    actual.removeWhere((e) => e['id'] == id);
    alertasLocales.value = actual;
    await _guardarEnDisco(actual);
  }

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final List> _mensajesBase = [
    {
      'texto': '🏢 Pauta Aquí: Anuncie su taller o grúa — Wompi / Bre-B',
      'color': const Color(0xFF1B5E20),
      'icono': Icons.business,
      'tipo': 'pauta_cta',
    },
    {
      'texto': '🚨 S.O.S. Auto: Red activa de seguridad y asistencia 24/7',
      'color': const Color(0xFF0A192F),
      'icono': Icons.shield_outlined,
      'tipo': 'info',
    },
  ];

  List> _pautasVivas = [];
  List> _robosVivos = [];
  List> _accidentesVivos = [];
  List> _emergenciasVivas = [];
  List> _novedadesVivas = [];

  StreamSubscription<QuerySnapshot>>? _pautasSub;
  StreamSubscription<QuerySnapshot>>? _robosSub;
  StreamSubscription<QuerySnapshot>>? _accidentesSub;
  StreamSubscription<QuerySnapshot>>? _emergenciasSub;
  StreamSubscription<QuerySnapshot>>? _novedadesSub;

  int _currentIndex = 0;
  Timer? _timer;

  bool _esRegistroActivo(Map<String, dynamic> d) {
    if (d['activa'] == false || d['activo'] == false) return false;
    final estado = (d['estado'] ?? '').toString().toLowerCase();
    if (estado == 'cerrado' ||
        estado == 'resuelto' ||
        estado == 'cancelado' ||
        estado == 'inactivo') {
      return false;
    }
    return true;
  }

  List> get _mensajes {
    final idsFirestore = <String>{
      ..._emergenciasVivas.map((e) => (e['id'] ?? '').toString()),
      ..._robosVivos.map((e) => (e['id'] ?? '').toString()),
      ..._accidentesVivos.map((e) => (e['id'] ?? '').toString()),
      ..._novedadesVivas.map((e) => (e['id'] ?? '').toString()),
    };

    final localesFiltradas = BannerDinamico.alertasLocales.value
        .where((e) => !idsFirestore.contains((e['id'] ?? '').toString()))
        .toList();

    final lista = >[
      ...localesFiltradas,
      ..._emergenciasVivas,
      ..._robosVivos,
      ..._accidentesVivos,
      ..._novedadesVivas,
      ..._pautasVivas,
    ];

    if (lista.isEmpty) {
      return _mensajesBase;
    }
    return [...lista, ..._mensajesBase];
  }

  @override
  void initState() {
    super.initState();
    BannerDinamico.alertasLocales.addListener(_onLocalAlertChanged);
    _inicializar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final total = _mensajes.length;
      if (total <= 1) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % total;
      });
    });
  }

  Future<void> _inicializar() async {
    await BannerDinamico.cargarPersistentes();
    if (mounted) setState(() {});
    _conectarFirestore();
  }

  void _onLocalAlertChanged() {
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
    });
  }

  void _conectarFirestore() {
    try {
      if (Firebase.apps.isEmpty) return;
      final db = FirebaseFirestore.instance;

      // 1. Pautas comerciales
      _pautasSub = db
          .collection('pautas_comerciales')
          .limit(30)
          .snapshots()
          .listen((snap) {
        final ahora = DateTime.now();
        final cargadas = >[];

        for (final doc in snap.docs) {
          final d = doc.data();
          if (!_esRegistroActivo(d)) continue;
          final expiraTs = d['fechaVencimiento'] as Timestamp?;
          if (expiraTs != null && expiraTs.toDate().isBefore(ahora)) continue;

          final nombre =
              (d['nombreComercio'] ?? 'Aliado S.O.S. Auto').toString();
          final servicio =
              (d['mensajeBanner'] ?? 'Asistencia 24/7').toString();
          cargadas.add({
            'id': doc.id,
            'texto': '🏢 Aliado: $nombre — $servicio',
            'color': const Color(0xFF1B5E20),
            'icono': Icons.storefront,
            'tipo': 'pauta',
            'payload': d,
          });
        }
        if (mounted) setState(() => _pautasVivas = cargadas);
      }, onError: (e) {
        debugPrint('Firestore pautas_comerciales error: $e');
      });

      // 2. Vehículos robados activos
      _robosSub = db
          .collection('vehiculos_robados')
          .limit(30)
          .snapshots()
          .listen((snap) {
        final cargados = >[];
        final paraSirena = >[];
        for (final doc in snap.docs) {
          final d = doc.data();
          if (!_esRegistroActivo(d)) continue;

          final vehiculo = (d['detalleVehiculo'] ??
                  d['vehiculo'] ??
                  d['modelo'] ??
                  'Vehículo')
              .toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          final prefijoCiudad = ciudad.isNotEmpty ? ' ($ciudad)' : '';

          cargados.add({
            'id': doc.id,
            'texto':
                '🚨 ROBO ACTIVO$prefijoCiudad: $vehiculo ${placa.isNotEmpty ? "[$placa]" : ""}',
            'color': const Color(0xFFB71C1C),
            'icono': Icons.warning_amber_rounded,
            'tipo': 'robo',
            'payload': d,
          });
          paraSirena.add({'id': doc.id, 'category': 'stolen'});
        }
        if (paraSirena.isNotEmpty) {
          unawaited(EmergencySoundService.checkAndSound(paraSirena));
        }
        if (mounted) setState(() => _robosVivos = cargados);
      }, onError: (e) {
        debugPrint('Firestore vehiculos_robados error: $e');
      });

      // 3. Accidentes activos en vía
      _accidentesSub = db
          .collection('accidentes')
          .limit(30)
          .snapshots()
          .listen((snap) {
        final cargados = >[];
        final paraSirena = >[];
        for (final doc in snap.docs) {
          final d = doc.data();
          if (!_esRegistroActivo(d)) continue;

          final gravedad = (d['gravedad'] ?? 'Accidente en vía').toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          final prefijoCiudad = ciudad.isNotEmpty ? ' ($ciudad)' : '';

          cargados.add({
            'id': doc.id,
            'texto':
                '🚑 ACCIDENTE$prefijoCiudad: $gravedad${placa.isNotEmpty ? " • Placa $placa" : ""}',
            'color': const Color(0xFFC62828),
            'icono': Icons.car_crash,
            'tipo': 'accidente',
            'payload': d,
          });
          paraSirena.add({'id': doc.id, 'category': 'incident'});
        }
        if (paraSirena.isNotEmpty) {
          unawaited(EmergencySoundService.checkAndSound(paraSirena));
        }
        if (mounted) setState(() => _accidentesVivos = cargados);
      }, onError: (e) {
        debugPrint('Firestore accidentes error: $e');
      });

      // 4. Emergencias SOS ("Estoy en peligro") activas
      _emergenciasSub = db
          .collection('emergencias_sos')
          .limit(30)
          .snapshots()
          .listen((snap) {
        final cargadas = >[];
        final paraSirena = >[];
        for (final doc in snap.docs) {
          final d = doc.data();
          if (!_esRegistroActivo(d)) continue;

          final amenaza = (d['amenaza'] ?? 'Emergencia SOS').toString();
          final placa = (d['placa'] ?? '').toString().toUpperCase();
          final ciudad = (d['ciudad'] ?? '').toString();
          final prefijoCiudad = ciudad.isNotEmpty ? ' ($ciudad)' : '';

          cargadas.add({
            'id': doc.id,
            'texto':
                '🆘 SOS PELIGRO$prefijoCiudad: $amenaza${placa.isNotEmpty ? " • Placa $placa" : ""}',
            'color': const Color(0xFF8E0000),
            'icono': Icons.notifications_active,
            'tipo': 'emergencia',
            'payload': d,
          });
          paraSirena.add({'id': doc.id, 'category': 'incident'});
        }
        if (paraSirena.isNotEmpty) {
          unawaited(EmergencySoundService.checkAndSound(paraSirena));
        }
        if (mounted) setState(() => _emergenciasVivas = cargadas);
      }, onError: (e) {
        debugPrint('Firestore emergencias_sos error: $e');
      });

      // 5. Novedades viales vigentes
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
          if (!_esRegistroActivo(d)) continue;

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
            'id': doc.id,
            'texto': sector.isNotEmpty
                ? '⚠️ Novedad en Vía: $tipo · $sector'
                : '⚠️ Novedad en Vía: $tipo',
            'color': esPermanente
                ? const Color(0xFFC62828)
                : const Color(0xFFE65100),
            'icono': esPermanente ? Icons.speed : Icons.traffic,
            'tipo': 'novedad',
            'payload': d,
          });
        }

        if (mounted) setState(() => _novedadesVivas = cargadas);
      }, onError: (e) {
        debugPrint('Firestore novedades_viales error: $e');
      });
    } catch (e) {
      debugPrint('Error conectando Firestore en BannerDinamico: $e');
    }
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
    final mensajeActual = lista[safeIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        key: ValueKey('${safeIndex}_${mensajeActual['texto']}'),
        onTap: widget.onTapItem != null
            ? () => widget.onTapItem!(mensajeActual)
            : null,
        child: Container(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lista.length > 1) ...[
                const SizedBox(width: 8),
                Text(
                  '${safeIndex + 1}/${lista.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
