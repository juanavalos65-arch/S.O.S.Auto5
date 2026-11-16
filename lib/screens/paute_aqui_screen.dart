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

  static const String _wompiCheckoutUrl = 'https://checkout.wompi.co/l/test_VPOS_S0SAuto';
  static const String _cuentaBancolombia = '31954613201';
  static const String _llaveBreB = '71663024';
  static const String _whatsappSoporte = '573116479280';

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerContactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();

  String _selectedCategory = 'Grúa y Asistencia Vial';
  final List _categories = [
    'Grúa y Asistencia Vial',
    'Taller Mecánico y Eléctrico',
    'Montallantas y Baterías',
    'Repuestos y Accesorios',
    'Lavadero y Estética',
    'Abogados de Tránsito',
    'Aseguradoras y SOAT',
  ];

  int _selectedPlanIndex = 0;
  final List _plans = [
    {
      'nombre': 'Plan Mensual (30 días)',
      'dias': 30,
      'baseCop': 50000,
      'descripcion': 'Banner rotativo + Directorio de Aliados + Botón directo WhatsApp',
    },
    {
      'nombre': 'Plan Semestral (180 días — Ahorra \$50.000)',
      'dias': 180,
      'baseCop': 250000,
      'descripcion': 'Prioridad en banner + Destacado en Aliados cercanos',
    },
    {
      'nombre': 'Plan Anual (365 días — Ahorra \$100.000)',
      'dias': 365,
      'baseCop': 500000,
      'descripcion': 'Máxima visibilidad continental + Sello Aliado Oficial',
    },
  ];

  bool _isSubmitting = false;

  int get _baseAmount => _plans[_selectedPlanIndex]['baseCop'] as int;
  int get _ivaAmount => (_baseAmount * 0.19).round();
  int get _gatewayFee => ((_baseAmount + _ivaAmount) * 0.029 + 900).round();
  int get _totalWompiCop => _baseAmount + _ivaAmount + _gatewayFee;
  int get _totalLlaveDirectaCop => _baseAmount + _ivaAmount;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerContactController.dispose();
    _emailController.dispose();
    _sloganController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _nitController.dispose();
    super.dispose();
  }

  String _formatCop(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return '\$${buffer.toString().split('').reversed.join()} COP';
  }

  void _copiarTexto(String texto, String etiqueta) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$etiqueta ($texto) copiada al portapapeles.'),
        backgroundColor: const Color(0xFF0D1B2A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _publishAndPay({required String metodoPago}) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los datos obligatorios del pautante y comercio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final plan = _plans[_selectedPlanIndex] as Map;
    final now = DateTime.now();
    final dias = plan['dias'] as int;
    final expiresAt = now.add(Duration(days: dias));
    final alertRenewalAt = expiresAt.subtract(const Duration(days: 2));
    final cleanPhone = _phoneController.text.trim();
    final fullWhatsapp = cleanPhone.startsWith('57') ? '+$cleanPhone' : '+57$cleanPhone';
    final cleanNit = _nitController.text.trim().toUpperCase();

    final int montoFinal =
        metodoPago == 'wompi' ? _totalWompiCop : _totalLlaveDirectaCop;

    try {
      final db = FirebaseFirestore.instance;

      // 1. Guardar ficha completa del PAUTANTE en colección 'pautantes'
      await db.collection('pautantes').doc(cleanNit).set({
        'nitODocumento': cleanNit,
        'nombreComercio': _businessNameController.text.trim(),
        'nombreResponsable': _ownerContactController.text.trim(),
        'correo': _emailController.text.trim().toLowerCase(),
        'telefono': cleanPhone,
        'whatsapp': fullWhatsapp,
        'ciudad': _cityController.text.trim(),
        'direccion': _addressController.text.trim(),
        'categoria': _selectedCategory,
        'ultimoPlan': plan['nombre'],
        'ultimoMontoPagadoCop': montoFinal,
        'metodoPago': metodoPago,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));

      // 2. Publicar la PAUTA ACTIVA en colección 'pautas_comerciales'
      final docRef = await db.collection('pautas_comerciales').add({
        'pautanteId': cleanNit,
        'nombreComercio': _businessNameController.text.trim(),
        'nombreResponsable': _ownerContactController.text.trim(),
        'correo': _emailController.text.trim().toLowerCase(),
        'categoria': _selectedCategory,
        'mensajeBanner': _sloganController.text.trim(),
        'ciudad': _cityController.text.trim(),
        'direccion': _addressController.text.trim(),
        'nit': cleanNit,
        'telefono': cleanPhone,
        'whatsapp': fullWhatsapp,
        'planNombre': plan['nombre'],
        'diasVigencia': dias,
        'valorBaseCop': _baseAmount,
        'ivaCop': _ivaAmount,
        'comisionPasarelaCop': metodoPago == 'wompi' ? _gatewayFee : 0,
        'totalPagadoCop': montoFinal,
        'metodoPago': metodoPago,
        'cuentaDestino': 'Bancolombia Ahorros $_cuentaBancolombia / Llave$_llaveBreB',
        'activa': true,
        'estadoPago': metodoPago == 'wompi'
            ? 'en_pasarela_wompi'
            : (metodoPago == 'llave' ? 'reportado_llave_directa' : 'activacion_directa'),
        'creadoEn': FieldValue.serverTimestamp(),
        'expiraEn': Timestamp.fromDate(expiresAt),
        'alertaVencimientoEn': Timestamp.fromDate(alertRenewalAt),
      }).timeout(const Duration(seconds: 10));

      if (metodoPago == 'wompi') {
        final uri = Uri.parse(
          '$_wompiCheckoutUrl?reference=SOSAUTO-${docRef.id}&amount-in-cents=${montoFinal * 100}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (metodoPago == 'llave') {
        Clipboard.setData(const ClipboardData(text: _llaveBreB));
        final msg = Uri.encodeComponent(
          'Hola S.O.S. Auto, acabo de registrar la pauta de *${_businessNameController.text.trim()}* '
          '(NIT/ID: $cleanNit \vert{} Ref:${docRef.id}) por valor de *${_formatCop(montoFinal)}* '
          'a la Llave $_llaveBreB / Bancolombia$_cuentaBancolombia. Adjunto comprobante:',
        );
        final waUri = Uri.parse('https://wa.me/$_whatsappSoporte?text=$msg');
        if (await canLaunchUrl(waUri)) {
          await launchUrl(waUri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Pautante y pauta "${_businessNameController.text.trim()}" guard
