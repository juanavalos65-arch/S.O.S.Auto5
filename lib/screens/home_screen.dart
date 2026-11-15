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
  // Datos del vehículo registrado en sesión para compartirlos con los demás botones
  String? _placaRegistrada;
  String? _tipoVehiculoRegistrado;
  String? _detalleVehiculoRegistrado;
  String _ciudadActual = 'Medellín / Sincelejo';
  String _paisActual = 'Colombia';

  int _indiceBanner = 0;
  Timer? _timerBanner;

  final List> _bannersBase = [
    {
      'tipo': 'ALIADO COMERCIAL',
      'titulo': 'Grúas Express 24/7 • Auxilio Vial Inmediato',
      'subtitulo': 'Cobertura urbana y carretera • Acuerdo directo sin comisiones',
      'color': const Color(0xFF0B6E4F),
      'icono': Icons.local_shipping,
    },
    {
      'tipo': 'NOVEDAD EN LA VÍA',
      'titulo': 'Paso restringido Troncal de Occidente',
      'subtitulo': 'Cierre parcial por mantenimiento • Conduce con precaución',
      'color': const Color(0xFFE65100),
      'icono': Icons.traffic,
    },
    {
      'tipo': 'ALERTA COMUNIDAD S.O.S.',
      'titulo': 'Mantén tus documentos y contactos al día',
      'subtitulo': 'Registra tu placa y múltiples conductores en 1 minuto',
      'color': const Color(0xFF102A43),
      'icono': Icons.shield,
    },
  ];

  List> get _bannersDinamicos {
    final List> lista = [];

    // Sincroniza automáticamente novedades reportadas en ReportIncidentScreen
    for (final nov in NovedadesViaStore.novedadesActivas) {
      if (nov['enBanner'] == true) {
        lista.add({
          'tipo': 'NOVEDAD EN LA VÍA • ${(nov['tipo'] as String).toUpperCase()}',
          'titulo': nov['via'] as String,
          'subtitulo': nov['detalle'] as String,
          'color': const Color(0xFFE65100),
          'icono': Icons.warning_amber_rounded,
        });
      }
    }

    lista.addAll(_bannersBase);
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _timerBanner = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final total = _bannersDinamicos.length;
      if (total > 0) {
        setState(() {
          _indiceBanner = (_indiceBanner + 1) % total;
        });
      }
    });
  }

  @override
  void dispose() {
    _timerBanner?.cancel();
    super.dispose();
  }

  Future<void> _abrirRegistro() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterVehicleScreen()),
    );

    if (resultado is Map && mounted) {
      setState(() {
        _placaRegistrada = resultado['placa']?.toString() ?? _placaRegistrada;
        _tipoVehiculoRegistrado = resultado['tipo']?.toString() ?? _tipoVehiculoRegistrado;
        final marca = resultado['marca']?.toString() ?? '';
        final linea = resultado['linea']?.toString() ?? '';
        final color = resultado['color']?.toString() ?? '';
        final combinado = '$marca $linea$color'.trim();
        if (combinado.isNotEmpty) {
          _detalleVehiculoRegistrado = combinado;
        }
        if (resultado['ciudad'] != null && resultado['ciudad'].toString().isNotEmpty) {
          _ciudadActual = resultado['ciudad'].toString();
        }
        if (resultado['pais'] != null && resultado['pais'].toString().isNotEmpty) {
          _paisActual = resultado['pais'].toString();
        }
      });
    }
  }

  void _abrirPauteAqui() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PauteAquiScreen()),
    );
  }

  void _abrirMeVare() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeVareScreen(
          placaRegistrada: _placaRegistrada,
          tipoVehiculoRegistrado: _tipoVehiculoRegistrado,
          detalleVehiculoRegistrado: _detalleVehiculoRegistrado,
          ciudadActual: _ciudadActual,
        ),
      ),
    );
  }

  void _abrirAccidente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccidenteScreen(
          placaRegistrada: _placaRegistrada,
          tipoVehiculoRegistrado: _tipoVehiculoRegistrado,
          ciudadActual: _ciudadActual,
        ),
      ),
    );
  }

  void _abrirEstoyEnPeligro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencySosScreen(
          placaRegistrada: _placaRegistrada,
          tipoVehiculoRegistrado: _tipoVehiculoRegistrado,
          ciudadActual: _ciudadActual,
        ),
      ),
    );
  }

  void _abrirRoboAuto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StolenCarScreen(
          placaRegistrada: _placaRegistrada,
          tipoVehiculoRegistrado: _tipoVehiculoRegistrado,
          marcaModeloColorRegistrado: _detalleVehiculoRegistrado,
          ciudadActual: _ciudadActual,
        ),
      ),
    );
  }

  Future<void> _abrirNovedadesVia() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportIncidentScreen(ciudadActual: _ciudadActual),
      ),
    );
    if (mounted) {
      setState(() {
        _indiceBanner = 0;
      });
    }
  }

  void _abrirAgenteTransito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrafficStopScreen(
          placaRegistrada: _placaRegistrada,
          ciudadActual: _ciudadActual,
          paisActual: _paisActual,
        ),
      ),
    );
  }

  void _abrirListaAliados({String? categoriaInicial}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlliesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = _bannersDinamicos;
    final bannerActual = banners[_indiceBanner % banners.length];

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF0D1B2A), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'S.O.S. AUTO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mi Vehículo Registrado',
            onPressed: _abrirRegistro,
            icon: const Icon(Icons.directions_car),
          ),
          IconButton(
            tooltip: 'Directorio de Aliados',
            onPressed: () => _abrirListaAliados(),
            icon: const Icon(Icons.storefront),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner rotativo superior
            GestureDetector(
              onTap: () {
                final tipo = bannerActual['tipo'] as String;
                if (tipo.contains('NOVEDAD')) {
                  _abrirNovedadesVia();
                } else if (tipo.contains('ALIADO')) {
                  _abrirListaAliados();
                } else {
                  _abrirRegistro();
                }
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bannerActual['color'] as Color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      bannerActual['icono'] as IconData,
                      color: Colors.amberAccent,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bannerActual['tipo'] as String,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bannerActual['titulo'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bannerActual['subtitulo'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),

            // Zona central de Mapa GPS en modo prueba
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 64, color: Colors.blueGrey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Mapa GPS en modo prueba',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _placaRegistrada != null
                            ? '$_ciudadActual • Vehículo activo: $_placaRegistrada'
                            : '$_ciudadActual • Listo para API Key',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Panel inferior fijo con los 8 botones operativos
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'S.O.S. AUTO • ACCIONES Y EMERGENCIAS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.92,
                    children: [
                      _botonAccion(
                        titulo: 'Registro',
                        icono: Icons.app_registration,
                        colorFondo: const Color(0xFFE3F2FD),
                        colorIcono: const Color(0xFF1565C0),
                        onTap: _abrirRegistro,
                      ),
                      _botonAccion(
                        titulo: 'Paute aquí',
                        icono: Icons.campaign,
                        colorFondo: const Color(0xFFE0F2F1),
                        colorIcono: const Color(0xFF0B6E4F),
                        onTap: _abrirPauteAqui,
                      ),
                      _botonAccion(
                        titulo: 'Me varé',
                        icono: Icons.car_repair,
                        colorFondo: const Color(0xFFFFF3E0),
                        colorIcono: const Color(0xFFE65100),
                        onTap: _abrirMeVare,
                      ),
                      _botonAccion(
                        titulo: 'Accidente',
                        icono: Icons.car_crash,
                        colorFondo: const Color(0xFFFFEBEE),
                        colorIcono: const Color(0xFFC62828),
                        onTap: _abrirAccidente,
                      ),
                      _botonAccion(
                        titulo: 'Estoy en peligro',
                        icono: Icons.shield_outlined,
                        colorFondo: const Color(0xFFFFEBEE),
                        colorIcono: const Color(0xFFB71C1C),
                        onTap: _abrirEstoyEnPeligro,
                      ),
                      _botonAccion(
                        titulo: 'Robo de auto',
                        icono: Icons.directions_car_filled,
                        colorFondo: const Color(0xFFFCE4EC),
                        colorIcono: const Color(0xFF880E4F),
                        onTap: _abrirRoboAuto,
                      ),
                      _botonAccion(
                        titulo: 'Novedad en vía',
                        icono: Icons.alt_route,
                        colorFondo: const Color(0xFFE8EAF6),
                        colorIcono: const Color(0xFF283593),
                        onTap: _abrirNovedadesVia,
                      ),
                      _botonAccion(
                        titulo: 'Agente tránsito',
                        icono: Icons.local_police,
                        colorFondo: const Color(0xFFECEFF1),
                        colorIcono: const Color(0xFF102A43),
                        onTap: _abrirAgenteTransito,
                      ),
                    ],
                  ),
