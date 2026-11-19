import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modelo ligero del vehículo registrado para auto-cargar sin pedir datos.
class RegisteredVehicleSummary {
  final String placa;
  final String tipo;
  final String marca;
  final String modelo;
  final String color;
  final String ciudad;
  final String pais;

  const RegisteredVehicleSummary({
    required this.placa,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.ciudad,
    required this.pais,
  });
}

/// Evento registrado en la bitácora de simulacro.
class SimulacroDispatchLog {
  final String destino;
  final String detalle;
  final String hora;
  final IconData icono;
  final Color color;

  const SimulacroDispatchLog({
    required this.destino,
    required this.detalle,
    required this.hora,
    required this.icono,
    required this.color,
  });
}

class StolenCarScreen extends StatefulWidget {
  final RegisteredVehicleSummary? vehicle;
  final ValueChanged<bool>? onBannerAlertStateChanged;

  const StolenCarScreen({
    super.key,
    this.vehicle,
    this.onBannerAlertStateChanged,
  });

  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  static const int _initialCountdown = 5;

  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdown;

  /// Estados posibles:
  /// - 'countdown': cuenta regresiva de 5 segundos (cancelable sin PIN)
  /// - 'active': alerta de robo publicada en simulacro
  /// - 'cancelled': cancelada antes de enviarse
  /// - 'recovered': vehículo marcado como recuperado y retiro del banner
  String _alertStatus = 'countdown';

  final List<SimulacroDispatchLog> _dispatchLogs = [];
  final TextEditingController _observacionesController = TextEditingController();

  late final RegisteredVehicleSummary _vehicleData;

  @override
  void initState() {
    super.initState();
    _vehicleData = widget.vehicle ??
        const RegisteredVehicleSummary(
          placa: 'KLM-482',
          tipo: 'Automóvil',
          marca: 'Chevrolet',
          modelo: 'Onix Turbo 2023',
          color: 'Gris Plata',
          ciudad: 'Sincelejo',
          pais: 'Colombia',
        );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _observacionesController.dispose();
    super.dispose();
  }

  String _formattedNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = _initialCountdown;
      _alertStatus = 'countdown';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      HapticFeedback.mediumImpact();
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _triggerStolenCarAlert();
      }
    });
  }

  /// Desactivación directa SIN PIN (Regla técnica #1).
  void _cancelAlertWithoutPin() {
    _countdownTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _alertStatus = 'cancelled';
    });
    widget.onBannerAlertStateChanged?.call(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de robo desactivada inmediatamente (sin PIN).'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _triggerStolenCarAlert() {
    HapticFeedback.heavyImpact();
    final hora = _formattedNow();

    setState(() {
      _alertStatus = 'active';
      _dispatchLogs
        ..clear()
        ..addAll([
          SimulacroDispatchLog(
            destino: 'Banner Superior Comunitario (Simulacro)',
            detalle:
                'Publicada alerta roja: ${_vehicleData.marca} ${_vehicleData.modelo} (${_vehicleData.color}) - Placa ${_vehicleData.placa}.',
            hora: hora,
            icono: Icons.campaign_rounded,
            color: Colors.deepOrange,
          ),
          SimulacroDispatchLog(
            destino: 'Autoridades / Línea 123 (Simulacro)',
            detalle:
                'Coordenadas GPS en vivo y ficha técnica del vehículo enviadas a central.',
            hora: hora,
            icono: Icons.local_police_rounded,
            color: Colors.indigo,
          ),
          SimulacroDispatchLog(
            destino: 'Contactos de Emergencia (Simulacro)',
            detalle:
                'Notificación SMS/WhatsApp con ubicación del incidente y estado del conductor.',
            hora: hora,
            icono: Icons.contacts_rounded,
            color: Colors.teal,
          ),
          SimulacroDispatchLog(
            destino: 'Red de Conductores Cercanos (Simulacro)',
            detalle:
                'Aviso enviado a usuarios S.O.S. Auto en un radio de 10 km en ${_vehicleData.ciudad}.',
            hora: hora,
            icono: Icons.radar_rounded,
            color: Colors.redAccent,
          ),
        ]);
    });

    widget.onBannerAlertStateChanged?.call(true);
  }

  void _markVehicleAsRecovered() {
    HapticFeedback.mediumImpact();
    final hora = _formattedNow();

    setState(() {
      _alertStatus = 'recovered';
      _dispatchLogs.insert(
        0,
        SimulacroDispatchLog(
          destino: 'Cierre de Alerta - Auto Recuperado',
          detalle:
              'Aviso retirado del banner superior y notificación de cierre enviada a contactos y comunidad.',
          hora: hora,
          icono: Icons.verified_rounded,
          color: Colors.green,
        ),
      );
    });

    widget.onBannerAlertStateChanged?.call(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Vehículo marcado como recuperado! El aviso fue retirado del banner.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _appendExtraDetailsToLog() {
    final text = _observacionesController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _dispatchLogs.insert(
        0,
        SimulacroDispatchLog(
          destino: 'Actualización de última dirección vista',
          detalle: text,
          hora: _formattedNow(),
          icono: Icons.edit_location_alt_rounded,
          color: Colors.orange.shade800,
        ),
      );
      _observacionesController.clear();
    });

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalle añadido a la alerta activa en simulacro.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Robo de Auto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_rounded, size: 15, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  'SIMULACRO',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusHeaderCard(),
            const SizedBox(height: 14),
            _buildAutoLoadedVehicleCard(),
            const SizedBox(height: 14),
            if (_alertStatus == 'active') ...[
              _buildQuickUpdateCard(),
              const SizedBox(height: 14),
              _buildRecoveredActionCard(),
              const SizedBox(height: 14),
            ],
            _buildSafetyRecommendationsCard(),
            const SizedBox(height: 14),
            if (_dispatchLogs.isNotEmpty) _buildSimulacroInspectorCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard() {
    if (_alertStatus == 'countdown') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade800, Colors.red.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'ACTIVANDO ALERTA DE ROBO EN...',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Text(
                '$_secondsRemaining',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Se publicará la placa en el banner superior y se alertará a autoridades y contactos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cancelAlertWithoutPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel_rounded),
                label: const Text(
                  'DESACTIVAR ALERTA AHORA (SIN PIN)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_alertStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 42, color: Colors.blueGrey.shade700),
            const SizedBox(height: 8),
            const Text(
              'Alerta Cancelada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'No se envió ningún reporte ni se publicó aviso en el banner.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startCountdown,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Volver a iniciar alerta'),
            ),
          ],
        ),
      );
    }

    if (_alertStatus == 'recovered') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 46, color: Colors.green.shade700),
            const SizedBox(height: 8),
            Text(
              'Vehículo Recuperado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'La alerta de robo ha sido cerrada y retirada del banner comunitario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
      );
    }

    // Estado 'active'
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALERTA DE ROBO ACTIVA',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Visible en banner superior y enviada a red de apoyo.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelAlertWithoutPin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade800,
                side: BorderSide(color: Colors.red.shade400),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Desactivar por error (Sin PIN)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLoadedVehicleCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car_filled_rounded,
                    color: Colors.deepOrange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Datos del Vehículo (Cargados Automáticamente)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _vehicleChip('Placa', _vehicleData.placa, highlight: true),
                _vehicleChip('Tipo', _vehicleData.tipo),
                _vehicleChip(
                    'Vehículo', '${_vehicleData.marca} ${_vehicleData.modelo}'),
                _vehicleChip('Color', _vehicleData.color),
                _vehicleChip(
                    'Ubicación', '${_vehicleData.ciudad}, ${_vehicleData.pais}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleChip(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.amber.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? Colors.amber.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuickUpdateCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Añadir dirección o referencia (Opcional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _observacionesController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Tomó vía hacia el norte, 2 sujetos...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _appendExtraDetailsToLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveredActionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '¿Ya apareció o recuperaste tu vehículo?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Al confirmar, se retirará inmediatamente la alerta del banner comunitario y se notificará el cierre.',
            style: TextStyle(fontSize: 12.5, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markVehicleAsRecovered,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'AUTO RECUPERADO - CERRAR ALERTA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRecommendationsCard() {
    final recommendations = [
      'No persigas ni enfrentes a los delincuentes; tu vida es la prioridad.',
      'Resguárdate en un lugar público, iluminado o estación de policía cercana.',
      'Si tu celular fue robado junto al auto, bloquea tu línea SIM y apps bancarias de inmediato.',
      'Comunícate con la línea de emergencias (123) y radica la denuncia formal para asegurar el reporte.',
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_rounded,
                    color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Text(
                  'Recomendaciones de Seguridad',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulacroInspectorCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal_rounded, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bitácora de Envíos (Modo Simulacro)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${_dispatchLogs.length} eventos',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 18),
            ..._dispatchLogs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(log.icono, color: log.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.destino,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                log.hora,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.detalle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
