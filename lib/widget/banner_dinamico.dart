import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerItemData {
  final String id;
  final String texto;
  final Color color;
  final IconData icono;
  final String tipo; // 'robo', 'accidente', 'emergencia', 'novedad', 'pauta'

  const BannerItemData({
    required this.id,
    required this.texto,
    required this.color,
    required this.icono,
    required this.tipo,
  });
}

class BannerDinamico extends StatefulWidget {
  const BannerDinamico({super.key});

  /// Notificador global para publicación instantánea (0 ms) desde cualquier pantalla
  static final ValueNotifier _localItems = ValueNotifier([]);

  /// Publica inmediatamente una alerta en el banner local mientras se guarda en Firebase
  static Future publicarLocal({
    required String id,
    required String texto,
    Color color = const Color(0xFFB71C1C),
    IconData icono = Icons.warning_amber_rounded,
    String tipo = 'alerta',
  }) async {
    final actual = List.from(_localItems.value as List);
    actual.removeWhere((item) => (item as BannerItemData).id == id);
    actual.insert(
      0,
      BannerItemData(
        id: id,
        texto: texto,
        color: color,
        icono: icono,
        tipo: tipo,
      ),
    );
    _localItems.value = actual;
  }

  /// Retira una alerta local del banner al desactivarla o cancelar
  static Future quitarLocal(String id) async {
    final actual = List.from(_localItems.value as List);
    actual.removeWhere((item) => (item as BannerItemData).id == id);
    _localItems.value = actual;
  }

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final PageController _pageCtrl = PageController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  List _robosNube = [];
  List _accidentesNube = [];
  List _emergenciasNube = [];
  List _novedadesNube = [];
  List _pautasNube = [];

  StreamSubscription? _subRobos;
  StreamSubscription? _subAccidentes;
  StreamSubscription? _subEmergencias;
  StreamSubscription? _subNovedades;
  StreamSubscription? _subPautas;

  static const List _pautasBase = [
    BannerItemData(
      id: 'pauta_base_1',
      texto:
          '📢 PAUTE AQUÍ: Anuncia tu taller, grúa o repuestos en S.O.S. Auto',
      color: Color(0xFF0D47A1),
      icono: Icons.campaign_rounded,
      tipo: 'pauta',
    ),
    BannerItemData(
      id: 'pauta_base_2',
      texto:
          '🛡️ S.O.S. AUTO: Asistencia vial directa sin intermediarios ni comisiones',
      color: Color(0xFF1B5E20),
      icono: Icons.verified_user_rounded,
      tipo: 'pauta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    BannerDinamico._localItems.addListener(_onLocalChanged);
    _escucharColeccionesNube();
    _iniciarRotacionAutomatica();
  }

  void _onLocalChanged() {
    if (!mounted) return;
    _currentIndex = 0;
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
    setState(() {});
  }

  void _escucharColeccionesNube() {
    // 1. Vehículos robados activos
    try {
      _subRobos = FirebaseFirestore.instance
          .collection('vehiculos_robados')
          .where('activa', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _robosNube = snap.docs.map((doc) {
            final d = doc.data();
            final placa = (d['placa'] ?? d['plate'] ?? '').toString();
            final vehiculo =
                (d['detalleVehiculo'] ?? d['vehiculo'] ?? 'Vehículo').toString();
            final ciudad = (d['ciudad'] ?? 'Colombia').toString();
            final detalle = (d['detalle'] ?? '').toString();
            final texto =
                '🚨 ROBO ACTIVO ($ciudad): $vehiculo [$placa]${detalle.isNotEmpty ? " • $detalle" : ""}';
            return BannerItemData(
              id: doc.id,
              texto: texto,
              color: const Color(0xFFB71C1C),
              icono: Icons.warning_amber_rounded,
              tipo: 'robo',
            );
          }).toList();
        });
      }, onError: (_) {});
    } catch (_) {}

    // 2. Accidentes viales activos
    try {
      _subAccidentes = FirebaseFirestore.instance
          .collection('accidentes')
          .where('activa', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _accidentesNube = snap.docs.map((doc) {
            final d = doc.data();
            final placa = (d['placa'] ?? '').toString();
            final vehiculo =
                (d['detalleVehiculo'] ?? 'Vehículo').toString();
            final gravedad = (d['gravedad'] ?? 'Accidente vial').toString();
            final ciudad = (d['ciudad'] ?? 'Colombia').toString();
            return BannerItemData(
              id: doc.id,
              texto: '🚑 ACCIDENTE ($ciudad): $gravedad • $vehiculo [$placa]',
              color: const Color(0xFFC62828),
              icono: Icons.car_crash,
              tipo: 'accidente',
            );
          }).toList();
        });
      }, onError: (_) {});
    } catch (_) {}

    // 3. Emergencias SOS (Persona en peligro) activas
    try {
      _subEmergencias = FirebaseFirestore.instance
          .collection('emergencias_sos')
          .where('activa', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _emergenciasNube = snap.docs.map((doc) {
            final d = doc.data();
            final placa = (d['placa'] ?? '').toString();
            final vehiculo = (d['vehiculo'] ?? 'Vehículo').toString();
            final amenaza = (d['amenaza'] ?? 'Persona en peligro').toString();
            final ciudad = (d['ciudad'] ?? 'Colombia').toString();
            return BannerItemData(
              id: doc.id,
              texto:
                  '🆘 PERSONA EN PELIGRO ($ciudad): $amenaza • $vehiculo [$placa]',
              color: const Color(0xFF8E0000),
              icono: Icons.notifications_active,
              tipo: 'emergencia',
            );
          }).toList();
        });
      }, onError: (_) {});
    } catch (_) {}

    // 4. Novedades viales vigentes (colección novedades_viales)
    try {
      _subNovedades = FirebaseFirestore.instance
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(15)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        final ahora = DateTime.now();
        final vigentes = [];
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
          final titulo = (d['tipo'] ?? d['titulo'] ?? 'Novedad vial').toString();
          final sector = (d['sector'] ?? '').toString();
          vigentes.add(
            BannerItemData(
              id: 'novedad_${doc.id}',
              texto: sector.isNotEmpty
                  ? '⚠️ $titulo • $sector'
                  : '⚠️ $titulo',
              color: esPermanente
                  ? const Color(0xFFC62828)
                  : const Color(0xFFE65100),
              icono: esPermanente ? Icons.speed : Icons.traffic_rounded,
              tipo: 'novedad',
            ),
          );
        }
        setState(() => _novedadesNube = vigentes);
      }, onError: (_) {});
    } catch (_) {}

    // 5. Pautas comerciales aprobadas
    try {
      _subPautas = FirebaseFirestore.instance
          .collection('pautas_comerciales')
          .where('activa', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _pautasNube = snap.docs.map((doc) {
            final d = doc.data();
            final empresa =
                (d['nombreComercio'] ?? d['empresa'] ?? 'Aliado S.O.S. Auto')
                    .toString();
            final anuncio =
                (d['mensajeBanner'] ?? d['mensaje'] ?? d['texto'] ?? '')
                    .toString();
            return BannerItemData(
              id: doc.id,
              texto: '🏢 $empresa: $anuncio',
              color: const Color(0xFF0D47A1),
              icono: Icons.storefront_rounded,
              tipo: 'pauta',
            );
          }).toList();
        });
      }, onError: (_) {});
    } catch (_) {}
  }

  List _construirListaIntercalada(List locales) {
    final Set idsVistos = Set();
    final List alertasActivas = [];

    void agregar(List origen) {
      for (final raw in origen) {
        final item = raw as BannerItemData;
        if (idsVistos.add(item.id)) {
          alertasActivas.add(item);
        }
      }
    }

    agregar(locales);
    agregar(_emergenciasNube);
    agregar(_robosNube);
    agregar(_accidentesNube);
    agregar(_novedadesNube);

    final pautas = _pautasNube.isNotEmpty ? _pautasNube : _pautasBase;
    if (alertasActivas.isEmpty) return pautas;

    final List resultado = [...alertasActivas];
    for (final p in pautas) {
      final item = p as BannerItemData;
      if (idsVistos.add(item.id)) {
        resultado.add(item);
      }
    }
    return resultado;
  }

  void _iniciarRotacionAutomatica() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final items =
          _construirListaIntercalada(BannerDinamico._localItems.value as List);
      if (items.length <= 1) return;
      _currentIndex = (_currentIndex + 1) % items.length;
      _pageCtrl.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    BannerDinamico._localItems.removeListener(_onLocalChanged);
    _autoScrollTimer?.cancel();
    _subRobos?.cancel();
    _subAccidentes?.cancel();
    _subEmergencias?.cancel();
    _subNovedades?.cancel();
    _subPautas?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BannerDinamico._localItems,
      builder: (context, localesRaw, _) {
        final items = _construirListaIntercalada(localesRaw as List);
        return SizedBox(
          height: 54,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: items.length,
            onPageChanged: (index) => _currentIndex = index,
            itemBuilder: (context, index) {
              final item = items[index % items.length] as BannerItemData;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(item.icono, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
