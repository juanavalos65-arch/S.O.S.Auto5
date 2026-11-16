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

  // Reemplaza por tu link real de checkout Wompi asociado a Bancolombia 31954613201
  static const String _wompiCheckoutUrl = 'https://checkout.wompi.co/l/test_VPOS_S0SAuto';
  static const String _cuentaBancolombia = '31954613201';
  static const String _llaveBreB = '71663024';
  static const String _whatsappSoporte = '573116479280';

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();

  String _selectedCategory = 'Grúa y Asistencia Vial';
  final List<String> _categories = [
    'Grúa y Asistencia Vial',
    'Taller Mecánico y Eléctrico',
    'Montallantas y Baterías',
    'Repuestos y Accesorios',
    'Lavadero y Estética',
    'Abogados de Tránsito',
    'Aseguradoras y SOAT',
  ];

  int _selectedPlanIndex = 0;
  final List> _plans = [
    {
      'nombre': 'Plan Mensual (30 días)',
      'dias': 30,
      'baseCop': 50000,
      'descripcion': 'Banner rotativo + Directorio de Aliados + Botón directo WhatsApp',
    },
    {
      'nombre': 'Plan Semestral (180 días — Ahorra $50.000)',
      'dias': 180,
      'baseCop': 250000,
      'descripcion': 'Prioridad en banner + Destacado en Aliados cercanos',
    },
    {
      'nombre': 'Plan Anual (365 días — Ahorra $100.000)',
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
  int get _totalLlaveDirectaCop => _baseAmount + _ivaAmount; // Sin comisión de pasarela

  @override
  void dispose() {
    _businessNameController.dispose();
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
          content: Text('Completa todos los datos obligatorios del comercio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final plan = _plans[_selectedPlanIndex];
    final now = DateTime.now();
    final dias = plan['dias'] as int;
    final expiresAt = now.add(Duration(days: dias));
    final alertRenewalAt = expiresAt.subtract(const Duration(days: 2));
    final cleanPhone = _phoneController.text.trim();
    final fullWhatsapp = cleanPhone.startsWith('57') ? '+$cleanPhone' : '+57$cleanPhone';

    final int montoFinal =
        metodoPago == 'wompi' ? _totalWompiCop : _totalLlaveDirectaCop;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('pautas_comerciales')
          .add({
        'nombreComercio': _businessNameController.text.trim(),
        'categoria': _selectedCategory,
        'mensajeBanner': _sloganController.text.trim(),
        'ciudad': _cityController.text.trim(),
        'direccion': _addressController.text.trim(),
        'nit': _nitController.text.trim(),
        'telefono': cleanPhone,
        'whatsapp': fullWhatsapp,
        'planNombre': plan['nombre'],
        'diasVigencia': dias,
        'valorBaseCop': _baseAmount,
        'ivaCop': _ivaAmount,
        'comisionPasarelaCop': metodoPago == 'wompi' ? _gatewayFee : 0,
        'totalPagadoCop': montoFinal,
        'metodoPago': metodoPago,
        'cuentaDestino': 'Bancolombia Ahorros $_cuentaBancolombia / Llave $_llaveBreB',
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
          '(Ref: ${docRef.id}) por valor de *${_formatCop(montoFinal)}* a la Llave $_llaveBreB / '
          'Bancolombia $_cuentaBancolombia. Adjunto comprobante:',
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
            '¡Pauta "${_businessNameController.text.trim()}" registrada! Visible dentro de las próximas 24 h (activa en banner y directorio).',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar pauta: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paute Aquí — Aliados S.O.S. Auto'),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Publicación garantizada en menos de 24 horas en el banner rotativo y directorio de aliados. Recibirás aviso 2 días antes del vencimiento.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría del servicio *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _businessNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre del comercio / empresa *',
                    hintText: 'Ej: Grúas y Talleres El Paisa 24/7',
                    prefixIcon: const Icon(Icons.store),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del negocio' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _sloganController,
                  maxLength: 75,
                  decoration: InputDecoration(
                    labelText: 'Texto corto para el banner rotativo *',
                    hintText: 'Ej: Desvare rápido en Medellín y área metropolitana. ¡Llámanos!',
                    prefixIcon: const Icon(Icons.short_text),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el texto del anuncio' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Ciudad *',
                          hintText: 'Ej: Medellín',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa la ciudad' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _nitController,
                        decoration: InputDecoration(
                          labelText: 'NIT / Cédula *',
                          hintText: 'Ej: 900123456-1',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa NIT o documento' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección o zona de cobertura *',
                    hintText: 'Ej: Av. 80 # 45-20, Laureles',
                    prefixIcon: const Icon(Icons.place),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa la dirección' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Celular / WhatsApp de atención 24/7 *',
                    hintText: 'Ej: 3116479280',
                    prefixIcon: const Icon(Icons.phone_in_talk),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 7) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Selecciona tu Plan Publicitario:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...List.generate(_plans.length, (index) {
                  final plan = _plans[index];
                  final selected = _selectedPlanIndex == index;
                  return Card(
                    elevation: selected ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedPlanIndex,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPlanIndex = val);
                      },
                      title: Text(
                        '${plan['nombre']} — ${_formatCop(plan['baseCop'] as int)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        plan['descripcion'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),

                // Tarjeta de Recaudo Oficial (Bancolombia + Llave Bre-B)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1565C0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canales Oficiales de Recaudo S.O.S. Auto:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '• Llave Inmediata (Bre-B): 71663024',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _copiarTexto(_llaveBreB, 'Llave Bre-B'),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '• Bancolombia Ahorros: 31954613201',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _copiarTexto(_cuentaBancolombia, 'Cuenta Bancolombia'),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Desglose de tarifa e impuestos
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _buildRowPrecio('Valor base pauta:', _formatCop(_baseAmount)),
                      _buildRowPrecio('IVA (19%):', _formatCop(_ivaAmount)),
                      _buildRowPrecio(
                        'Total transferencia Llave / Bancolombia:',
                        _formatCop(_totalLlaveDirectaCop),
                        isBold: true,
                      ),
                      const Divider(),
                      _buildRowPrecio('Comisión pasarela Wompi:', _formatCop(_gatewayFee)),
                      _buildRowPrecio(
                        'TOTAL CON WOMPI (PSE / Tarjetas / Nequi):',
                        _formatCop(_totalWompiCop),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botón 1: Pasarela Wompi (dispersión a Bancolombia 31954613201)
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _publishAndPay(metodoPago: 'wompi'),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'PROCESANDO PAUTA...' : 'PAGAR CON WOMPI Y PUBLICAR',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón 2: Pago directo por Llave 71663024 / Bancolombia 31954613201
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _publishAndPay(metodoPago: 'llave'),
                  icon: const Icon(Icons.key, color: Colors.white),
                  label: const Text(
                    'PAGAR CON LLAVE 71663024 (SIN COMISIÓN)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón 3: Activación directa (para tus pruebas inmediatas)
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : () => _publishAndPay(metodoPago: 'directa'),
                  icon: const Icon(Icons.bolt, color: Color(0xFF0D1B2A)),
                  label: const Text(
                    'ACTIVAR PAUTA DIRECTA (PRUEBA / ADMIN)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildRowPrecio(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 13.5 : 12.5,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 14 : 12.5,
              color: isBold ? const Color(0xFF1B5E20) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
