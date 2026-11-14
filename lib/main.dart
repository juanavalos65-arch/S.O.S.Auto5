import 'dart:async';
import 'package:flutter/material.dart';

// Importación de pantallas del proyecto S.O.S. Auto
import 'register_vehicle_screen.dart';
import 'paute_aqi_screen.dart';
import 'me_vare_screen.dart';
import 'repot_incident_screen.dart';
import 'stolen_car_screen.dart';
import 'emergency_sos_screen.dart';

void main() {
  runApp(const SosAutoApp());
}

class SosAutoApp extends StatelessWidget {
  const SosAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S. AUTO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceBanner = 0;
  Timer? _bannerTimer;

  // Datos dinámicos del banner superior (Aliados, Vehículos robados, Novedades)
  final List> _itemsBanner = [
    {
      'tipo': 'NOVEDAD EN LA VÍA',
      'titulo': 'Paso restringido Troncal de Occidente',
      'subtitulo': 'Cierre parcial por mantenimiento vial',
      'color': const Color(0xFFB45309),
      'icono': Icons.traffic,
    },
    {
      'tipo': 'ALIADO COMERCIAL',
      'titulo': 'Grúas y Talleres 24/7 en tu zona',
      'subtitulo': '20% de descuento presentando S.O.S. Auto',
      'color': const Color(0xFF1E3A8A),
      'icono': Icons.local_shipping,
    },
    {
      'tipo': 'ALERTA VEHÍCULO ROBADO',
      'titulo': 'Mazda 3 Gris - Placa KLM-456',
      'subtitulo': 'Reportado hace 15 min. Si lo ve, reporte aquí',
      'color': const Color(0xFF991B1B),
      'icono': Icons.warning_amber_rounded,
    },
  ];

  // Configuración de los 8 botones principales
  final List> _botones = [
    {
      'titulo': 'Registro',
      'icono': Icons.app_registration,
      'color': const Color(0xFF1E40AF),
      'bgColor': const Color(0xFFDBEAFE),
      'esEmergencia': false,
    },
    {
      'titulo': 'Paute aquí',
      'icono': Icons.campaign,
      'color': const Color(0xFF065F46),
      'bgColor': const Color(0xFFD1FAE5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Me varé',
      'icono': Icons.car_repair,
      'color': const Color(0xFF9A3412),
      'bgColor': const Color(0xFFFFEDD5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Accidente',
      'icono': Icons.car_crash,
      'color': const Color(0xFF991B1B),
      'bgColor': const Color(0xFFFEE2E2),
      'esEmergencia': true,
    },
    {
      'titulo': 'Estoy en peligro',
      'icono': Icons.gpp_maybe,
      'color': const Color(0xFF7F1D1D),
      'bgColor': const Color(0xFFFECACA),
      'esEmergencia': true,
    },
    {
      'titulo': 'Robo de auto',
      'icono': Icons.no_crash,
      'color': const Color(0xFF881337),
      'bgColor': const Color(0xFFFFE4E6),
      'esEmergencia': true,
    },
    {
      'titulo': 'Novedades en la vía',
      'icono': Icons.alt_route,
      'color': const Color(0xFF3730A3),
      'bgColor': const Color(0xFFE0E7FF),
      'esEmergencia': false,
    },
    {
      'titulo': 'Agente de tránsito',
      'icono': Icons.local_police,
      'color': const Color(0xFF1F2937),
      'bgColor': const Color(0xFFE5E7EB),
      'esEmergencia': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _indiceBanner = (_indiceBanner + 1) % _itemsBanner.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _alPresionarBoton(Map<String, dynamic> boton) {
    final String titulo = boton['titulo'];
    final bool esEmergencia = boton['esEmergencia'];

    if (esEmergencia) {
      _mostrarDialogo5Segundos(titulo);
    } else {
      _navegarAPantalla(titulo);
    }
  }

  void _navegarAPantalla(String titulo) {
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
        destino = EmergencySosScreen(initialCategory: titulo);
        break;
    }

    if (destino != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destino!),
      );
    }
  }

  void _mostrarDialogo5Segundos(String tipoAlerta) {
    int segundosRestantes = 5;
    Timer? cuentaRegresiva;
    bool cancelada = false;

    showDialog(
      context: context,
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
                _dispararAlertaConfirmada(tipoAlerta);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.red, size: 30),
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
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Alerta desactivada.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 24),
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

  void _dispararAlertaConfirmada(String tipoAlerta) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Alerta "$tipoAlerta" enviada con ubicación GPS.'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
    _navegarAPantalla(tipoAlerta);
  }

  @override
  Widget build(BuildContext context) {
    final bannerActual = _itemsBanner[_indiceBanner];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'S.O.S. AUTO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'Mis Vehículos',
            onPressed: () => _navegarAPantalla('Registro'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi Perfil',
            onPressed: () => _navegarAPantalla('Registro'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FONDO DE MAPA INTERACTIVO
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE2E8F0),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.my_location, size: 42, color: Color(0xFF1E3A8A)),
                  SizedBox(height: 8),
                  Text(
                    'Mapa GPS Activo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. BANNER SUPERIOR DINÁMICO
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                if (bannerActual['tipo'] == 'NOVEDAD EN LA VÍA') {
                  _navegarAPantalla('Novedades en la vía');
                } else if (bannerActual['tipo'] == 'ALERTA VEHÍCULO ROBADO') {
                  _navegarAPantalla('Robo de auto');
                } else {
                  _navegarAPantalla('Me varé');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bannerActual['color'],
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(bannerActual['icono'], color: Colors.white, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bannerActual['tipo'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            bannerActual['titulo'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bannerActual['subtitulo'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. CUADRÍCULA INFERIOR FLOTANTE DE 8 BOTONES
          Positioned(
            left: 10,
            right: 10,
            bottom: 14,
            child: Container(
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
                  return InkWell(
                    onTap: () => _alPresionarBoton(btn),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: btn['bgColor'],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (btn['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(btn['icono'], color: btn['color'], size: 26),
                          const SizedBox(height: 5),
                          Text(
                            btn['titulo'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: btn['color'],
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
            ),
          ),
        ],
      ),
    );
  }
}
