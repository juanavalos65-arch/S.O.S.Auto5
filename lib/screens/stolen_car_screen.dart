import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_alert_service.dart';
import '../services/banner_feed_service.dart';
import '../services/vehicle_session.dart';

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
  State createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State {
  final TextEditingController _detalleHuidaCtrl = TextEditingController();
  final TextEditingController _detalleRecuperacionCtrl = TextEditingController();
  final TextEditingController _placaEmergenciaCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _estadoAlerta = 'cuenta_regresiva';
  int _segundosRestantes = 5;
  Timer? _timerCuentaRegresiva;

  String _modalidadHurto = 'atraco';
  String _recuperadoPor = 'Policía Nacional / Plan Candado';

  String _placaReal = 'SIN PLACA';
  String _tipoReal = 'Automóvil';
  String _detalleVehiculoReal = 'Ficha tomada del registro S.O.S. Auto';
  String _propietarioReal = 'Propietario S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  List _contactosEmergencia = [];

  double? _lat;
  double? _lng;
  String _gpsTxt = 'Obteniendo GPS...';
  String? _roboDocId;

  StolenCarScreen get _cfg => widget as StolenCarScreen;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudadReal';

  @override
  void initState() {
    super.initState();
    _precargarVehiculoYGps();
    _iniciarCuentaRegresiva();
  }

  Future _precargarVehiculoYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map;
        final v = d['vehicle'] as Map? ?? {};
        final o = d['owner'] as Map? ?? {};
        final l = d['location'] as Map? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ??
                    (VehicleSession.hasVehicle ? VehicleSession.plate : null) ??
                    _cfg.placaRegistrada ??
                    'SIN PLACA')
                .toString()
                .toUpperCase();
            _tipoReal = (v['type'] ??
                    (VehicleSession.vehicleType.isNotEmpty
                        ? VehicleSession.vehicleType
                        : null) ??
                    _cfg.tipoVehiculoRegistrado ??
                    'Automóvil')
                .toString();
            final marca = (v['brand'] ?? VehicleSession.brand).toString();
            final modelo = (v['model'] ?? VehicleSession.model).toString();
            final color = (v['color'] ?? VehicleSession.color).toString();
            final combinado = '$marca $modelo • Color $color'.trim();
            _detalleVehiculoReal =
                combinado.length == 8 || combinado.length == 7 || combinado.isEmpty
                    ? 'Vehículo registrado'
                    : combinado;
            _propietarioReal = (o['name'] ??
                    (VehicleSession.driverName.isNotEmpty
                        ? VehicleSession.driverName
                        : 'Propietario'))
                .toString();
            _ciudadReal = (l['city'] ??
                    (VehicleSession.city.isNotEmpty ? VehicleSession.city : null) ??
                    _cfg.ciudadActual ??
                    'Colombia')
                .toString();
            _contactosEmergencia = d['emergencyContacts'] as List? ?? [];
          });
        }
      } else if (VehicleSession.hasVehicle) {
        if (mounted) {
          setState(() {
            _placaReal = VehicleSession.plate.toUpperCase();
            _tipoReal = VehicleSession.vehicleType;
            final combinado =
                '${VehicleSession.brand} ${VehicleSession.model} • Color ${VehicleSession.color}'
                    .trim();
            _detalleVehiculoReal = combinado;
            _propietarioReal = VehicleSession.driverName.isNotEmpty
                ? VehicleSession.driverName
                : 'Propietario';
            _ciudadReal =
                VehicleSession.city.isNotEmpty ? VehicleSession.city : 'Colombia';
            if (VehicleSession.emergencyContactPhone.isNotEmpty) {
              _contactosEmergencia = [
                {
                  'name': VehicleSession.emergencyContactName.isNotEmpty
                      ? VehicleSession.emergencyContactName
                      : 'Contacto de Emergencia',
                  'fullPhone': VehicleSession.emergencyContactPhone,
                }
              ];
            }
          });
        }
      } else if (_cfg.placaRegistrada != null &&
          _cfg.placaRegistrada!.isNotEmpty) {
        setState(() => _placaReal = _cfg.placaRegistrada!.trim().toUpperCase());
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _gpsTxt =
                '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _gpsTxt = 'GPS sin permiso ($_ciudadReal)');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTxt = 'Ubicación: $_ciudadReal');
    }
  }

  void _iniciarCuentaRegresiva() {
    _timerCuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes == 5 ||
          _segundosRestantes == 4 ||
          _segundosRestantes == 3 ||
          _segundosRestantes == 2) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
        _activarAlertaRoboReal();
      }
    });
  }

  Future _activarAlertaRoboReal() async {
    setState(() {
      _segundosRestantes = 0;
      _estadoAlerta = 'alerta_activa';
    });

    EmergencyAlertService.alertarRoboVehiculo(
      placa: _placaReal,
      tipoVehiculo: _tipoReal,
      ciudad: _ciudadReal,
    );

    try {
      final ref = await FirebaseFirestore.instance
          .collection('vehiculos_robados')
          .add({
        'placa': _placaReal,
        'tipoVehiculo': _tipoReal,
        'detalleVehiculo': _detalleVehiculoReal,
        'propietario': _propietarioReal,
        'ciudad': _ciudadReal,
        'modalidad': _modalidadHurto,
        'latitud': _lat,
        'longitud': _lng,
        'mapsUrl': _mapsUrl,
        'activa': true,
        'estado': 'ROBADO_BUSQUEDA_ACTIVA',
        'reportadoEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      _roboDocId = ref.id;

      // Publicar también en el banner dinámico superior en tiempo real
      await BannerFeedService.publishAlert(
        id: 'stolen_${_roboDocId ?? _placaReal}',
        category: 'stolen',
        tag: 'VEHÍCULO ROBADO — ALERTA EN VIVO',
        title: '$_tipoReal ($_detalleVehiculoReal) • Placa $_placaReal — $_ciudadReal',
        city: _ciudadReal,
        plate: _placaReal,
      );
    } catch (_) {}
  }

  void _cancelarDuranteCuentaRegresiva() {
    _timerCuentaRegresiva?.cancel();
    EmergencyAlertService.detenerVoz();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de robo desactivada antes de publicarse.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
    Navigator.of(context).pop();
  }

  Future _actualizarDatosHuida() async {
    final desc = _detalleHuidaCtrl.text.trim();
    final placaDigitada = _placaEmergenciaCtrl.text.trim().toUpperCase();

    if (placaDigitada.isNotEmpty) {
      setState(() => _placaReal = placaDigitada);
    }

    if (_roboDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_roboDocId)
            .update({
          'placa': _placaReal,
          'modalidad': _modalidadHurto,
          'detalleHuida': desc,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });

        await BannerFeedService.publishAlert(
          id: 'stolen_$_roboDocId',
          category: 'stolen',
          tag: 'VEHÍCULO ROBADO — ALERTA EN VIVO',
          title:
              '$_tipoReal • Placa $_placaReal — $_ciudadReal${desc.isNotEmpty ? " ($desc)" : ""}',
          city: _ciudadReal,
          plate: _placaReal,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos de ruta y modalidad actualizados en la alerta activa.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
  }

  Future _marcarAutoRecuperado() async {
    EmergencyAlertService.detenerVoz();
    final notaRec = _detalleRecuperacionCtrl.text.trim();
    if (_roboDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos_robados')
            .doc(_roboDocId)
            .update({
          'activa': false,
          'estado': 'RECUPERADO',
          'recuperadoPor': _recuperadoPor,
          'notaRecuperacion': notaRec,
          'recuperadoEn': FieldValue.serverTimestamp(),
        });

        await BannerFeedService.deactivateAlert('stolen_$_roboDocId');
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _estadoAlerta = 'recuperado');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '¡Excelente noticia! Alerta cerrada y $_placaReal marcado como RECUPERADO.'),
        backgroundColor: const Color(0xFF0B6E4F),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future _notificarWhatsApp(Map contacto) async {
    final fullPhone = (contacto['fullPhone'] ?? contacto['phone'] ?? '').toString();
    final digits = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final nombre = (contacto['name'] ?? 'Contacto').toString();
    final huida = _detalleHuidaCtrl.text.trim();
    final msg = Uri.encodeComponent(
      '🚨 *ALERTA S.O.S. AUTO — ROBO DE VEHÍCULO* 🚨\n'
      'Hola $nombre, soy *$_propietarioReal*. Me acaban de robar mi vehículo:\n'
      '• *Placa:* *$_placaReal*\n'
      '• *Vehículo:* $_tipoReal ($_detalleVehiculoReal)\n'
      '${huida.isNotEmpty ? '• *Ruta / Detalles:* $huida\n' : ''}'
      '• *Mi ubicación actual (necesito que me recojan):* $_mapsUrl',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future _compartirAvistamientoWhatsApp(Map carData) async {
    final placa = (carData['placa'] ?? 'SIN PLACA').toString();
    final tipo = (carData['tipoVehiculo'] ?? 'Vehículo').toString();
    final detalle = (carData['detalleVehiculo'] ?? '').toString();
    final ciudad = (carData['ciudad'] ?? '').toString();
    final msg = Uri.encodeComponent(
      '🚨 *BOLETÍN DE BÚSQUEDA — S.O.S. AUTO* 🚨\n'
      'Vehículo reportado como robado:\n'
      '• *Placa:* *$placa*\n'
      '• *Características:* $tipo ($detalle)\n'
      '• *Ciudad de reporte:* $ciudad\n'
      'Si lo ves, llama de inmediato al *123* o repórtalo en S.O.S. Auto.',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future _llamar123() async {
    final uri = Uri.parse('tel:123');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _timerCuentaRegresiva?.cancel();
    EmergencyAlertService.detenerVoz();
    _detalleHuidaCtrl.dispose();
    _detalleRecuperacionCtrl.dispose();
    _placaEmergenciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esRecuperado = _estadoAlerta == 'recuperado';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor:
              esRecuperado ? const Color(0xFF0B6E4F) : const Color(0xFFB71C1C),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Icon(esRecuperado ? Icons.verified : Icons.directions_car_filled,
                  size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  esRecuperado
                      ? 'Auto Recuperado • $_placaReal'
                      : 'Robo de Auto y Búsqueda',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.sos), text: 'Reportar mi robo'),
              Tab(icon: Icon(Icons.directions_car), text: 'Autos robados'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // PESTAÑA 1: REPORTAR MI ROBO (CONSERVA TODA TU LÓGICA ACTUAL)
              _estadoAlerta == 'cuenta_regresiva'
                  ? _buildPantallaCuentaRegresiva()
                  : _estadoAlerta == 'alerta_activa'
                      ? _buildPantallaAlertaActiva()
                      : _buildPantallaAutoRecuperado(),

              // PESTAÑA 2: LISTADO EN VIVO DE AUTOS ROBADOS EN LA RED
              _buildListaAutosRobadosEnVivo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaAutosRobadosEnVivo() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('vehiculos_robados')
          .where('activa', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final querySnap = snapshot.data as QuerySnapshot?;
        final docs = querySnap?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 64, color: Colors.green.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    'Sin reportes activos de vehículos robados en este momento',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cuando un conductor active una alerta de robo en S.O.S. Auto, aparecerá aquí al instante con su placa y características.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map;
            final String placa = (data['placa'] ?? 'SIN PLACA').toString();
            final String tipo = (data['tipoVehiculo'] ?? 'Vehículo').toString();
            final String detalle = (data['detalleVehiculo'] ?? '').toString();
            final String ciudad = (data['ciudad'] ?? 'Colombia').toString();
            final String modalidad = (data['modalidad'] ?? '').toString();
            final String huida = (data['detalleHuida'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFEF9A9A), width: 1.2),
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
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black87, width: 1.5),
                          ),
                          child: Text(
                            placa,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFFB71C1C),
                                ),
                              ),
                              Text(
                                detalle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📍 Ciudad: $ciudad${modalidad.isNotEmpty ? " • Modalidad: ${modalidad.toUpperCase()}" : ""}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (huida.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🧭 Ruta / Detalle: $huida',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: _llamar123,
                            icon: const Icon(Icons.call, size: 17),
                            label: const Text(
                              '¡Lo vi! Llamar 123',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => _compartirAvistamientoWhatsApp(data),
                            icon: const Icon(Icons.share, size: 17),
                            label: const Text(
                              'Difundir',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
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
    );
  }

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
          const Text(
            'ACTIVANDO ALERTA DE ROBO EN:',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                  color: Color(0xFFB71C1C)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vehículo: $_tipoReal • Placa: $_placaReal\nSe publicará la alerta de búsqueda en la red S.O.S. Auto.',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.cancel, size: 24),
              label: const Text('DESACTIVAR ALERTA AHORA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

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
                  colors: [Color(0xFFC62828), Color(0xFF8E0000)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  '¡ALERTA DE ROBO ACTIVA EN LA RED!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car,
                          color: Colors.amberAccent, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_tipoReal • PLACA: $_placaReal',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(_detalleVehiculoReal,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text('GPS: $_gpsTxt',
                                style: const TextStyle(
                                    color: Colors.amberAccent, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_contactosEmergencia.isNotEmpty)
                  ..._contactosEmergencia.map((c) {
                    final map = c as Map;
                    final nombre = (map['name'] ?? 'Contacto').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _notificarWhatsApp(map),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.chat, size: 18),
                        label: Text(
                            'AVISAR POR WHATSAPP A ${nombre.toUpperCase()}'),
                      ),
                    );
                  }),
                ElevatedButton.icon(
                  onPressed: _llamar123,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8E0000),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('LLAMAR A POLICÍA / PLAN CANDADO (123)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                const Text('1. Recomendaciones Inmediatas para tu Vida',
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E))),
                const SizedBox(height: 10),
                _itemRecomendacion('NO persigas al delincuente:',
                    'Tu vida vale más que cualquier vehículo; nunca intentes seguirlos.'),
                _itemRecomendacion('Busca un sitio seguro e iluminado:',
                    'Entra de inmediato a un local con vigilancia, estación de servicio o CAI cercano.'),
                _itemRecomendacion('Bloqueo rápido:',
                    'Si tu celular o tarjetas quedaron en el auto, bloquea cuentas bancarias y SIM de inmediato.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2. Ampliar datos de búsqueda',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_placaReal == 'SIN PLACA') ...[
                  TextField(
                    controller: _placaEmergenciaCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Ingresa la placa del vehículo robado',
                      hintText: 'Ej. ABC123',
                      prefixIcon: const Icon(Icons.pin, color: Color(0xFFB71C1C)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Atraco'),
                      selected: _modalidadHurto == 'atraco',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                          color: _modalidadHurto == 'atraco'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _modalidadHurto = 'atraco'),
                    ),
                    ChoiceChip(
                      label: const Text('Halado / Estacionado'),
                      selected: _modalidadHurto == 'halado',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                          color: _modalidadHurto == 'halado'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _modalidadHurto = 'halado'),
                    ),
                    ChoiceChip(
                      label: const Text('Engaño / Retén falso'),
                      selected: _modalidadHurto == 'engano',
                      selectedColor: const Color(0xFFB71C1C),
                      labelStyle: TextStyle(
                          color: _modalidadHurto == 'engano'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _modalidadHurto = 'engano'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _detalleHuidaCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Dirección de huida o rasgos (ej. tomaron vía al norte, 2 sujetos...)',
                    prefixIcon:
                        const Icon(Icons.explore, color: Color(0xFFB71C1C)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _actualizarDatosHuida,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44)),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('ACTUALIZAR DATOS DE BÚSQUEDA',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0B6E4F), width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('3. ¿Ya apareció tu vehículo? • Auto Recuperado',
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B6E4F))),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  value: _recuperadoPor,
                  decoration: InputDecoration(
                      labelText: '¿Cómo se logró la recuperación?',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true),
                  items: const [
                    DropdownMenuItem(
                        value: 'Policía Nacional / Plan Candado',
                        child: Text('Policía Nacional / Plan Candado')),
                    DropdownMenuItem(
                        value: 'Comunidad S.O.S. Auto (Avistamiento)',
                        child: Text('Comunidad S.O.S. Auto (Avistamiento)')),
                    DropdownMenuItem(
                        value: 'Rastreo Satelital GPS',
                        child: Text('Rastreo Satelital GPS')),
                    DropdownMenuItem(
                        value: 'Ubicación directa del propietario',
                        child: Text('Ubicación directa del propietario')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _recuperadoPor = v as String);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detalleRecuperacionCtrl,
                  decoration: InputDecoration(
                      hintText: 'Lugar o estado en que se encontró (opcional)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _marcarAutoRecuperado,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6E4F),
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('MARCAR AUTO COMO RECUPERADO',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

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
                border: Border.all(color: const Color(0xFF0B6E4F), width: 2)),
            child: Column(
              children: [
                const Icon(Icons.verified, color: Color(0xFF0B6E4F), size: 64),
                const SizedBox(height: 12),
                const Text('¡VEHÍCULO RECUPERADO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B6E4F))),
                const SizedBox(height: 8),
                Text(
                  '$_tipoReal • Placa: $_placaReal\nRecuperado por: $_recuperadoPor\n\nLa alerta de robo fue cerrada en la red S.O.S. Auto.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5, color: Colors.black87, height: 1.4),
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
                minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.home),
            label: const Text('FINALIZAR Y VOLVER AL INICIO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(
                      text: '$titulo ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
