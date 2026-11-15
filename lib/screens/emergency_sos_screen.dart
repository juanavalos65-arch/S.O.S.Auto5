import 'dart:async';
import 'package:flutter/material.dart';

class EstoyEnPeligroScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? tipoVehiculoRegistrado;
  final String? ciudadActual;

  const EstoyEnPeligroScreen({
    super.key,
    this.placaRegistrada,
    this.tipoVehiculoRegistrado,
    this.ciudadActual,
  });

  @override
  State<EstoyEnPeligroScreen> createState() => _EstoyEnPeligroScreenState();
}

class _EstoyEnPeligroScreenState extends State<EstoyEnPeligroScreen> {
  final TextEditingController _motivoDescripcionCtrl = TextEditingController();

  // Motivos: 'agresion', 'amenaza', 'seguimiento', 'zona_insegura', 'otro'
  String _motivoSeleccionadoId = 'agresion';
  bool _alertaActualizada = false;

  // Cuenta regresiva visual de 5 segundos al activar
  int _segundosVentana = 5;
  Timer? _timerVentana;

  // Bitácora de eventos en Modo Simulacro
  final List _bitacoraSimulacro = [];

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
          : 'GPS Simulado en Vivo (6.2442° N, 75.5812° W)';

  final List> _motivosPeligro = [
    {
      'id': 'agresion',
      'titulo': 'Me están agrediendo',
      'subtitulo': 'Ataque físico, intento de abrir el vehículo o golpear vidrios',
      'icono': Icons.personal_injury,
      'color': const Color(0xFFB71C1C),
      'prioridad': 'MÁXIMA CRÍTICA (Policía 123 / Contactos / Usuarios Cercanos)',
      'reglaOro':
          'NO bajes los vidrios ni abras las puertas por ningún motivo. Mantén el vehículo encendido y en cambio para maniobrar si es necesario.',
      'instrucciones': [
        'Verifica de inmediato que los seguros eléctricos de todas las puertas estén cerrados y los vidrios completamente arriba.',
        'Mantén el pie listo en el acelerador y observa salidas libres hacia adelante o en reversa sin poner en riesgo tu vida.',
        'Acciona el pito (claxon) de forma intermitente y enciende luces altas/estacionarias para llamar la atención de transeúntes y cámaras.',
        'Conduce de inmediato hacia el CAI de Policía, estación de servicio 24h o centro comercial con vigilancia más cercano.',
        'No confrontes verbal ni físicamente al agresor; deja que el audio y GPS de S.O.S. Auto registren la evidencia.',
      ],
    },
    {
      'id': 'amenaza',
      'titulo': 'Me están amenazando',
      'subtitulo': 'Intimidación verbal, cierre de vía o exhibición de armas',
      'icono': Icons.gpp_bad,
      'color': const Color(0xFFC62828),
      'prioridad': 'CRÍTICA ALTA (Policía 123 / Contactos de Emergencia)',
      'reglaOro':
          'Si exhiben un arma y exigen el vehículo, prioriza tu vida: no te resistas, entrega las llaves y aléjate hacia un lugar público iluminado.',
      'instrucciones': [
        'Evita el contacto visual directo y no respondas a provocaciones ni insultos desde el interior del vehículo.',
        'Si estás en movimiento y tienes vía libre, cambia de carril con calma y dirígete a una avenida principal con presencia policial.',
        'Si te bloquean el paso y estás en riesgo inminente, mantén las manos visibles sobre el volante y conserva la calma.',
        'Memoriza rasgos clave sin mirar fijamente (placa, color y modelo del otro vehículo, dirección de huida) para reportarlos.',
        'Una vez a salvo, activa también el botón "Robo de auto" si te despojaron del vehículo.',
      ],
    },
    {
      'id': 'seguimiento',
      'titulo': 'Me están siguiendo',
      'subtitulo': 'Vehículo o motocicleta sospechosa persiguiendo tu ruta',
      'icono': Icons.visibility,
      'color': const Color(0xFFD84315),
      'prioridad': 'ALTA (Rastreo GPS Continuo / CAI Cercano)',
      'reglaOro':
          'NUNCA te dirijas a tu casa, oficina ni a calles solitarias mientras sospeches que te siguen.',
      'instrucciones': [
        'Realiza una prueba de confirmación: haz 3 giros consecutivos hacia la derecha (dar la vuelta a la manzana) o cambia de carril en una glorieta.',
        'Si el vehículo sospechoso repite tus giros, dirígete directamente a la estación de Policía o CAI más próximo.',
        'Conduce por vías principales, bien iluminadas y con alto flujo vehicular o cámaras de seguridad.',
        'Mantén el teléfono en soporte o altavoz con la línea 123 lista sin soltar el volante.',
        'Estaciónate frente a la entrada de un lugar con guardia de seguridad armada (banco, clínica, supermercado) sin apagar el motor hasta confirmar ayuda.',
      ],
    },
    {
      'id': 'zona_insegura',
      'titulo': 'Zona no segura o desconocida',
      'subtitulo': 'Desvío solitario, vía sin iluminación o sector de alto riesgo',
      'icono': Icons.wrong_location,
      'color': const Color(0xFFE65100),
      'prioridad': 'PREVENTIVA ACTIVA (Monitoreo GPS Contactos)',
      'reglaOro':
          'No te detengas a revisar el celular ni pidas indicaciones a desconocidos en la calle en sectores aislados.',
      'instrucciones': [
        'Mantén una velocidad constante y prudente, dejando suficiente distancia con el carro de adelante para poder esquivar si frena de golpe.',
        'Sube todos los vidrios, activa el bloqueo central de puertas y guarda objetos de valor fuera de la vista.',
        'Retoma de inmediato una vía arterial principal utilizando el mapa de S.O.S. Auto sin detener la marcha.',
        'Mantén compartida tu ubicación en tiempo real con tus contactos hasta salir completamente del sector.',
        'Si necesitas detenerte por fuerza mayor, hazlo únicamente dentro de una estación de gasolina iluminada y con personal.',
      ],
    },
    {
      'id': 'otro',
      'titulo': 'Otro motivo de peligro',
      'subtitulo': 'Emergencia personal, acoso o situación sospechosa',
      'icono': Icons.warning_amber_rounded,
      'color': const Color(0xFF4E342E),
      'prioridad': 'ALTA (Contactos de Emergencia / Red S.O.S.)',
      'reglaOro':
          'Describe brevemente lo que sucede abajo para que tus contactos y usuarios cercanos sepan exactamente cómo auxiliarte.',
      'instrucciones': [
        'Escribe en el cuadro inferior qué está ocurriendo (ej. vehículo sospechoso bloqueando salida, emergencia médica a bordo, etc.).',
        'Permanece dentro del vehículo con seguros puestos mientras llegan tus contactos o las autoridades.',
        'Mantén el micrófono despejado para que la grabación ambiental de emergencia capture lo que ocurre.',
        'Si ves usuarios de S.O.S. Auto cerca en el mapa, haz señales con las luces estacionarias para facilitar tu ubicación.',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarVentanaAnulacion();
    _registrarAlertaInicialSimulacro();
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _registrarAlertaInicialSimulacro() {
    final hora = _horaActual();
    _bitacoraSimulacro.addAll([
      {
        'hora': hora,
        'destinatario': 'Contactos de Emergencia (WhatsApp / SMS Prioritario)',
        'estado': 'SIMULADO OK',
        'detalle':
            'Alerta silenciosa "ESTOY EN PELIGRO" enviada con GPS en tiempo real ($_ubicacionActiva) y placa $_placaActiva.',
      },
      {
        'hora': hora,
        'destinatario': 'Usuarios Cercanos S.O.S. Auto (Radio 2 km)',
        'estado': 'SIMULADO OK',
        'detalle':
            'Aviso comunitario de auxilio preventivo despachado a conductores activos en el sector.',
      },
      {
        'hora': hora,
        'destinatario': 'Central de Emergencias / Policía (123)',
        'estado': 'SIMULADO OK',
        'detalle':
            'Coordenadas en vivo y grabación ambiental de respaldo iniciadas en modo simulacro.',
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
    _motivoDescripcionCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _motivoActual =>
      _motivosPeligro.firstWhere((m) => m['id'] == _motivoSeleccionadoId);

  void _seleccionarMotivo(String id) {
    setState(() {
      _motivoSeleccionadoId = id;
    });
  }

  void _enviarActualizacionMotivo() {
    final hora = _horaActual();
    final String desc = _motivoDescripcionCtrl.text.trim().isEmpty
        ? 'Sin descripción adicional'
        : _motivoDescripcionCtrl.text.trim();

    setState(() {
      _alertaActualizada = true;
      _bitacoraSimulacro.insert(0, {
        'hora': hora,
        'destinatario': 'Actualización a Contactos y Usuarios Cercanos',
        'estado': 'SIMULADO OK',
        'detalle':
            'Motivo reportado: "${_motivoActual['titulo']}" • Prioridad: ${_motivoActual['prioridad']} • Detalle: "$desc"',
      });
    });

    _mostrarInspectorSimulacro(tituloPersonalizado: 'Simulacro: Motivo Notificado');
  }

  void _mostrarInspectorSimulacro({String tituloPersonalizado = 'Inspector de Simulacro • Peligro'}) {
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
                const Icon(Icons.science, color: Color(0xFFB71C1C)),
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
              'Vehículo: $_tipoActivo ($_placaActiva) • GPS: $_ubicacionActiva',
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
                backgroundColor: const Color(0xFFB71C1C),
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

  /// Desactivación directa de la alerta SIN pedir PIN
  void _desactivarAlertaDirecto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta desactivada: se notificó a tus contactos y cercanos.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color colorMotivo = _motivoActual['color'] as Color;
    final List<String> instrucciones = _motivoActual['instrucciones'] as List<String>;
    final String reglaOro = _motivoActual['reglaOro'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'SIMULACRO • Estoy en peligro',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =========================================================
              // SECCIÓN 1: ALERTA EN MODO SIMULACRO + BOTÓN DESACTIVAR DIRECTO
              // =========================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC62828), Color(0xFF8E0000)],
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
                            'MODO SIMULACRO • NOTIFICACIONES DE PRUEBA',
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
                        Icon(Icons.notifications_active, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ALERTA DE PELIGRO ACTIVADA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simulación enviada a tus contactos de emergencia y usuarios cercanos de S.O.S. Auto con tu ubicación GPS en tiempo real.\nVehículo: $_tipoActivo • $_placaActiva',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarInspectorSimulacro(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8E0000),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(
                        'VER NOTIFICACIONES ENVIADAS (${_bitacoraSimulacro.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón directo de desactivación sin PIN
                    OutlinedButton.icon(
                      onPressed: _desactivarAlertaDirecto,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        _segundosVentana > 0
                            ? 'DESACTIVAR ALERTA (${_segundosVentana}s)'
                            : 'DESACTIVAR ALERTA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 2: BOTONES DE SITUACIÓN DE PELIGRO Y DESCRIPCIÓN
              // =========================================================
              const Text(
                '1. Selecciona qué está sucediendo:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              ..._motivosPeligro.map((motivo) {
                final bool seleccionado = motivo['id'] == _motivoSeleccionadoId;
                final Color itemColor = motivo['color'] as Color;
                return GestureDetector(
                  onTap: () => _seleccionarMotivo(motivo['id'] as String),
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
                          motivo['icono'] as IconData,
                          size: 26,
                          color: seleccionado ? Colors.white : itemColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                motivo['titulo'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: seleccionado ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                motivo['subtitulo'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: seleccionado
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black54,
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
              const SizedBox(height: 8),

              // Campo para describir el motivo
              TextField(
                controller: _motivoDescripcionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Describe el motivo o detalles clave (opcional)',
                  hintText: 'Ej. Moto negra sin placa me sigue hace 3 cuadras, voy rumbo al CAI...',
                  prefixIcon: Icon(Icons.edit_note, color: colorMotivo),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _enviarActualizacionMotivo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alertaActualizada ? const Color(0xFF0B6E4F) : colorMotivo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_alertaActualizada ? Icons.check_circle : Icons.send),
                label: Text(
                  _alertaActualizada
                      ? 'SIMULAR NUEVA ACTUALIZACIÓN DE MOTIVO'
                      : 'NOTIFICAR MOTIVO A CONTACTOS Y CERCANOS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 3: INSTRUCCIONES DE QUÉ HACER SEGÚN EL MOTIVO
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorMotivo.withOpacity(0.55), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: colorMotivo, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Qué hacer: ${_motivoActual['titulo']}',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: colorMotivo,
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
                          const Icon(Icons.priority_high, color: Colors.amber, size: 22),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reglaOro,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4E342E),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(instrucciones.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: colorMotivo,
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
                                instrucciones[i],
                                style: const TextStyle(fontSize: 13.5, height: 1.32),
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

              // Botón Finalizar Simulacro
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _desactivarAlertaDirecto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212121),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'DESACTIVAR ALERTA Y VOLVER AL INICIO',
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
