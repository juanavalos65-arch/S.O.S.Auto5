import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerItemData {
  final String id;
  final String texto;
  final Color color;
  final IconData icono;
  final String tipo; // 'robo', 'emergencia', 'novedad', 'pauta'

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
  static final ValueNotifier<List<BannerItemData>> _localItems =
      ValueNotifier<List<BannerItemData>>([]);

  /// Publica inmediatamente una alerta en el banner local mientras se guarda en Firebase
  static Future<void> publicarLocal({
    required String id,
    required String texto,
    Color color = const Color(0xFFB71C1C),
    IconData icono = Icons.warning_amber_rounded,
    String tipo = 'robo',
  }) async {
    final actual = List<BannerItemData>.from(_localItems.value);
    actual.removeWhere((item) => item.id == id);
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
  static Future<void> quitarLocal(String id) async {
    final actual = List<BannerItemData>.from(_localItems.value);
    actual.removeWhere((item) => item.id == id);
    _localItems.value = actual;
  }

  @override
  State<BannerDinamico> createState() => _BannerDinamicoState();
}

class _BannerDinamicoState extends State<BannerDinamico> {
  final PageController _pageCtrl = PageController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  List<BannerItemData> _robosNube = [];
  List<BannerItemData> _novedadesNube = [];
  List<BannerItemData> _pautasNube = [];

  StreamSubscription? _subRobos;
  StreamSubscription? _subNovedades;
  StreamSubscription? _subPautas;

  static const List<BannerItemData> _pautasBase = [
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
    _escucharColeccionesNube();
    _iniciarRotacionAutomatica();
  }

  void _escucharColeccionesNube() {
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

    try {
      _subNovedades = FirebaseFirestore.instance
          .collection('novedades_via')
          .where('activa', isEqualTo: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _novedadesNube = snap.docs.map((doc) {
            final d = doc.data();
            final titulo = (d['titulo'] ?? d['tipo'] ?? 'Novedad vial').toString();
            final desc = (d['descripcion'] ?? d['mensaje'] ?? '').toString();
            return BannerItemData(
              id: doc.id,
              texto: '⚠️ $titulo${desc.isNotEmpty ? ": $desc" : ""}',
              color: const Color(0xFFE65100),
              icono: Icons.traffic_rounded,
              tipo: 'novedad',
            );
          }).toList();
        });
      }, onError: (_) {});
    } catch (_) {}

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
            final empresa = (d['empresa'] ?? 'Aliado S.O.S. Auto').toString();
            final anuncio = (d['mensaje'] ?? d['texto'] ?? '').toString();
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

  /// Intercala: Alertas locales -> Robos -> Pauta -> Novedades en vía
  List<BannerItemData> _construirListaIntercalada(
      List<BannerItemData> locales) {
    final idsLocales = locales.map((e) => e.id).toSet();
    final robosFiltrados =
        _robosNube.where((r) => !idsLocales.contains(r.id)).toList();
    final pautas = _pautasNube.isNotEmpty ? _pautasNube : _pautasBase;

    final resultado = <BannerItemData>[...locales];
    final maxLen = [
      robosFiltrados.length,
      pautas.length,
      _novedadesNube.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      if (i < robosFiltrados.length) resultado.add(robosFiltrados[i]);
      if (i < pautas.length) resultado.add(pautas[i]);
      if (i < _novedadesNube.length) resultado.add(_novedadesNube[i]);
    }

    return resultado.isEmpty ? _pautasBase : resultado;
  }

  void _iniciarRotacionAutomatica() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final items = _construirListaIntercalada(BannerDinamico._localItems.value);
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
    _autoScrollTimer?.cancel();
    _subRobos?.cancel();
    _subNovedades?.cancel();
    _subPautas?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BannerItemData>>(
      valueListenable: BannerDinamico._localItems,
      builder: (context, locales, _) {
        final items = _construirListaIntercalada(locales);
        return SizedBox(
          height: 52,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: items.length,
            onPageChanged: (index) => _currentIndex = index,
            itemBuilder: (context, index) {
              final item = items[index % items.length];
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
