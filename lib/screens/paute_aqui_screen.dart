import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
      'https://us-central1-sos-auto-app.cloudfunctions.net/gestionarPauta';
  static const String _tokenAdmin = 'SOS2026_JGA_9842';

  final _comercioCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();

  String _categoria = 'Grúas';
  final _categorias = [
    'Grúas',
    'Talleres / Mecánica',
    'Baterías / Eléctricos',
    'Montallantas',
    'Cerrajería',
    'Abogados / Seguros',
  ];

  int _planIdx = 0;
  final _planes = [
    {
      'nombre': 'Mensual (30 días)',
      'dias': 30,
      'base': 50000,
      'desc': 'Banner + Aliados + WhatsApp',
      'wompiUrl': 'https://checkout.wompi.co/l/Q8SgOC',
    },
    {
      'nombre': 'Semestral (180 días)',
      'dias': 180,
      'base': 250000,
      'desc': 'Prioridad en banner + Aliados',
      'wompiUrl': 'https://checkout.wompi.co/l/uWGzC8',
    },
    {
      'nombre': 'Anual (365 días)',
      'dias': 365,
      'base': 500000,
      'desc': 'Máxima visibilidad + Sello Oficial',
      'wompiUrl': 'https://checkout.wompi.co/l/3m9LLM',
    },
  ];

  bool _guardando = false;

  int get _base => _planes[_planIdx]['base'] as int;
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
        content: Text('$label ($txt) copiada'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _generarCodigoRef() {
    final rnd = Random.secure();
    final num = 100000 + rnd.nextInt(900000);
    return 'SOS-$num';
  }

  Future<void> _guardarPauta(String metodo) async {
    if (_guardando) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los campos obligatorios'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final plan = _planes[_planIdx];
    final dias = plan['dias'] as int;
    final tel = _telCtrl.text.trim();
    final digits = tel.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneFull = digits.startsWith('57') ? digits : '57$digits';
    final wa = '+$phoneFull';
    final nit = _nitCtrl.text.trim().toUpperCase();
    final total = metodo == 'wompi' ? _totalWompi : _totalLlave;
    final nombreComercio = _comercioCtrl.text.trim();
    final slogan = _sloganCtrl.text.trim();
    final ciudad = _ciudadCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final codigoRef = _generarCodigoRef();

    try {
      final db = FirebaseFirestore.instance;

      await db.collection('pautantes').doc(nit).set({
        'nitODocumento': nit,
        'nombreComercio': nombreComercio,
        'nombreResponsable': _contactoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim().toLowerCase(),
        'telefono': tel,
        'whatsapp': wa,
        'ciudad': ciudad,
        'direccion': direccion,
        'categoria': _categoria,
        'ultimoPlan': plan['nombre'],
        'ultimoMontoCop': total,
        'metodoPago': metodo,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));

      final ref = await db.collection('pautas_comerciales').add({
        'codigoReferencia': codigoRef,
        'pautanteId': nit,
        'nombreComercio': nombreComercio,
        'nombreResponsable': _contactoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim().toLowerCase(),
        'categoria': _categoria,
        'mensajeBanner': slogan,
        'ciudad': ciudad,
        'direccion': direccion,
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
        'estadoPago': 'pendiente_aprobacion',
        'creadoEn': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      final linkAprobar =
          '$_urlGestionPauta?id=${ref.id}&accion=1&token=$_tokenAdmin';
      final linkRechazar =
          '$_urlGestionPauta?id=${ref.id}&accion=2&token=$_tokenAdmin';

      if (metodo == 'wompi') {
        final wompiUrl = plan['wompiUrl'] as String;
        final uri = Uri.parse('$wompiUrl?reference=$codigoRef-${ref.id}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (metodo == 'llave') {
        Clipboard.setData(const ClipboardData(text: _llave));
      }

      final textoWa = '''
*NUEVA SOLICITUD DE PAUTA - S.O.S. AUTO*
Ref: *$codigoRef*
Comercio: *$nombreComercio* (NIT: $nit)
Categoría: $_categoria | Ciudad: $ciudad
Mensaje: "$slogan"
Plan: ${plan['nombre']}
Método: ${metodo.toUpperCase()}
Total a verificar: *${_cop(total)}*

_Verifica primero en tu app Bancolombia ($_bancolombia), Bre-B ($_llave) o Wompi que el dinero haya ingresado._

1. *APROBAR Y PUBLICAR:*
$linkAprobar

2. *RECHAZAR:*
$linkRechazar
''';

      final waUri = Uri.parse(
        'https://wa.me/$_waSoporte?text=${Uri.encodeComponent(textoWa)}',
      );
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Solicitud recibida'),
          content: Text(
            'Tu pauta ($codigoRef) quedó registrada en estado PENDIENTE DE VERIFICACIÓN.\n\n'
            'Una vez confirmemos la acreditación real del pago de ${_cop(total)}, '
            'tu anuncio se activará automáticamente en el banner y directorio de aliados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) => InputDecoration(
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nitCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _dec('NIT / Cédula *', Icons.badge),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ciudadCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec('Ciudad *', Icons.location_city),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Correo electrónico *', Icons.email_outlined),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Correo no válido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: _dec('Celular / WhatsApp 24/7 *', Icons.phone_in_talk),
                  validator: (v) =>
                      (v == null || v.trim().length < 7) ? 'Número no válido' : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  '2. Datos del Anuncio',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: _dec('Categoría *', Icons.category),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _sloganCtrl,
                  maxLength: 75,
                  decoration: _dec('Texto corto para banner *', Icons.short_text),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: _dec('Dirección / Cobertura *', Icons.place),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  '3. Plan y Pago',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_planes.length, (i) {
                  final p = _planes[i];
                  return Card(
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: _planIdx,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (v) {
                        if (v != null) setState(() => _planIdx = v);
                      },
                      title: Text(
                        '${p['nombre']} — ${_cop(p['base'] as int)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        p['desc'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }),
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
                        'Nota: El anuncio se publica únicamente tras confirmar el abono real en cuenta.',
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
                    _guardando ? 'ENVIANDO SOLICITUD...' : 'PAGAR CON WOMPI',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
