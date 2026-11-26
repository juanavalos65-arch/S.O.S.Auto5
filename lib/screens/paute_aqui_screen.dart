import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_notifier_service.dart';

class PauteAquiScreen extends StatefulWidget {
  const PauteAquiScreen({super.key});

  @override
  State<PauteAquiScreen> createState() => _PauteAquiScreenState();
}

class _PauteAquiScreenState extends State<PauteAquiScreen> {
  final _formKey = GlobalKey<FormState>();

  static const String _bancolombia = '31954613201';
  static const String _llave = '71663024';
  static const String _waSoporte = '573116479280';

  static const String _urlGestionPauta =
      'https://us-central1-sos-auto-18e1c.cloudfunctions.net/gestionarPauta';
  static const String _tokenAdmin = 'SOS2026_JGA_9842';

  final _comercioCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  String _categoria = 'Grúas';
  final List _categorias = [
    'Grúas',
    'Talleres / Mecánica',
    'Baterías / Eléctricos',
    'Montallantas',
    'Cerrajería',
    'Abogados / Seguros',
    'Clínicas / Salud Vial',
  ];

  bool _esAliadoPremium = true;

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoDataUrl;

  double? _latComercio;
  double? _lngComercio;
  bool _capturandoGps = false;

  int _planIdx = 0;

  final List _planesEstandar = [
    {
      'nombre': 'Estándar Mensual (30 días)',
      'dias': 30,
      'base': 50000,
      'desc': 'Banner dinámico + Directorio Aliados + Estrella en mapa',
      'wompiUrl': 'https://checkout.wompi.co/l/Q8SgOC',
    },
    {
      'nombre': 'Estándar Semestral (180 días)',
      'dias': 180,
      'base': 250000,
      'desc': 'Prioridad en banner + Aliados + Estrella en mapa',
      'wompiUrl': 'https://checkout.wompi.co/l/uWGzC8',
    },
    {
      'nombre': 'Estándar Anual (365 días)',
      'dias': 365,
      'base': 500000,
      'desc': 'Máxima visibilidad + Sello Oficial + Estrella en mapa',
      'wompiUrl': 'https://checkout.wompi.co/l/3m9LLM',
    },
  ];

  final List _planesPremium = [
    {
      'nombre': 'Aliado Premium Mensual (30 días)',
      'dias': 30,
      'base': 100000,
      'desc': 'Logo fijo en cabecera principal + Estrella dorada en mapa + Banner',
      'wompiUrl': 'https://checkout.wompi.co/l/QQMQaY',
    },
    {
      'nombre': 'Aliado Premium Semestral (180 días)',
      'dias': 180,
      'base': 500000,
      'desc': 'Logo fijo en cabecera principal + Estrella dorada + Prioridad',
      'wompiUrl': 'https://checkout.wompi.co/l/7VzCee',
    },
    {
      'nombre': 'Aliado Premium Anual (365 días)',
      'dias': 365,
      'base': 1000000,
      'desc': 'Logo fijo en cabecera principal + Estrella dorada + Sello VIP',
      'wompiUrl': 'https://checkout.wompi.co/l/hsi3Nx',
    },
  ];

  List get _planesActivos =>
      _esAliadoPremium ? _planesPremium : _planesEstandar;

  bool _guardando = false;

  int get _base => (_planesActivos[_planIdx] as Map)['base'] as int;
  int get _iva => (_base * 0.19).round();
  int get _comisionWompi => ((_base + _iva) * 0.029 + 900).round();
  int get _totalWompi => _base + _iva + _comisionWompi;
  int get _totalLlave => _base + _iva;

  @override
  void dispose() {
    _comercioCtrl.dispose();
    _contactoCtrl.dispose();
    _correoCtrl.dispose();
    _sloganCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _telCtrl.dispose();
    _nitCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  String _cop(int v) {
    final s = v.toString();
    final b = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      b.write(s[i]);
      c++;
      if (c == 3 && i != 0) {
        b.write('.');
        c = 0;
      }
    }
    return '\$${b.toString().split('').reversed.join()} COP';
  }

  void _copiar(String txt, String label) {
    Clipboard.setData(ClipboardData(text: txt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($txt) copiada al portapapeles'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _generarCodigoRef() {
    final rnd = Random.secure();
    final num = 100000 + rnd.nextInt(900000);
    return 'SOS-$num';
  }

  Future<void> _seleccionarLogoConClip() async {
    try {
      final picker = ImagePicker();
      final XFile? archivo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (archivo == null) return;

      final String nombre = archivo.name;
      final String lower = nombre.toLowerCase();
      if (!lower.endsWith('.png') &&
          !lower.endsWith('.jpg') &&
          !lower.endsWith('.jpeg') &&
          !lower.endsWith('.webp')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato no válido. Sube tu logo en PNG, JPG o WEBP.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final Uint8List bytes = await archivo.readAsBytes();
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El logo supera 2 MB. Elige una imagen más liviana.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final String mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final String b64 = base64Encode(bytes);

      setState(() {
        _logoBytes = bytes;
        _logoFileName = nombre;
        _logoDataUrl = 'data:$mime;base64,$b64';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logo "$nombre" adjuntado correctamente.'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la galería. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _capturarGpsComercio() async {
    if (_capturandoGps) return;
    setState(() => _capturandoGps = true);
    try {
      bool activo = await Geolocator.isLocationServiceEnabled();
      if (!activo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activa el GPS del celular para ubicar tu estrella.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 6));

      if (!mounted) return;
      setState(() {
        _latComercio = pos.latitude;
        _lngComercio = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicación GPS capturada. Tu estrella dorada aparecerá en este punto del mapa.',
          ),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _capturandoGps = false);
    }
  }

  Future<void> _geocodificarSiFaltaGps(String direccion, String ciudad) async {
    if (_latComercio != null && _lngComercio != null) return;
    try {
      final query = '$direccion, $ciudad, Colombia';
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'SOSAutoApp/1.0 (soporte.applay65@gmail.com)'},
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Iterable && decoded.isNotEmpty) {
          final first = decoded.first as Map;
          _latComercio = double.tryParse(first['lat'].toString());
          _lngComercio = double.tryParse(first['lon'].toString());
        }
      }
    } catch (_) {}
  }

  Future<void> _abrirWhatsAppComprobante(String textoWa) async {
    final waUri = Uri.parse(
      'https://wa.me/$_waSoporte?text=${Uri.encodeComponent(textoWa)}',
    );
    await launchUrl(waUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _guardarPauta(String metodo) async {
    if (_guardando) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos obligatorios marcados con *'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_esAliadoPremium &&
        _logoBytes == null &&
        _logoUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para Aliado Premium adjunta el logo usando el ícono del clip (PNG/JPG 512x512 px).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final plan = _planesActivos[_planIdx] as Map;
    final dias = plan['dias'] as int;
    final tel = _telCtrl.text.trim();
    final digits = tel.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneFull = digits.startsWith('57') ? digits : '57$digits';
    final wa = '+$phoneFull';
    final nit = _nitCtrl.text.trim().toUpperCase();
    final total = metodo == 'wompi' ? _totalWompi : _totalLlave;
    final nombreComercio = _comercioCtrl.text.trim();
    final nombreResponsable = _contactoCtrl.text.trim();
    final correo = _correoCtrl.text.trim().toLowerCase();
    final slogan = _sloganCtrl.text.trim();
    final ciudad = _ciudadCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final logoUrlFinal = _logoUrlCtrl.text.trim().isNotEmpty
        ? _logoUrlCtrl.text.trim()
        : (_logoDataUrl ?? '');
    final codigoRef = _generarCodigoRef();

    await _geocodificarSiFaltaGps(direccion, ciudad);

    final db = FirebaseFirestore.instance;
    final pautaDocRef = db.collection('pautas_comerciales').doc();

    final linkAprobar =
        '$_urlGestionPauta?id=${pautaDocRef.id}&accion=1&token=$_tokenAdmin';
    final linkRechazar =
        '$_urlGestionPauta?id=${pautaDocRef.id}&accion=2&token=$_tokenAdmin';

    unawaited(
      Future.wait([
        db.collection('pautantes').doc(nit).set({
          'nitODocumento': nit,
          'nombreComercio': nombreComercio,
          'nombreResponsable': nombreResponsable,
          'correo': correo,
          'telefono': tel,
          'whatsapp': wa,
          'ciudad': ciudad,
          'direccion': direccion,
          'lat': _latComercio,
          'lng': _lngComercio,
          'categoria': _categoria,
          'esAliadoPremium': _esAliadoPremium,
          'logoAdjuntoNombre': _logoFileName ?? '',
          'logoUrl': logoUrlFinal,
          'ultimoPlan': plan['nombre'],
          'ultimoMontoCop': total,
          'metodoPago': metodo,
          'actualizadoEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        pautaDocRef.set({
          'codigoReferencia': codigoRef,
          'pautanteId': nit,
          'nombreComercio': nombreComercio,
          'negocio': nombreComercio,
          'servicio': '$_categoria • $slogan',
          'nombreResponsable': nombreResponsable,
          'correo': correo,
          'categoria': _categoria,
          'mensajeBanner': slogan,
          'ciudad': ciudad,
          'direccion': direccion,
          'lat': _latComercio,
          'lng': _lngComercio,
          'esAliadoPremium': _esAliadoPremium,
          'logoAdjuntoNombre': _logoFileName ?? '',
          'logoUrl': logoUrlFinal,
          'nit': nit,
          'phoneFull': phoneFull,
          'telefono': tel,
          'whatsapp': wa,
          'planNombre': plan['nombre'],
          'diasVigencia': dias,
          'valorBaseCop': _base,
          'ivaCop': _iva,
          'comisionPasarelaCop': metodo == 'wompi' ? _comisionWompi : 0,
          'totalPagadoCop': total,
          'metodoPago': metodo,
          'cuentaDestino': 'Bancolombia $_bancolombia / Llave $_llave',
          'activa': false,
          'verificado': false,
          'pagoVerificado': false,
          'estadoPago': 'pendiente_pago',
          'creadoEn': FieldValue.serverTimestamp(),
        }),
      ]).catchError((_) => <void>[]),
    );

    AdminNotifierService.notificarCorreo(
      modulo:
          'Paute Aquí (${_esAliadoPremium ? "PREMIUM" : "ESTÁNDAR"} - $metodo)',
      titulo: '$nombreComercio ($codigoRef) - ${_cop(total)}',
      detalle:
          'Tipo: ${_esAliadoPremium ? "ALIADO PREMIUM (Cabecera + Estrella Mapa)" : "Pauta Estándar"} • '
          'Comercio: $nombreComercio (NIT $nit) • Responsable: $nombreResponsable ($tel / $correo) • '
          'Categoría: $_categoria • Ciudad: $ciudad • Dirección: $direccion • '
          'GPS Estrella: ${_latComercio != null ? "$_latComercio, $_lngComercio" : "Pendiente"} • '
          'Logo: ${_logoFileName ?? (_logoUrlCtrl.text.trim().isNotEmpty ? _logoUrlCtrl.text.trim() : "Sin adjunto")} • '
          'Banner: "$slogan" • Plan: ${plan['nombre']} • Total: ${_cop(total)}\n'
          'APROBAR: $linkAprobar\n'
          'RECHAZAR: $linkRechazar',
      placa: nit,
      ciudad: ciudad,
    );

    final textoWa = '''
*COMPROBANTE DE PAGO PAUTA - S.O.S. AUTO*
Ref: *$codigoRef*
Modalidad: *${_esAliadoPremium ? "ALIADO PREMIUM (Logo Cabecera + Estrella Mapa)" : "PAUTA ESTÁNDAR"}*
Comercio: *$nombreComercio* (NIT: $nit)
Categoría: $_categoria | Ciudad: $ciudad
Dirección: $direccion
Logo adjunto: ${_logoFileName ?? "Enlace / Por enviar"}
Mensaje: "$slogan"
Plan: ${plan['nombre']}
Método: ${metodo.toUpperCase()}
Total pagado: *${_cop(total)}*

_Adjunto captura del comprobante y el archivo del logo para verificación en Bancolombia ($_bancolombia), Bre-B ($_llave) o Wompi._

1. *APROBAR Y PUBLICAR:*
$linkAprobar

2. *RECHAZAR:*
$linkRechazar
''';

    if (metodo == 'wompi') {
      final wompiBaseUrl = plan['wompiUrl'] as String;
      await launchUrl(Uri.parse(wompiBaseUrl),
          mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(const ClipboardData(text: _llave));
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          metodo == 'wompi'
              ? 'Pasarela Wompi Abierta ($codigoRef)'
              : 'Datos de Pago Listos ($codigoRef)',
        ),
        content: Text(
          metodo == 'wompi'
              ? 'Se abrió Wompi por ${_cop(total)}.\n\n'
                  '1. Realiza el pago en la página de Wompi.\n'
                  '2. Cuando tengas el comprobante, regresa aquí y toca "Ya pagué — Enviar comprobante" (recuerda adjuntar también tu logo en el chat).'
              : 'Copiamos la Llave Bre-B ($_llave) a tu portapapeles.\n\n'
                  '1. Abre tu app bancaria y transfiere ${_cop(total)} a la Llave $_llave o Bancolombia Ahorros $_bancolombia.\n'
                  '2. Cuando realices el pago, toca el botón verde inferior para enviarnos el comprobante y tu logo por WhatsApp.',
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _abrirWhatsAppComprobante(textoWa),
            icon: const Icon(Icons.chat),
            label: const Text('Ya pagué — Enviar comprobante'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paute Aquí — Aliados'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '1. Datos del Pautante',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _contactoCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Nombre del responsable *', Icons.person),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nitCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _dec('NIT / Cédula *', Icons.badge),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ciudadCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec('Ciudad *', Icons.location_city),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _dec('Correo electrónico *', Icons.email_outlined),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Correo no válido'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration:
                      _dec('Celular / WhatsApp 24/7 *', Icons.phone_in_talk),
                  validator: (v) => (v == null || v.trim().length < 7)
                      ? 'Número no válido'
                      : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  '2. Datos del Anuncio y Logo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: _dec('Categoría *', Icons.category),
                  items: _categorias
                      .map((c) => DropdownMenuItem<String>(
                            value: c.toString(),
                            child: Text(c.toString()),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoria = v);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _comercioCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Nombre comercial *', Icons.store),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _sloganCtrl,
                  maxLength: 75,
                  decoration:
                      _dec('Texto corto para banner *', Icons.short_text),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: _dec('Dirección / Cobertura *', Icons.place),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: _capturandoGps ? null : _capturarGpsComercio,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A192F),
                    side: BorderSide(
                      color: _latComercio != null
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF0A192F),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    _latComercio != null ? Icons.star : Icons.my_location,
                    color: _latComercio != null
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF1565C0),
                  ),
                  label: Text(
                    _capturandoGps
                        ? 'OBTENIENDO COORDENADAS GPS...'
                        : (_latComercio != null
                            ? 'Estrella en mapa lista (${_latComercio!.toStringAsFixed(4)}, ${_lngComercio!.toStringAsFixed(4)})'
                            : 'Fijar mi ubicación GPS para estrella en el mapa'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Logo de la Empresa (Aliados Premium)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF0A192F),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _seleccionarLogoConClip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A192F),
                              foregroundColor: const Color(0xFFFBC02D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: Text(
                              _logoBytes == null ? 'Subir logo' : 'Cambiar',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '• Formato recomendado: PNG (fondo transparente o blanco) o JPG.\n'
                        '• Tamaño ideal: 512 × 512 px (cuadrado 1:1) · Peso máximo: 2 MB.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                      if (_logoBytes != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _logoBytes!,
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Adjunto: ${_logoFileName ?? "logo.png"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar logo',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _logoBytes = null;
                                  _logoFileName = null;
                                  _logoDataUrl = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  '3. Modalidad, Plan y Pago',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: _esAliadoPremium,
                        selectedColor: const Color(0xFF1B5E20),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Aliado Premium\n(Logo + Estrella)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _esAliadoPremium
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _esAliadoPremium = true;
                            _planIdx = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        selected: !_esAliadoPremium,
                        selectedColor: const Color(0xFF0A192F),
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Pauta Estándar\n(Banner + Mapa)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_esAliadoPremium
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _esAliadoPremium = false;
                            _planIdx = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                for (int i = 0; i < _planesActivos.length; i++)
                  Card(
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: _planIdx,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (v) {
                        if (v != null) setState(() => _planIdx = v);
                      },
                      title: Text(
                        '${(_planesActivos[i] as Map)['nombre']} — ${_cop((_planesActivos[i] as Map)['base'] as int)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        (_planesActivos[i] as Map)['desc'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1565C0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Llave Bre-B: 71663024',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _copiar(_llave, 'Llave'),
                            child: const Text('Copiar'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bancolombia Ahorros: 31954613201',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _copiar(_bancolombia, 'Cuenta'),
                            child: const Text('Copiar'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        'Total Llave / Bancolombia (Base + IVA): ${_cop(_totalLlave)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Wompi (incluye pasarela): ${_cop(_totalWompi)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nota: El anuncio, logo y estrella en mapa se publican tras confirmar el abono real en cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : () => _guardarPauta('wompi'),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    _guardando ? 'ABRIENDO PASARELA...' : 'PAGAR CON WOMPI',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : () => _guardarPauta('llave'),
                  icon: const Icon(Icons.key, color: Colors.white),
                  label: const Text(
                    'PAGAR CON LLAVE 71663024 / BANCOLOMBIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
