import 'dart:async';
import 'package:flutter/material.dart';

class AccidenteScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? tipoVehiculoRegistrado;
  final String? ciudadActual;
  final String? pinCancelacion;

  const AccidenteScreen({
    super.key,
    this.placaRegistrada,
    this.tipoVehiculoRegistrado,
    this.ciudadActual,
    this.pinCancelacion,
  });

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  final TextEditingController _descripcionCtrl = TextEditingController();

  // Gravedades: 'leve', 'danos_graves', 'lesionados', 'fallecidos'
  String _gravedadSeleccionada = 'leve';
  bool _alertaActualizada = false;

  // Cuenta regresiva visual de 5 segundos para cancelación rápida
  int _segundosVentana = 5;
  Timer? _timerVentana;

  // Bitácora de despachos en Modo Simulacro
  final List> _bitacoraSimulacro = [];

  String get _placaActiva =>
      (widget.placaRegistrada != null && widget.placaRegistrada!.trim().isNotEmpty)
          ? widget.placaRegistrada!.trim().toUpperCase()
          : 'VEHÍCULO REGISTRADO';

  String get _tipoActivo =>
      (widget.tipoVehiculoRegistrado != null && widget.tipoVehiculoRegistrado!.trim().isNotEmpty)
          ? widget.tipoVehiculoRegistrado!.trim()
          : 'Automóvil';

  String get _ubicacionActiva =>
      (widget.ciudadActual != null && widget.ciudadActual!.trim().isNotEmpty)
          ? widget.ciudadActual!.trim()
          : 'GPS Simulado (6.2442° N, 75.5812° W)';

  String get _pinValido =>
      (widget.pinCancelacion != null && widget.pinCancelacion!.trim().isNotEmpty)
          ? widget.pinCancelacion!.trim()
          : '1234';

  final List> _tiposAccidente = [
    {
      'id': 'leve',
      'titulo': 'Choque leve',
      'subtitulo': 'Solo daños materiales menores',
      'prioridad': 'MEDIA (Tránsito / Aseguradora)',
      'icono': Icons.car_crash_outlined,
      'color': const Color(0xFFEF6C00),
      'categoriaColaborador': 'Talleres de Latonería y Peritaje',
      'alertaLegal':
          'En choques simples (solo latas) sin heridos, toma fotos/video de posición y retira los vehículos a la orilla para no bloquear la vía.',
      'recomendaciones': [
        'Enciende de inmediato las luces estacionarias y ponte el chaleco reflectivo antes de bajar.',
        'Coloca los conos o triángulos reflectivos a 30–50 metros detrás del vehículo.',
        'Toma fotografías panorámicas y de detalle de las placas, daños y señalización vial antes de mover los carros.',
        'Intercambia datos con el otro conductor (cédula, licencia, SOAT, póliza y teléfono) sin entrar en confrontaciones.',
        'Si cuentas con póliza todo riesgo, contacta a tu aseguradora o un perito aliado abajo.',
      ],
    },
    {
      'id': 'danos_graves',
      'titulo': 'Daños graves al vehículo',
      'subtitulo': 'Inmovilizado, volcamiento o derrame',
      'prioridad': 'ALTA (Tránsito / Bomberos / Grúa)',
      'icono': Icons.minor_crash,
      'color': const Color(0xFFD84315),
      'categoriaColaborador': 'Grúas Cama Baja y Rescate Vehicular',
      'alertaLegal':
          'Si hay derrame de combustible o aceite, aléjate mínimo 20 metros, apaga el switch y no enciendas cigarrillos ni celulares cerca del derrame.',
      'recomendaciones': [
        'Desconecta el encendido del motor inmediatamente para evitar cortocircuitos o incendio.',
        'Coloca triángulos reflectivos en ambos sentidos si el vehículo quedó atravesado en la calzada.',
        'Verifica que todos los ocupantes salgan del vehículo y se ubiquen detrás de la baranda de seguridad.',
        'Reporta el bloqueo vial a tránsito (Línea 123 / #767) para abanderamiento de la vía.',
        'Solicita una grúa cama baja del directorio inferior para evitar daños mayores en la transmisión.',
      ],
    },
    {
      'id': 'lesionados',
      'titulo': 'Personas lesionadas',
      'subtitulo': 'Heridos que requieren auxilio médico',
      'prioridad': 'CRÍTICA (Ambulancia 123 / Policía Tránsito)',
      'icono': Icons.medical_services,
      'color': const Color(0xFFC62828),
      'categoriaColaborador': 'Ambulancias y Asistencia Médica',
      'alertaLegal':
          'PROHIBIDO mover los vehículos cuando hay personas lesionadas hasta que llegue la autoridad de tránsito (salvo riesgo inminente de incendio).',
      'recomendaciones': [
        'Prioriza la vida: llama de inmediato al 123 (Emergencias) e indica número exacto de heridos y estado de conciencia.',
        'NO muevas a los heridos ni les quites el casco (si son motociclistas), pues puedes agravar lesiones cervicales.',
        'Primeros auxilios básicos: si hay sangrado activo, haz presión directa con un paño limpio o gasa.',
        'Mantén abrigado y tranquilo al lesionado; no le des agua ni medicamentos.',
        'Señaliza con conos a 50 metros para proteger a quienes prestan los primeros auxilios en la vía.',
      ],
    },
    {
      'id': 'fallecidos',
      'titulo': 'Con víctimas fatales',
      'subtitulo': 'Siniestro grave con fallecidos',
      'prioridad': 'MÁXIMA (123 / Criminalística Vial / Fiscalía)',
      'icono': Icons.emergency,
      'color': const Color(0xFF8E0000),
      'categoriaColaborador': 'Abogados de Tránsito y Defensa Penal Vial',
      'alertaLegal':
          'ESCENA JUDICIAL: No alteres ni muevas absolutamente nada del lugar. Permanece en el sitio y solicita acompañamiento legal inmediato.',
      'recomendaciones': [
        'Asegura el perímetro con triángulos reflectivos y luces estacionarias para evitar un segundo choque.',
        'Notifica inmediatamente a la Policía de Tránsito y Fiscalía (Línea 123) para levantamiento e inspección técnica.',
        'Verifica si hay sobrevivientes que requieran primeros auxilios urgentes mientras llegan las ambulancias.',
        'No abandones el lugar de los hechos ni rindas declaraciones sin asesoría de un abogado penalista de tránsito.',
        'Contacta de urgencia a un abogado especialista en siniestros viales de la lista inferior.',
      ],
    },
  ];

  final List> _colaboradoresAccidente = [
    {
      'nombre': 'Ambulancias Médicas Vital 24/7',
      'categorias': ['Ambulancias y Asistencia Médica'],
      'zona': 'Despacho Inmediato Urbano y Carretera',
      'distancia': '1.4 km',
      'tiempo': '10 min',
      'telefono': '+57 311 647 9280',
      'verificado': true,
    },
    {
      'nombre': 'Grúas Plataforma Cama Baja S.O.S.',
      'categorias': ['Grúas Cama Baja y Rescate Vehicular', 'Talleres de Latonería y Peritaje'],
      'zona': 'Cobertura Metropolitana y Autopistas',
      'distancia': '1.9 km',
      'tiempo': '18 min',
      'telefono': '+57 300 412 8890',
      'verificado': true,
    },
    {
      'nombre': 'Jurídica Vial — Abogados de Tránsito 24h',
      'categorias': ['Abogados de Tránsito y Defensa Penal Vial', 'Ambulancias y Asistencia Médica'],
      'zona': 'Atención Presencial en Escena y Audiencias',
      'distancia': '2.3 km',
      'tiempo': '20 min',
      'telefono': '+57 315 789 3321',
      'verificado': true,
    },
    {
      'nombre': 'Centro de Colisión, Latonería y Peritaje Express',
      'categorias': ['Talleres de Latonería y Peritaje', 'Grúas Cama Baja y Rescate Vehicular'],
      'zona': 'Zona Industrial y Sector Automotriz',
      'distancia': '2.8 km',
      'tiempo': '25 min',
      'telefono': '+57 312 654 1109',
      'verificado': true,
    },
    {
      'nombre': 'Defensa Legal Siniestros & Aseguradoras',
      'categorias': ['Abogados de Tránsito y Defensa Penal Vial', 'Talleres de Latonería y Peritaje'],
      'zona': 'Cobertura Regional',
      'distancia': '3.5 km',
      'tiempo': '30 min',
      'telefono': '+57 318 902 4410',
      'verificado': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarVentanaAnulacion();
    _registrarEventosInicialesSimulacro();
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _registrarEventosInicialesSimulacro() {
    final hora = _horaActual();
    _bitacoraSimulacro.addAll([
      {
        'hora': hora,
        'destinatario': 'Contactos de Emergencia (WhatsApp / SMS)',
        'estado': 'SIMULADO OK',
        'detalle':
            'Alerta inicial S.O.S. Auto enviada con ubicación $_ubicacionActiva y placa $_placaActiva.',
      },
      {
        'hora': hora,
        'destinatario': 'Organismos de Socorro (Línea 123 / Tránsito)',
        'estado': 'SIMULADO OK',
        'detalle':
            'Paquete telemático de siniestro despachado en modo prueba (${_accidenteActual['titulo']}).',
      },
      {
        'hora': hora,
        'destinatario': 'Conductores Cercanos S.O.S. Auto (Radio 3 km)',
        'estado': 'SIMULADO OK',
        'detalle': 'Notificación preventiva en mapa comunitario para precaución en la vía.',
      },
    ]);
  }

  void _iniciarVentanaAnulacion() {
    _timerVentana = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosVentana > 0) {
        setState(() => _segundosVentana--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timerVentana?.cancel();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _accidenteActual =>
      _tiposAccidente.firstWhere((t) => t['id'] == _gravedadSeleccionada);

  List> get _colaboradoresFiltrados {
    final String catBuscada = _accidenteActual['categoriaColaborador'] as String;
    final filtrados = _colaboradoresAccidente.where((col) {
      final cats = col['categorias'] as List<String>;
      return cats.contains(catBuscada);
    }).toList();
    return filtrados.isNotEmpty ? filtrados : _colaboradoresAccidente;
  }

  void _enviarActualizacionGravedad() {
    final hora = _horaActual();
    final String obs = _descripcionCtrl.text.trim().isEmpty
        ? 'Sin observaciones adicionales'
        : _descripcionCtrl.text.trim();

    setState(() {
      _alertaActualizada = true;
      _bitacoraSimulacro.insert(0, {
        'hora': hora,
        'destinatario': 'Actualización a Socorro (123) y Contactos',
        'estado': 'SIMULADO OK',
        'detalle':
            'Clasificación: ${_accidenteActual['titulo']} • Prioridad: ${_accidenteActual['prioridad']} • Nota: "$obs"',
      });
    });

    _mostrarInspectorSimulacro(tituloPersonalizado: 'Simulacro: Actualización Enviada');
  }

  void _mostrarInspectorSimulacro({String tituloPersonalizado = 'Inspector de Modo Simulacro'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Color(0xFFC62828)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tituloPersonalizado,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade800),
                  ),
                  child: Text(
                    'SIMULACRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vehículo: $_tipoActivo ($_placaActiva) • Ubicación: $_ubicacionActiva',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const Divider(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: _bitacoraSimulacro.length,
                itemBuilder: (_, index) {
                  final item = _bitacoraSimulacro[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['destinatario'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item['estado']} • ${item['hora']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B6E4F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['detalle'] ?? '',
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CERRAR INSPECTOR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarPinCancelacion() async {
    final TextEditingController pinCtrl = TextEditingController();
    final bool? cancelado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFC62828)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Anular Simulacro de Accidente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu clave/PIN de seguridad para probar la cancelación por falsa alarma (ej. 1234):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Clave / PIN de acceso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('VOLVER'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinCtrl.text.trim() == _pinValido || pinCtrl.text.trim().length >= 4) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un PIN válido (mínimo 4 dígitos).'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: const Text('ANULAR ALERTA'),
          ),
        ],
      ),
    );

    if (cancelado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulacro cancelado: se notificó falsa alarma a contactos y entidades.'),
          backgroundColor: Color(0xFF0B6E4F),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _contactarColaborador(Map<String, dynamic> colaborador) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: Color(0xFFC62828)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                colaborador['nombre'] as String,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubicación GPS: $_ubicacionActiva'),
            const SizedBox(height: 4),
            Text('Vehículo: $_tipoActivo ($_placaActiva)'),
            Text('Novedad: ${_accidenteActual['titulo']}'),
            const Divider(height: 18),
            Text(
              'Contacto directo:\n${colaborador['telefono']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'S.O.S. Auto conecta directamente sin intermediar cobros ni comisiones.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7F0000)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color colorGravedad = _accidenteActual['color'] as Color;
    final List<String> recomendaciones = _accidenteActual['recomendaciones'] as List<String>;
    final String alertaLegal = _accidenteActual['alertaLegal'] as String;
    final String categoriaActiva = _accidenteActual['categoriaColaborador'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.emergency_share, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'SIMULACRO • Accidente',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _solicitarPinCancelacion,
            icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
            label: Text(
              _segundosVentana > 0 ? 'Anular (${_segundosVentana}s)' : 'Anular',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =========================================================
              // SECCIÓN 1: SIMULACRO DE ALERTA A CONTACTOS Y SOCORRO
              // =========================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science, size: 15, color: Colors.black87),
                          SizedBox(width: 5),
                          Text(
                            'MODO SIMULACRO • PRUEBA DE NOTIFICACIONES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.podcasts, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Text(
                          'ALERTA DE ACCIDENTE SIMULADA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simulación enviada a contactos de emergencia, organismos de socorro (123 / Tránsito) y conductores cercanos.\nVehículo: $_tipoActivo • $_placaActiva',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarInspectorSimulacro(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(
                        'VER QUÉ ENVIÓ LA APP (${_bitacoraSimulacro.length} EVENTOS)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 2: DESCRIBE LA GRAVEDAD DEL ACCIDENTE
              // =========================================================
              const Text(
                '1. Describe la gravedad del accidente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              ..._tiposAccidente.map((tipo) {
                final bool seleccionado = tipo['id'] == _gravedadSeleccionada;
                final Color itemColor = tipo['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _gravedadSeleccionada = tipo['id'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: seleccionado ? itemColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado ? itemColor : Colors.grey.shade300,
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tipo['icono'] as IconData,
                          size: 26,
                          color: seleccionado ? Colors.white : itemColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo['titulo'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: seleccionado ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                tipo['subtitulo'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: seleccionado ? Colors.white.withOpacity(0.9) : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: seleccionado ? Colors.white : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              TextField(
                controller: _descripcionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Detalles adicionales del accidente (ej. # de heridos, vía bloqueada...)',
                  prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFC62828)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _enviarActualizacionGravedad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alertaActualizada ? const Color(0xFF0B6E4F) : colorGravedad,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_alertaActualizada ? Icons.check_circle : Icons.send),
                label: Text(
                  _alertaActualizada
                      ? 'SIMULAR NUEVA ACTUALIZACIÓN A SOCORRO'
                      : 'SIMULAR ENVÍO DE REPORTE A SOCORRO Y CONTACTOS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 3: RECOMENDACIONES Y PRIMEROS AUXILIOS SEGÚN NOVEDAD
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorGravedad.withOpacity(0.5), width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: colorGravedad, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Recomendaciones y Primeros Auxilios (${_accidenteActual['titulo']})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorGravedad,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gavel, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alertaLegal,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4E342E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(recomendaciones.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: colorGravedad,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recomendaciones[i],
                                style: const TextStyle(fontSize: 13.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 4: DIRECTORIO DE COLABORADORES POR UBICACIÓN Y CATEGORÍA
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.store_mall_directory, color: Color(0xFFC62828), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '3. Directorio de Colaboradores',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ubicación: $_ubicacionActiva\nCategoría: $categoriaActiva',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF0B6E4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 18),
                    ..._colaboradoresFiltrados.map((col) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          col['nombre'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (col['verificado'] == true)
                                        const Icon(Icons.verified, size: 16, color: Color(0xFF0B6E4F)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${col['zona']} • A ${col['distancia']} (~${col['tiempo']})',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    col['telefono'] as String,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _contactarColaborador(col),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B6E4F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text(
                                'Llamar',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón Finalizar y Volver al Inicio
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212121),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'FINALIZAR SIMULACRO Y VOLVER AL INICIO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
