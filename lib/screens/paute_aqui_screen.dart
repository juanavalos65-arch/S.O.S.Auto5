import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/banner_feed_service.dart';

class PauteAquiScreen extends StatefulWidget {
  const PauteAquiScreen({super.key});

  @override
  State createState() => _PauteAquiScreenState();
}

class _PauteAquiScreenState extends State {
  final _formKey = GlobalKey();

  static const String _bancolombia = '31954613201';
  static const String _llave = '71663024';
  static const String _waSoporte = '573116479280';

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

  Future _guardarPauta(String metodo) async {
    if (_guardando) return;
    final formState = _formKey.currentState as FormState?;
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
    final expira = DateTime.now().add(Duration(days: dias));
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

    try {
      final db = FirebaseFirestore.instance;

      // 1. Guardar ficha del pautante
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

      // 2. Guardar registro de la pauta comercial
      final ref = await db.collection('pautas_comerciales').add({
        'pautanteId': nit,
        'nombreComercio': nombreComercio,
        'nombreResponsable': _contactoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim().toLowerCase(),
        'categoria': _categoria,
        'mensajeBanner': slogan,
        'ciudad': ciudad,
        'direccion': direccion,
        'nit': nit,
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
        'activa': true,
        'estadoPago': metodo == 'wompi' ? 'en_pasarela_wompi' : 'activado_$metodo',
        'creadoEn': FieldValue.serverTimestamp(),
        'expiraEn': Timestamp.fromDate(expira),
      }).timeout(const Duration(seconds: 10));

      // 3. Publicar en el directorio en vivo ('aliados') para AlliesScreen
      await db.collection('aliados').doc(nit).set({
        'name': nombreComercio,
        'category': _categoria,
        'city': ciudad,
        'description': '$slogan ($direccion)',
        'phone': phoneFull,
        'activo': true,
        'plan': plan['nombre'],
        'expiraEn': Timestamp.fromDate(expira),
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));

      // 4. Publicar en el banner dinámico superior en tiempo real
      await BannerFeedService.publishAlert(
        id: 'ad_$nit',
        category: 'ad',
        tag: 'ALIADO OFICIAL • $_categoria ($ciudad)',
        title: '$nombreComercio — $slogan',
        city: ciudad,
      );

      if (metodo == 'wompi') {
        final wompiUrl = plan['wompiUrl'] as String;
        final uri = Uri.parse('$wompiUrl?reference=SOSAUTO-${ref.id}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (metodo == 'llave') {
        Clipboard.setData(const ClipboardData(text: _llave));
        final msg = Uri.encodeComponent(
          'Hola S.O.S. Auto, registré pauta de *$nombreComercio* (NIT $nit) por *${_cop(total)}* a Llave $_llave / Bancolombia $_bancolombia.',
        );
        final waUri = Uri.parse('https://wa.me/$_waSoporte?text=$msg');
        if (await canLaunchUrl(waUri)) {
          await launchUrl(waUri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pauta publicada en Banner y Directorio de Aliados!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error Firebase: $e'),
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
                  validator: (v) => (v == null || v.trim().length == 1 || v.trim().length == 2 || v.trim().length == 3 || v.trim().length == 4 || v.trim().length == 5 || v.trim().length == 6 || v.trim().isEmpty)
                      ? 'Número no válido'
                      : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  '2. Datos del Anuncio',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: _categoria,
                  decoration: _dec('Categoría *', Icons.category),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c as String)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _categoria = v as String);
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
                    child: RadioListTile(
                      value: i,
                      groupValue: _planIdx,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (v) {
                        if (v != null) setState(() => _planIdx = v as int);
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : () => _guardarPauta('wompi'),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    _guardando ? 'GUARDANDO...' : 'PAGAR CON WOMPI Y PUBLICAR',
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
                    'PAGAR CON LLAVE 71663024',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _guardando ? null : () => _guardarPauta('directa'),
                  icon: const Icon(Icons.bolt),
                  label: const Text('ACTIVAR PAUTA DIRECTA (PRUEBA)'),
                  style: OutlinedButton.styleFrom(
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
