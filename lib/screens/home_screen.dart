import 'dart:async';
import 'package:flutter/material.dart';

class _BannerItem {
  final String tipo;
  final String titulo;
  final String subtitulo;
  final Color color;
  final IconData icono;

  const _BannerItem({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.icono,
  });
}

class _MainButtonItem {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEmergency;

  const _MainButtonItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.isEmergency,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  static const List<_BannerItem> _bannerItems = [
    _BannerItem(
      tipo: 'ALIADO COMERCIAL',
      titulo: 'Grúas y Talleres 24/7 en Medellín y Sincelejo',
      subtitulo: '20% de descuento presentando tu app S.O.S. Auto',
      color: Color(0xFF1565C0),
      icono: Icons.local_shipping,
    ),
    _BannerItem(
      tipo: 'ALERTA VEHÍCULO ROBADO',
      titulo: 'Mazda 3 Gris - Placa KLM-456',
      subtitulo: 'Reportado hace 15 min. Si lo ves, toca aquí',
      color: Color(0xFFC62828),
      icono: Icons.warning_amber_rounded,
    ),
    _BannerItem(
      tipo: 'NOVEDAD EN LA VÍA',
      titulo: 'Paso restringido Troncal de Occidente',
      subtitulo: 'Cierre parcial por mantenimiento vial - Conduzca con precaución',
      color: Color(0xFFEF6C00),
      icono: Icons.traffic,
    ),
  ];

  final List<_MainButtonItem> _mainButtons = [
    _MainButtonItem(
      label: 'Registro',
      icon: Icons.app_registration,
      color: Colors.blue.shade800,
      isEmergency: false,
    ),
    _MainButtonItem(
      label: 'Paute aquí',
      icon: Icons.campaign,
      color: Colors.teal.shade700,
      isEmergency: false,
    ),
    _MainButtonItem(
      label: 'Me varé',
      icon: Icons.car_repair,
      color: Colors.amber.shade900,
      isEmergency: false,
    ),
    _MainButtonItem(
      label: 'Accidente',
      icon: Icons.car_crash,
      color: Colors.deepOrange.shade700,
      isEmergency: true,
    ),
    _MainButtonItem(
      label: 'Estoy en peligro',
      icon: Icons.gpp_maybe,
      color: Colors.red.shade700,
      isEmergency: true,
    ),
    _MainButtonItem(
      label: 'Robo de auto',
      icon: Icons.no_crash,
      color: Colors.red.shade900,
      isEmergency: true,
    ),
    _MainButtonItem(
      label: 'Novedades en la vía',
      icon: Icons.alt_route,
      color: Colors.indigo.shade700,
      isEmergency: false,
    ),
    _MainButtonItem(
      label: 'Agente de tránsito',
      icon: Icons.local_police,
      color: const Color(0xFF0D1B2A),
      isEmergency: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % _bannerItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _onButtonPressed(_MainButtonItem btn) {
    if (btn.isEmergency) {
      _triggerEmergencyWithoutPin(btn.label, btn.color);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ModuloOperativoScreen(
            titulo: btn.label,
            color: btn.color,
            icono: btn.icon,
          ),
        ),
      );
    }
  }

  // EMERGENCIA SIN PIN: Cuenta regresiva de 5 segundos con botón grande de cancelar
  void _triggerEmergencyWithoutPin(String serviceName, Color color) {
    int secondsLeft = 5;
    Timer? countdownTimer;
    bool cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (cancelled) {
                timer.cancel();
                return;
              }
              if (secondsLeft > 1) {
                setDialogState(() {
                  secondsLeft--;
                });
              } else {
                timer.cancel();
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                _showAlertSentScreen(serviceName, color);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      serviceName.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Activando protocolo de emergencia, ubicación GPS y notificación automática en:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      '$secondsLeft',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 26),
                      label: const Text(
                        'CANCELAR ALERTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      onPressed: () {
                        cancelled = true;
                        countdownTimer?.cancel();
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Alerta cancelada. No se envió ningún reporte.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
    });
  }

  void _showAlertSentScreen(String serviceName, Color color) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EmergenciaActivaScreen(
          tipoEmergencia: serviceName,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBanner = _bannerItems[_bannerIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'S.O.S. AUTO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car),
            tooltip: 'Mis Vehículos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ModuloOperativoScreen(
                    titulo: 'Registro',
                    color: Colors.blue.shade800,
                    icono: Icons.app_registration,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Aliados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ModuloOperativoScreen(
                    titulo: 'Paute aquí',
                    color: Colors.teal.shade700,
                    icono: Icons.campaign,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FONDO DE MAPA EN MODO PRUEBA (Quieto hasta tener la API Key)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECEF),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 72, color: Colors.blueGrey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Mapa GPS en modo prueba',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Medellín / Sincelejo • Listo para API Key',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // 2. BANNER DINÁMICO SUPERIOR
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: currentBanner.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(currentBanner.icono, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBanner.tipo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          currentBanner.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentBanner.subtitulo,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. PANEL FLOTANTE INFERIOR CON LOS 8 BOTONES OFICIALES
          Positioned(
            bottom: 14,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'S.O.S. AUTO • ACCIONES Y EMERGENCIAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mainButtons.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (context, index) {
                      final btn = _mainButtons[index];
                      return InkWell(
                        onTap: () => _onButtonPressed(btn),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: btn.color.withOpacity(0.11),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: btn.color.withOpacity(0.45),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(btn.icon, color: btn.color, size: 25),
                              const SizedBox(height: 4),
                              Text(
                                btn.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: btn.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PANTALLA PARA LOS 4 BOTONES OPERATIVOS (Registro, Paute aquí, Me varé, Novedades en la vía)
class _ModuloOperativoScreen extends StatefulWidget {
  final String titulo;
  final Color color;
  final IconData icono;

  const _ModuloOperativoScreen({
    required this.titulo,
    required this.color,
    required this.icono,
  });

  @override
  State<_ModuloOperativoScreen> createState() => _ModuloOperativoScreenState();
}

class _ModuloOperativoScreenState extends State<_ModuloOperativoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _campo1Controller = TextEditingController();
  final _campo2Controller = TextEditingController();
  final _detalleController = TextEditingController();
  String _tipoVehiculo = 'Automóvil';

  @override
  void dispose() {
    _campo1Controller.dispose();
    _campo2Controller.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esRegistro = widget.titulo == 'Registro';
    final esPauta = widget.titulo == 'Paute aquí';
    final esVare = widget.titulo == 'Me varé';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(widget.icono),
            const SizedBox(width: 8),
            Text(widget.titulo),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: widget.color.withOpacity(0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: widget.color.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    esRegistro
                        ? 'Registra tu placa, tipo de vehículo y vencimientos (SOAT / Tecnomecánica). Permite múltiples conductores por placa.'
                        : esPauta
                            ? 'Anuncia tu taller, grúa, aseguradora o comercio en el banner superior de S.O.S. Auto con pago seguro Wompi.'
                            : esVare
                                ? 'Solicita asistencia mecánica, grúa, batería o cerrajería en tu ubicación actual.'
                                : 'Reporta retenes, accidentes, cierres viales o peligros en la vía para alertar a la red de conductores.',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (esRegistro || esVare) ...[
                DropdownButtonFormField<String>(
                  value: _tipoVehiculo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Automóvil', child: Text('Automóvil')),
                    DropdownMenuItem(value: 'Motocicleta', child: Text('Motocicleta')),
                    DropdownMenuItem(value: 'Camioneta', child: Text('Camioneta')),
                    DropdownMenuItem(value: 'Camión', child: Text('Camión')),
                    DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                  ],
                  onChanged: (val) => setState(() => _tipoVehiculo = val!),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _campo1Controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: esRegistro
                      ? 'Placa del vehículo (Ej: KLM-456)'
                      : esPauta
                          ? 'Nombre de la empresa o taller'
                          : esVare
                              ? 'Placa del vehículo varado'
                              : 'Vía o sector de la novedad',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _campo2Controller,
                decoration: InputDecoration(
                  labelText: esRegistro
                      ? 'Marca, línea y color (Ej: Mazda 3 Gris)'
                      : esPauta
                          ? 'Teléfono / WhatsApp de contacto'
                          : esVare
                              ? 'Tipo de falla (Batería, Llanta, Grúa, Motor)'
                              : 'Tipo de novedad (Cierre, Obra, Derrumbe)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _detalleController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: esRegistro
                      ? 'Nombre del conductor y vencimiento SOAT'
                      : 'Observaciones adicionales',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    esRegistro
                        ? 'GUARDAR VEHÍCULO'
                        : esPauta
                            ? 'CONTINUAR A PAUTA WOMPI'
                            : 'ENVIAR REPORTE AHORA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.titulo}: Información registrada correctamente.'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PANTALLA ACTIVA CUANDO SE CONFIRMA UNA EMERGENCIA (TRAS LOS 5 SEGUNDOS)
class _EmergenciaActivaScreen extends StatelessWidget {
  final String tipoEmergencia;
  final Color color;

  const _EmergenciaActivaScreen({
    required this.tipoEmergencia,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final esAgente = tipoEmergencia == 'Agente de tránsito';

    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        foregroundColor: Colors.white,
        title: Text('S.O.S. ACTIVO • $tipoEmergencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.radar, color: Colors.white, size: 72),
            const SizedBox(height: 12),
            Text(
              'ALERTA DE ${tipoEmergencia.toUpperCase()} ENVIADA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              esAgente
                  ? 'Modo preventivo activado:\n• Mantén la calma y no discutas con el agente.\n• Grabación de audio/video lista para respaldo.\n• Consulta rápida del Código Nacional de Tránsito y abogados.'
                  : 'Se ha notificado a tus contactos de emergencia, autoridades y conductores cercanos de S.O.S. Auto con tu ubicación GPS en tiempo real.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
            const Spacer(),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'FINALIZAR Y VOLVER AL INICIO',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
