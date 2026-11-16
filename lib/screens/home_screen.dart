import 'dart:async';
import 'package:flutter/material.dart';
import 'register_vehicle_screen.dart';
import 'paute_aqui_screen.dart';
import 'me_vare_screen.dart';
import 'accidente_screen.dart';
import 'emergency_sos_screen.dart';
import 'stolen_car_screen.dart';
import 'report_incident_screen.dart';
import 'traffic_stop_screen.dart';
import 'allies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  String? _placaActiva;

  final List> _itemsBannerBase = [
    {
      'categoria': 'PAUTA COMERCIAL',
      'titulo': 'Grúas Express 24/7 — Cobertura Nacional',
      'subtitulo': 'Asistencia inmediata en carretera. Toca aquí para llamar.',
      'color': const Color(0xFF1565C0),
      'icono': Icons.local_shipping,
    },
    {
      'categoria': 'VEHÍCULO ROBADO',
      'titulo': 'ALERTA: Mazda 3 Gris — Placa KLM-456',
      'subtitulo': 'Reportado en Medellín. Si lo ves, avisa sin intervenir.',
      'color': const Color(0xFFB71C1C),
      'icono': Icons.warning_amber_rounded,
    },
    {
      'categoria': 'ALIADO DESTACADO',
      'titulo': 'Baterías y Serviteca El Camino',
      'subtitulo': 'Descuento del 15% para usuarios registrados en S.O.S. Auto.',
      'color': const Color(0xFF2E7D32),
      'icono': Icons.build_circle,
    },
  ];

  List> get _bannerCompleto {
    final List> lista = [];
    final novedades = ReportIncidentScreen.novedadesActivas;
    int maxLen = _itemsBannerBase.length > novedades.length
        ? _itemsBannerBase.length
        : novedades.length;

    for (int i = 0; i < maxLen; i++) {
      if (i < _itemsBannerBase.length) {
        lista.add(_itemsBannerBase[i]);
      }
      if (i < novedades.length) {
        lista.add({
          'categoria': 'NOVEDAD EN LA VÍA',
          'titulo': novedades[i]['titulo'] ?? 'Alerta vial',
          'subtitulo': '${novedades[i]['ubicacion']} • ${novedades[i]['hora']}',
          'color': const Color(0xFFE65100),
          'icono': Icons.traffic,
        });
      }
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _iniciarRotacionBanner();
  }

  void _iniciarRotacionBanner() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final int total = _bannerCompleto.length;
      if (total == 0) return;
      setState(() {
        _currentBannerIndex = ((_currentBannerIndex + 1) % total).toInt();
      });
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _abrirRegistro() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterVehicleScreen()),
    );
    if (resultado != null && resultado is Map && resultado['placa'] != null) {
      setState(() {
        _placaActiva = resultado['placa'].toString().toUpperCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsBanner = _bannerCompleto;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.car_crash, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'S.O.S. AUTO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  _placaActiva != null
                      ? 'Vehículo activo: $_placaActiva'
                      : 'Asistencia y Seguridad Vial 24/7',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Directorio de Aliados',
            icon: const Icon(Icons.store_mall_directory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlliesScreen()),
              );
            },
          ),
          TextButton.icon(
            onPressed: _abrirRegistro,
            icon: const Icon(Icons.person_add, color: Colors.amber, size: 18),
            label: Text(
              _placaActiva != null ? _placaActiva! : 'Registro',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 86,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: itemsBanner.length,
              onPageChanged: (index) {
                setState(() => _currentBannerIndex = index);
              },
              itemBuilder: (context, index) {
                final item = itemsBanner[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PauteAquiScreen()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
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
                        Icon(item['icono'] as IconData, color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['categoria'] as String,
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                item['titulo'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item['subtitulo'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EEF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 42,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'GPS Activo — Ubicación en Tiempo Real',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        const Text(
                          'Aliados y asistencia cercanos disponibles',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton.small(
                      heroTag: 'btn_aliados_mapa',
                      backgroundColor: const Color(0xFF0D1B2A),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlliesScreen()),
                        );
                      },
                      child: const Icon(Icons.near_me),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.35,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildModuloBoton(
                    titulo: 'Registro',
                    icono: Icons.app_registration,
                    color: const Color(0xFF1B4965),
                    onTap: _abrirRegistro,
                  ),
                  _buildModuloBoton(
                    titulo: 'Paute aquí',
                    icono: Icons.campaign,
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PauteAquiScreen()),
                    ),
                  ),
                  _buildModuloBoton(
                    titulo: 'Me varé',
                    icono: Icons.car_repair,
                    color: const Color(0xFFEF6C00),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MeVareScreen()),
                    ),
                  ),
                  _buildModuloBoton(
                    titulo: 'Accidente',
                    icono: Icons.car_crash,
                    color: const Color(0xFFC62828),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccidenteScreen()),
                    ),
                  ),
                  _buildModuloBoton(
                    titulo: 'Estoy en peligro',
                    icono: Icons.sos,
                    color: const Color(0xFF8E0000),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EstoyEnPeligroScreen()),
                    ),
                  ),
                  _buildModuloBoton(
                    titulo: 'Robo de auto',
                    icono: Icons.no_crash,
                    color: const Color(0xFF4A148C),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StolenCarScreen()),
                    ),
                  ),
                  _buildModuloBoton(
                    titulo: 'Novedades en la vía',
                    icono: Icons.add_road,
                    color: const Color(0xFFF57F17),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportIncidentScreen()),
                      );
                      setState(() {});
                    },
                  ),
                  _buildModuloBoton(
                    titulo: 'Agente de tránsito',
                    icono: Icons.local_police,
                    color: const Color(0xFF283593),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AgenteTransitoScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuloBoton({
    required String titulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icono, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
