import 'dart:async';
import 'package:flutter/material.dart';

class StolenCarScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? tipoVehiculoRegistrado;
  final String? marcaModeloColorRegistrado;
  final String? ciudadActual;

  const StolenCarScreen({
    super.key,
    this.placaRegistrada,
    this.tipoVehiculoRegistrado,
    this.marcaModeloColorRegistrado,
    this.ciudadActual,
  });

  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  final TextEditingController _detalleHuidaCtrl = TextEditingController();
  final TextEditingController _detalleRecuperacionCtrl = TextEditingController();

  // Fases: 'cuenta_regresiva', 'alerta_activa', 'recuperado'
  String _estadoAlerta = 'cuenta_regresiva';
  int _segundosRestantes = 5;
  Timer? _timerCuentaRegresiva;

  // Modalidad del hurto: 'atraco', 'halado', 'engano'
  String _modalidadHurto = 'atraco';
  String _recuperadoPor = 'Policía Nacional / Plan Candado';

  // Bitácora en Modo Simulacro
  final List> _bitacoraSimulacro = [];

  String get _placaActiva =>
      (widget.placaRegistrada != null && widget.placaRegistrada!.trim().isNotEmpty)
          ? widget.placaRegistrada!.trim().toUpperCase()
          : 'VEHÍCULO REGISTRADO';

  String get _tipoActivo =>
      (widget.tipoVehiculoRegistrado != null && widget.tipoVehiculoRegistrado!.trim().isNotEmpty)
          ? widget.tipoVehiculoRegistrado!.trim()
          : 'Automóvil';

  String get _detalleVehiculoActivo =>
      (widget.marcaModeloColorRegistrado != null &&
              widget.marcaModeloColorRegistrado!.trim().isNotEmpty)
          ? widget.marcaModeloColorRegistrado!.trim()
          : 'Ficha y foto tomadas del registro S.O.S. Auto';

  String get _ubicacionActiva =>
      (widget.ciudadActual != null && widget.ciudadActual!.trim().isNotEmpty)
          ? widget.ciudadActual!.trim()
          : 'GPS Simulado en Vivo (6.2442° N, 75.5812° W)';

  @override
  void initState() {
    super.initState();
    _iniciarCuentaRegresiva();
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _iniciarCuentaRegresiva() {
    _timerCuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes > 1) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
        _activarAlertaRoboSimulacro();
      }
    });
  }

  void _activarAlertaRoboSimulacro() {
    final hora = _horaActual();
    setState(() {
      _segundosRestantes = 0;
      _estadoAlerta = 'alerta_activa';
      _bitacoraSimulacro.addAll([
        {
          'hora': hora,
          'destinatario': 'Banner Público S.O.S. Auto (Comunidad Vial)',
          'estado': 'PUBLICADO (SIMULACRO)',
          'detalle':
              'Alerta de búsqueda activa en banner superior: $_tipoActivo • Placa $_placaActiva ($_detalleVehiculoActivo).',
        },
        {
          'hora': hora,
          'destinatario': 'Policía Nacional / Plan Candado (Línea 123)',
          'estado': 'DESPACHADO (SIMULACRO)',
          'detalle':
              'Reporte de hurto con coordenadas del incidente ($_ubicacionActiva) y ficha registral del vehículo.',
        },
        {
          'hora': hora,
          'destinatario': 'Contactos de Emergencia & Conductores Cercanos',
          'estado': 'NOTIFICADO (SIMULACRO)',
          'detalle':
              'Aviso inmediato a contactos de confianza (para que te recojan en punto seguro) y usuarios en radio de 5 km.',
        },
      ]);
    });
  }

  void _cancelarDuranteCuentaRegresiva() {
    _timerCuentaRegresiva?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de robo desactivada antes de enviarse.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
    Navigator.of(context).pop();
  }

  void _actualizarDatosHuida() {
    final hora = _horaActual();
    final String desc = _detalleHuidaCtrl.text.trim().isEmpty
        ? 'Sin datos adicionales de ruta'
        : _detalleHuidaCtrl.text.trim();

    String nombreModalidad = 'Atraco / Intimidación';
    if (_modalidadHurto == 'halado') nombreModalidad = 'Halado / Estacionado';
    if (_modalidadHurto == 'engano') nombreModalidad = 'Falsa autoridad / Engaño';

    setState(() {
      _bitacoraSimulacro.insert(0, {
        'hora': hora,
        'destinatario': 'Actualización de Búsqueda (123 + Banner Comunidad)',
        'estado': 'ACTUALIZADO (SIMULACRO)',
        'detalle': 'Modalidad: $nombreModalidad • Ruta / Rasgos: "$desc"',
      });
    });

    _mostrarInspectorSimulacro(titulo: 'Simulacro: Datos de Búsqueda Actualizados');
  }

  void _marcarAutoRecuperado() {
    final hora = _horaActual();
    final String notaRec = _detalleRecuperacionCtrl.text.trim().isEmpty
        ? 'Vehículo ubicado y verificado por el propietario'
        : _detalleRecuperacionCtrl.text.trim();

    setState(() {
      _estadoAlerta = 'recuperado';
      _bitacoraSimulacro.insert(0, {
        'hora': hora,
        'destinatario': 'CIERRE DE ALERTA • AUTO RECUPERADO ($_placaActiva)',
        'estado': 'CERRADO OK',
        'detalle':
            'Retirado del banner público de robo. Recuperado mediante: $_recuperadoPor. Nota: "$notaRec". Contactos notificados.',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Excelente noticia! Alerta cerrada y $_placaActiva marcado como RECUPERADO.'),
        backgroundColor: const Color(0xFF0B6E4F),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarInspectorSimulacro({String titulo = 'Inspector Simulacro • Robo de Auto'}) {
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
                    titulo,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
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
              'Vehículo: $_tipoActivo ($_placaActiva) • $_ubicacionActiva',
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
                                  fontSize: 10.5,
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

  @override
  void dispose() {
    _timerCuentaRegresiva?.cancel();
    _detalleHuidaCtrl.dispose();
    _detalleRecuperacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esRecuperado = _estadoAlerta == 'recuperado';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: esRecuperado ? const Color(0xFF0B6E4F) : const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(esRecuperado ? Icons.verified : Icons.directions_car_filled, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                esRecuperado ? 'SIMULACRO • Auto Recuperado' : 'SIMULACRO • Robo de Auto',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _estadoAlerta == 'cuenta_regresiva'
            ? _buildPantallaCuentaRegresiva()
            : _estadoAlerta == 'alerta_activa'
                ? _buildPantallaAlertaActiva()
                : _buildPantallaAutoRecuperado(),
      ),
    );
  }

  /// FASE 1: Cuenta regresiva de 5 segundos para desactivar sin PIN
  Widget _buildPantallaCuentaRegresiva() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'MODO SIMULACRO • ROBO DE AUTO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ACTIVANDO ALERTA DE ROBO EN:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 64,
            backgroundColor: Colors.white,
            child: Text(
              '$_segundosRestantes',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vehículo registrado: $_tipoActivo • $_placaActiva\nSe enviará alerta automática a Policía (123), contactos y banner comunitario.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _cancelarDuranteCuentaRegresiva,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.cancel, size: 24),
              label: const Text(
                'DESACTIVAR ALERTA AHORA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FASE 2: Alerta activa + datos del vehículo + recomendaciones + sección Auto Recuperado
  Widget _buildPantallaAlertaActiva() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                        'MODO SIMULACRO • ALERTA PUBLICADA',
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
                const Text(
                  '¡ALERTA DE ROBO ACTIVA!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Se envió la ficha de tu vehículo a autoridades (123), contactos de emergencia y al banner superior de S.O.S. Auto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.amberAccent, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_tipoActivo • PLACA: $_placaActiva',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              _detalleVehiculoActivo,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'Punto del reporte: $_ubicacionActiva',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _mostrarInspectorSimulacro(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8E0000),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: Text(
                    'VER NOTIFICACIONES Y BANNER (${_bitacoraSimulacro.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SECCIÓN 1: RECOMENDACIONES DE SEGURIDAD PERSONAL
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade700, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Color(0xFFB71C1C), size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '1. Recomendaciones Inmediatas para tu Vida',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _itemRecomendacion(
                    'NO persigas al delincuente:', 'Tu vida vale más que cualquier vehículo; nunca intentes seguirlos en otro carro o moto.'),
                _itemRecomendacion(
                    'Busca un sitio seguro e iluminado:', 'Entra de inmediato a un local comercial con vigilancia, estación de servicio o CAI cercano.'),
                _itemRecomendacion(
                    'Espera la ayuda que viene en camino:', 'Tus contactos de emergencia y la Policía ya recibieron tu ubicación exacta.'),
                _itemRecomendacion(
                    'Bloqueo rápido (Primeros 15 min):', 'Si tu celular o tarjetas quedaron en el auto, bloquea cuentas bancarias y línea SIM de inmediato.'),
                _itemRecomendacion(
                    'Denuncia formal (Plan Candado 123):', 'Radica el denuncio penal ante la Policía/Fiscalía para activar búsqueda oficial y póliza.'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SECCIÓN 2: DATOS DE HUIDA Y MODALIDAD
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
                const Text(
                  '2. Ampliar datos para la Policía y Comunidad',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Atraco'),
                      selected: _modalidadHurto == 'atraco',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                        color: _modalidadHurto == 'atraco' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _modalidadHurto = 'atraco'),
                    ),
                    ChoiceChip(
                      label: const Text('Halado / Estacionado'),
                      selected: _modalidadHurto == 'halado',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                        color: _modalidadHurto == 'halado' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _modalidadHurto = 'halado'),
                    ),
                    ChoiceChip(
                      label: const Text('Engaño / Retén falso'),
                      selected: _modalidadHurto == 'engano',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                        color: _modalidadHurto == 'engano' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _modalidadHurto = 'engano'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _detalleHuidaCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Dirección de huida o rasgos (ej. tomaron vía al norte, 2 sujetos...)',
                    prefixIcon: const Icon(Icons.explore, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _actualizarDatosHuida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text(
                    'ACTUALIZAR DATOS DE BÚSQUEDA (SIMULACRO)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SECCIÓN 3: ESPACIO DE AUTO RECUPERADO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0B6E4F), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF0B6E4F), size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '3. ¿Ya apareció tu vehículo? • Auto Recuperado',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B6E4F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Al confirmar la recuperación, se retira inmediatamente la alerta del banner público y se avisa a tus contactos.',
                  style: TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _recuperadoPor,
                  decoration: InputDecoration(
                    labelText: '¿Cómo se logró la recuperación?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Policía Nacional / Plan Candado',
                      child: Text('Policía Nacional / Plan Candado'),
                    ),
                    DropdownMenuItem(
                      value: 'Comunidad S.O.S. Auto (Avistamiento)',
                      child: Text('Comunidad S.O.S. Auto (Avistamiento)'),
                    ),
                    DropdownMenuItem(
                      value: 'Rastreo Satelital GPS',
                      child: Text('Rastreo Satelital GPS'),
                    ),
                    DropdownMenuItem(
                      value: 'Ubicación directa del propietario',
                      child: Text('Ubicación directa del propietario'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _recuperadoPor = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detalleRecuperacionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Lugar o estado en que se encontró (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _marcarAutoRecuperado,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6E4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_user),
                    label: const Text(
                      'MARCAR AUTO COMO RECUPERADO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              'VOLVER AL MAPA (MANTENER ALERTA EN SIMULACRO)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// FASE 3: Confirmación visual de Auto Recuperado
  Widget _buildPantallaAutoRecuperado() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF0B6E4F), width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, color: Color(0xFF0B6E4F), size: 64),
                const SizedBox(height: 12),
                const Text(
                  '¡VEHÍCULO RECUPERADO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B6E4F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_tipoActivo • Placa: $_placaActiva\n'
                  'Recuperado por: $_recuperadoPor\n\n'
                  'La alerta de robo fue retirada del banner público y se notificó el cierre exitoso a tus contactos y usuarios cercanos.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E4F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.home),
            label: const Text(
              'FINALIZAR Y VOLVER AL INICIO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRecomendacion(String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFFB71C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(text: '$titulo ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: detalle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
