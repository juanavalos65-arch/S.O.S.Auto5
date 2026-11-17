import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_alert_service.dart';

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

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada: $_ciudadReal';

  @override
  void initState() {
    super.initState();
    _precargarVehiculoYGps();
    _iniciarCuentaRegresiva();
  }

  Future<void> _precargarVehiculoYGps() async {
    try {
      final raw = await _storage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final d = jsonDecode(raw) as Map<String, dynamic>;
        final v = d['vehicle'] as Map<String, dynamic>? ?? {};
        final o = d['owner'] as Map<String, dynamic>? ?? {};
        final l = d['location'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _placaReal = (v['plate'] ?? widget.placaRegistrada ?? 'SIN PLACA')
                .toString()
                .toUpperCase();
            _tipoReal = (v['type'] ?? widget.tipoVehiculoRegistrado ?? 'Automóvil')
                .toString();
            final marca = (v['brand'] ?? '').toString();
            final modelo = (v['model'] ?? '').toString();
            final color = (v['color'] ?? '').toString();
            final combinado = '$marca $modelo • Color $color'.trim();
            _detalleVehiculoReal =
                combinado.length > 8 ? combinado : 'Vehículo registrado';
            _propietarioReal = (o['name'] ?? 'Propietario').toString();
            _ciudadReal = (l['city'] ?? widget.ciudadActual ?? 'Colombia').toString();
            _contactosEmergencia = d['emergencyContacts'] as List? ?? [];
          });
        }
      } else if (widget.placaRegistrada != null &&
          widget.placaRegistrada!.isNotEmpty) {
        setState(() => _placaReal = widget.placaRegistrada!.trim().toUpperCase());
      }
    } catch (_) {}

    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
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
      if (_segundosRestantes > 1) {
        setState(() => _segundosRestantes--);
      } else {
        timer.cancel();
        _activarAlertaRoboReal();
      }
    });
  }

  Future<void> _activarAlertaRoboReal() async {
    setState(() {
      _segundosRestantes = 0;
      _estadoAlerta = 'alerta_activa';
    });

    // Dispara alarma sonora, vibración y aviso de voz
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

  Future<void> _actualizarDatosHuida() async {
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

  Future<void> _marcarAutoRecuperado() async {
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

  Future<void> _notificarWhatsApp(Map contacto) async {
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

  Future<void> _llamar123() async {
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

    return Scaffold(
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
                    : 'ALERTA • Robo de Auto',
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
                    color: Colors.white.withValues(alpha: 0.14),
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
                DropdownButtonFormField<String>(
                  initialValue: _recuperadoPor,
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
