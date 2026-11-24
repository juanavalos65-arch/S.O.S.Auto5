import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_notifier_service.dart';
import '../services/banner_feed_service.dart';
import '../services/vehicle_session.dart';

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

class AlertDispatchLog {
  final String destino;
  final String detalle;
  final String hora;
  final IconData icono;
  final Color color;

  const AlertDispatchLog({
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

class _StolenCarScreenState extends State<StolenCarScreen>
    with SingleTickerProviderStateMixin {
  static const int _initialCountdown = 5;

  late final TabController _tabController;
  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdown;
  String _alertStatus = 'countdown';

  final List _dispatchLogs = [];
  final TextEditingController _observacionesController = TextEditingController();
  String _ultimaReferenciaReportada = 'Ubicación GPS en tiempo real';
  String? _stolenDocId;
  double? _lat;
  double? _lng;

  late final RegisteredVehicleSummary _vehicleData;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.vehicle != null) {
      _vehicleData = widget.vehicle!;
    } else if (VehicleSession.hasVehicle) {
      _vehicleData = RegisteredVehicleSummary(
        placa: VehicleSession.plate.toUpperCase(),
        tipo: VehicleSession.vehicleType,
        marca: VehicleSession.brand,
        modelo: VehicleSession.model,
        color: VehicleSession.color,
        ciudad:
            VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Sincelejo',
        pais: 'Colombia',
      );
    } else {
      _vehicleData = const RegisteredVehicleSummary(
        placa: 'SIN PLACA',
        tipo: 'Vehículo',
        marca: 'Registrado',
        modelo: 'S.O.S. Auto',
        color: 'No especificado',
        ciudad: 'Sincelejo',
        pais: 'Colombia',
      );
    }

    _obtenerGpsSilencioso();
    _startCountdown();
  }

  Future<void> _obtenerGpsSilencioso() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always ||
          p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _ultimaReferenciaReportada =
                'GPS ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _observacionesController.dispose();
    _tabController.dispose();
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
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _triggerStolenCarAlert();
      }
    });
  }

  Future<void> _cancelAlertWithoutPin() async {
    _countdownTimer?.cancel();
    HapticFeedback.lightImpact();

    if (_stolenDocId != null && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_stolenDocId)
            .update({
          'activa': false,
          'cerradaEn': FieldValue.serverTimestamp(),
        });
        await BannerFeedService.deactivateAlert('robo_$_stolenDocId');
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _alertStatus = 'cancelled');
    widget.onBannerAlertStateChanged?.call(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de robo desactivada inmediatamente (sin PIN).'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> _triggerStolenCarAlert() async {
    HapticFeedback.heavyImpact();
    final hora = _formattedNow();
    final detalleVehiculo =
        '${_vehicleData.marca} ${_vehicleData.modelo} • Color ${_vehicleData.color}';

    setState(() {
      _alertStatus = 'active';
      _dispatchLogs
        ..clear()
        ..addAll([
          AlertDispatchLog(
            destino: 'Banner Superior Comunitario y Nube',
            detalle:
                'Publicada alerta roja: $detalleVehiculo - Placa ${_vehicleData.placa}.',
            hora: hora,
            icono: Icons.campaign_rounded,
            color: Colors.deepOrange,
          ),
          const AlertDispatchLog(
            destino: 'Correo de Soporte (soporte.applay65@gmail.com)',
            detalle:
                'Reporte técnico enviado con placa, descripción y coordenadas GPS.',
            hora: 'Enviando',
            icono: Icons.mark_email_read_rounded,
            color: Colors.indigo,
          ),
          const AlertDispatchLog(
            destino: 'Autoridades / Línea 123',
            detalle:
                'Coordenadas GPS en vivo y ficha técnica del vehículo listas para reporte policial.',
            hora: 'En línea',
            icono: Icons.local_police_rounded,
            color: Colors.teal,
          ),
        ]);
    });

    widget.onBannerAlertStateChanged?.call(true);

    AdminNotifierService.notificarCorreo(
      modulo: 'Robo de Auto',
      titulo: 'Hurto de ${_vehicleData.tipo} (${_vehicleData.placa})',
      detalle: '$detalleVehiculo • Referencia: $_ultimaReferenciaReportada',
      placa: _vehicleData.placa,
      ciudad: _vehicleData.ciudad,
      mapsUrl: _mapsUrl,
    );

    if (Firebase.apps.isNotEmpty) {
      try {
        final docRef =
            FirebaseFirestore.instance.collection('vehiculos_robados').doc();
        _stolenDocId = docRef.id;

        await docRef.set({
          'placa': _vehicleData.placa,
          'tipoVehiculo': _vehicleData.tipo,
          'detalleVehiculo': detalleVehiculo,
          'ciudad': _vehicleData.ciudad,
          'modalidad': 'Hurto reportado en vivo',
          'detalleHuida': _ultimaReferenciaReportada,
          'latitud': _lat,
          'longitud': _lng,
          'mapsUrl': _mapsUrl,
          'activa': true,
          'creadaEn': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 8));

        await BannerFeedService.publishAlert(
          id: 'robo_${_stolenDocId ?? _vehicleData.placa}',
          category: 'stolen',
          tag: 'VEHÍCULO ROBADO — ${_vehicleData.ciudad}',
          title: '${_vehicleData.placa} • $detalleVehiculo',
          city: _vehicleData.ciudad,
          plate: _vehicleData.placa,
        );
      } catch (_) {}
    }
  }

  Future<void> _markVehicleAsRecovered() async {
    HapticFeedback.mediumImpact();
    final hora = _formattedNow();

    if (_stolenDocId != null && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_stolenDocId)
            .update({
          'activa': false,
          'recuperado': true,
          'cerradaEn': FieldValue.serverTimestamp(),
        });
        await BannerFeedService.deactivateAlert('robo_$_stolenDocId');
      } catch (_) {}
    }

    AdminNotifierService.notificarCorreo(
      modulo: 'Robo de Auto (RECUPERADO)',
      titulo: 'Vehículo recuperado (${_vehicleData.placa})',
      detalle: 'El usuario marcó el vehículo como recuperado y cerró la alerta.',
      placa: _vehicleData.placa,
      ciudad: _vehicleData.ciudad,
    );

    if (!mounted) return;
    setState(() {
      _alertStatus = 'recovered';
      _dispatchLogs.insert(
        0,
        AlertDispatchLog(
          destino: 'Cierre de Alerta - Auto Recuperado',
          detalle:
              'Aviso retirado del banner superior y cierre notificado a contactos y comunidad.',
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

  Future<void> _appendExtraDetailsToLog() async {
    final text = _observacionesController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _ultimaReferenciaReportada = text;
      _dispatchLogs.insert(
        0,
        AlertDispatchLog(
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

    if (_stolenDocId != null && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_stolenDocId)
            .update({'detalleHuida': text});
      } catch (_) {}
    }

    AdminNotifierService.notificarCorreo(
      modulo: 'Robo de Auto (Actualización)',
      titulo: 'Nueva pista placa ${_vehicleData.placa}',
      detalle: text,
      placa: _vehicleData.placa,
      ciudad: _vehicleData.ciudad,
      mapsUrl: _mapsUrl,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalle añadido a la alerta activa en la red.'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  Future<void> _callEmergency123() async {
    final uri = Uri(scheme: 'tel', path: '123');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareAlertWhatsApp({
    required String placa,
    required String vehiculo,
    required String ubicacion,
    bool esAvistamiento = false,
  }) async {
    final texto = esAvistamiento
        ? '🚨 AVISTAMIENTO S.O.S. AUTO 🚨\n'
            'Acabo de ver el vehículo reportado como robado:\n'
            '• Placa: $placa\n'
            '• Vehículo: $vehiculo\n'
            '• Zona reportada: $ubicacion\n'
            'Enviado desde la app S.O.S. Auto.'
        : '🚨 ALERTA DE ROBO DE VEHÍCULO — S.O.S. AUTO 🚨\n'
            '• Placa: $placa\n'
            '• Vehículo: $vehiculo\n'
            '• Última ubicación: $ubicacion\n'
            'Por favor difundir y avisar de inmediato a la Policía (123).';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign_rounded, size: 20),
              text: 'Reportar Robo',
            ),
            Tab(
              icon: Icon(Icons.directions_car_filled_rounded, size: 20),
              text: 'Vehículos Robados',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildReportTab(),
            _buildStolenVehiclesListTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusHeaderCard(),
        const SizedBox(height: 14),
        _buildAutoLoadedVehicleCard(),
        const SizedBox(height: 14),
        if (_alertStatus == 'active') ...[
          _buildQuickActionButtonsRow(),
          const SizedBox(height: 14),
          _buildQuickUpdateCard(),
          const SizedBox(height: 14),
          _buildRecoveredActionCard(),
          const SizedBox(height: 14),
        ],
        _buildSafetyRecommendationsCard(),
        const SizedBox(height: 14),
        if (_dispatchLogs.isNotEmpty) _buildDispatchHistoryCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStolenVehiclesListTab() {
    if (Firebase.apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Conectando con la red comunitaria...',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility_rounded,
                    color: Color(0xFFFBC02D), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RED COMUNITARIA DE BÚSQUEDA ACTIVA',
                        style: TextStyle(
                          color: Color(0xFFFBC02D),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Si ves alguno de estos vehículos en la vía, no intervengas: repórtalo de inmediato al 123 o comparte la ubicación.',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vehiculos_robados')
                .where('activa', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay vehículos reportados como robados en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 14.5),
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map;
                  final placa =
                      (d['placa'] ?? 'SIN PLACA').toString().toUpperCase();
                  final tipo = (d['tipoVehiculo'] ?? 'Vehículo').toString();
                  final detalle = (d['detalleVehiculo'] ?? '').toString();
                  final ciudad = (d['ciudad'] ?? 'Colombia').toString();
                  final huida = (d['detalleHuida'] ?? '').toString();
                  final esPropio = docs[index].id == _stolenDocId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: esPropio
                            ? Colors.red.shade600
                            : Colors.grey.shade300,
                        width: esPropio ? 1.8 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.amber.shade800, width: 1.5),
                                ),
                                child: Text(
                                  placa,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (esPropio)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TU REPORTE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$tipo • $detalle',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$ciudad${huida.isNotEmpty ? ' — $huida' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _callEmergency123,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                  ),
                                  icon: const Icon(Icons.local_police_rounded,
                                      size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Avisar 123'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _shareAlertWhatsApp(
                                    placa: placa,
                                    vehiculo: '$tipo $detalle',
                                    ubicacion: '$ciudad ($huida)',
                                    esAvistamiento: !esPropio,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                  ),
                                  icon:
                                      const Icon(Icons.share_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Reportar / Difundir'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callEmergency123,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.local_police_rounded, size: 20),
            label: const Text(
              'Llamar Policía 123',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareAlertWhatsApp(
              placa: _vehicleData.placa,
              vehiculo:
                  '${_vehicleData.tipo} ${_vehicleData.marca} ${_vehicleData.modelo} (${_vehicleData.color})',
              ubicacion: '${_vehicleData.ciudad} — $_ultimaReferenciaReportada',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: const Text(
              'Enviar WhatsApp',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ],
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
              'Tienes 5 segundos para cancelar antes de publicar la placa en el banner y en la red.',
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
                  'DESACTIVAR ALERTA AHORA',
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
            Icon(Icons.shield_outlined,
                size: 42, color: Colors.blueGrey.shade700),
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
            Icon(Icons.check_circle_rounded,
                size: 46, color: Colors.green.shade700),
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
                      'ALERTA DE ROBO ACTIVA EN RED',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const Text(
                      'Publicada en banner superior y enviada a soporte.applay65@gmail.com.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelAlertWithoutPin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Desactivar Alerta'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Ver en Lista'),
                  ),
                ),
              ),
            ],
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
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
                _vehicleChip('Vehículo',
                    '${_vehicleData.marca} ${_vehicleData.modelo}'),
                _vehicleChip('Color', _vehicleData.color),
                _vehicleChip('Ubicación',
                    '${_vehicleData.ciudad}, ${_vehicleData.pais}'),
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

  Widget _buildDispatchHistoryCard() {
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
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.deepOrange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Estado de Difusión de la Alerta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${_dispatchLogs.length} acciones',
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
