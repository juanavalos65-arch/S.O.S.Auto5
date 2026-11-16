import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _motivoSeleccionadoId = 'agresion';
  bool _alertaActualizada = false;

  int _segundosVentana = 5;
  Timer? _timerVentana;

  // Datos cargados desde el registro del vehículo
  String _placaReal = 'SIN PLACA';
  String _tipoReal = 'Automóvil';
  String _detalleVehiculo = '';
  String _nombreConductor = 'Conductor S.O.S. Auto';
  String _ciudadReal = 'Colombia';
  List _contactosEmergencia = [];

  // Ubicación GPS y ID de alerta en Firestore
  double? _latitud;
  double? _longitud;
  String _textoGps = 'Obteniendo GPS en vivo...';
  String? _alertaDocId;

  final List _bitacoraEventos = [];

  String get _mapsUrl => (_latitud != null && _longitud != null)
      ? 'https://maps.google.com/?q=$_latitud,$_longitud'
      : 'Ubicación GPS en proceso ($_ciudadReal)';

  final List _motivosPeligro = [
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
        'No confrontes verbal ni físicamente al agresor; deja que el GPS de S.O.S. Auto registre tu ruta.',
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
        'Mantén el micrófono despejado para que los usuarios cercanos y tus contactos reciban la actualización.',
        'Si ves usuarios de S.O.S. Auto cerca en el mapa, haz señales con las luces estacionarias para facilitar tu ubicación.',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarVentanaAnulacion();
    _inicializarAlertaReal();
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _inicializarAlertaReal() async {
    // 1. Cargar datos del vehículo y contactos guardados
    try {
      final rawJson = await _secureStorage.read(key: 'sos_auto_registered_vehicle');
      if (rawJson != null && rawJson.isNotEmpty) {
        final data = jsonDecode(rawJson) as Map<String, dynamic>;
        final vehicle = data['vehicle'] as Map<String, dynamic>? ?? {};
        final owner = data['owner'] as Map<String, dynamic>? ?? {};
        final location = data['location'] as Map<String, dynamic>? ?? {};
        final contacts = data['emergencyContacts'] as List? ?? [];

        if (mounted) {
          setState(() {
            _placaReal = (vehicle['plate'] ?? widget.placaRegistrada ?? 'SIN PLACA').toString().toUpperCase();
            _tipoReal = (vehicle['type'] ?? widget.tipoVehiculoRegistrado ?? 'Automóvil').toString();
            final marca = (vehicle['brand'] ?? '').toString();
            final color = (vehicle['color'] ?? '').toString();
            _detalleVehiculo = '$marca $color'.trim();
            _nombreConductor = (owner['name'] ?? 'Conductor S.O.S. Auto').toString();
            _ciudadReal = (location['city'] ?? widget.ciudadActual ?? 'Colombia').toString();
            _contactosEmergencia = contacts;
          });
        }
      } else if (widget.placaRegistrada != null && widget.placaRegistrada!.isNotEmpty) {
        setState(() {
          _placaReal = widget.placaRegistrada!.trim().toUpperCase();
        });
      }
    } catch (_) {}

    // 2. Obtener ubicación GPS real
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _latitud = pos.latitude;
            _longitud = pos.longitude;
            _textoGps = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _textoGps = 'GPS sin permiso ($_ciudadReal)');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _textoGps = 'Ubicación aproximada: $_ciudadReal');
      }
    }

    // 3. Registrar alerta activa en Cloud Firestore
    final hora = _horaActual();
    try {
      final docRef = await FirebaseFirestore.instance.collection('alertas_emergencia').add({
        'tipoAlerta': 'ESTOY_EN_PELIGRO',
        'motivoId': _motivoSeleccionadoId,
        'motivoTitulo': _motivoActual['titulo'],
        'placa': _placaReal,
        'tipoVehiculo': _tipoReal,
        'detalleVehiculo': _detalleVehiculo,
        'conductor': _nombreConductor,
        'ciudad': _ciudadReal,
        'latitud': _latitud,
        'longitud': _longitud,
        'mapsUrl': _mapsUrl,
        'contactosNotificados': _contactosEmergencia.length,
        'activa': true,
        'creadaEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));

      _alertaDocId = docRef.id;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _bitacoraEventos.addAll([
        {
          'hora': hora,
          'destinatario': 'Red S.O.S. Auto y Central en Tiempo Real',
          'estado': 'ACTIVA EN NUBE',
          'detalle': 'Alerta "ESTOY EN PELIGRO" registrada para placa $_placaReal ($_tipoReal $_detalleVehiculo) en $_textoGps.',
        },
        {
          'hora': hora,
          'destinatario': 'Contactos de Emergencia (${_contactosEmergencia.length} registrados)',
          'estado': _contactosEmergencia.isNotEmpty ? 'LISTOS PARA WHATSAPP' : 'SIN CONTACTOS',
          'detalle': _contactosEmergencia.isNotEmpty
              ? 'Toca el botón verde inferior para enviar tu enlace GPS directo por WhatsApp.'
              : 'Registra contactos en el botón "Registro" para envío automático.',
        },
      ]);
    });
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
      _motivosPeligro.firstWhere((m) => m['id'] == _motivoSeleccionadoId) as Map<String, dynamic>;

  void _seleccionarMotivo(String id) {
    setState(() => _motivoSeleccionadoId = id);
  }

  Future<void> _enviarActualizacionMotivo() async {
    final hora = _horaActual();
    final String desc = _motivoDescripcionCtrl.text.trim().isEmpty
        ? 'Sin descripción adicional'
        : _motivoDescripcionCtrl.text.trim();

    if (_alertaDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('alertas_emergencia')
            .doc(_alertaDocId)
            .update({
          'motivoId': _motivoSeleccionadoId,
          'motivoTitulo': _motivoActual['titulo'],
          'descripcion': desc,
          'actualizadaEn': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _alertaActualizada = true;
      _bitacoraEventos.insert(0, {
        'hora': hora,
        'destinatario': 'Actualización de Situación',
        'estado': 'ENVIADO',
        'detalle': 'Motivo: "${_motivoActual['titulo']}" • Detalle: "$desc"',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Motivo actualizado en la alerta activa.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
  }

  Future<void> _notificarContactoWhatsApp(Map contacto) async {
    final fullPhone = (contacto['fullPhone'] ?? contacto['phone'] ?? '').toString();
    final digits = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final nombreContacto = (contacto['name'] ?? 'Contacto').toString();
    final desc = _motivoDescripcionCtrl.text.trim();
    final texto = Uri.encodeComponent(
      '🚨 *ALERTA S.O.S. AUTO — ESTOY EN PELIGRO* 🚨\n'
      'Hola $nombreContacto, soy *$_nombreConductor*.\n'
      '• *Situación:* ${_motivoActual['titulo']}\n'
      '• *Vehículo:* $_tipoReal $_detalleVehiculo | Placa *$_placaReal*\n'
      '${desc.isNotEmpty ? '• *Detalle:* $desc\n' : ''}'
      '• *Mi ubicación GPS en vivo:* $_mapsUrl',
    );

    final uri = Uri.parse('https://wa.me/$digits?text=$texto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _llamarPolicia123() async {
    final uri = Uri.parse('tel:123');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _desactivarAlertaDirecto() async {
    if (_alertaDocId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('alertas_emergencia')
            .doc(_alertaDocId)
            .update({
          'activa': false,
          'desactivadaEn': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta desactivada en la red S.O.S. Auto.'),
        backgroundColor: Color(0xFF0B6E4F),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color colorMotivo = _motivoActual['color'] as Color;
    final List instrucciones = _motivoActual['instrucciones'] as List;
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
                'ALERTA • Estoy en peligro',
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
              // SECCIÓN 1: CABECERA CON DATOS REALES DEL VEHÍCULO Y GPS
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ALERTA DE PELIGRO ACTIVA',
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
                      'Vehículo: $_tipoReal $_detalleVehiculo • Placa: $_placaReal\nGPS: $_textoGps',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),

                    // Botones de envío directo por WhatsApp a los contactos registrados
                    if (_contactosEmergencia.isNotEmpty) ...[
                      ..._contactosEmergencia.map((c) {
                        final contacto = c as Map;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton.icon(
                            onPressed: () => _notificarContactoWhatsApp(contacto),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.chat, size: 19),
                            label: Text(
                              'ENVIAR GPS POR WHATSAPP A ${(contacto['name'] ?? 'CONTACTO').toString().toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    ],

                    ElevatedButton.icon(
                      onPressed: _llamarPolicia123,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8E0000),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text(
                        'LLAMAR A EMERGENCIAS / POLICÍA (123)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 8),

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

              // SECCIÓN 2: BOTONES DE SITUACIÓN DE PELIGRO Y DESCRIPCIÓN
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
                      ? 'ACTUALIZAR SITUACIÓN EN LA NUBE'
                      : 'NOTIFICAR MOTIVO A LA RED S.O.S.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 18),

              // SECCIÓN 3: INSTRUCCIONES DE QUÉ HACER SEGÚN EL MOTIVO
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
                                instrucciones[i].toString(),
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
