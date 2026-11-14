import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdPlan {
  final String id;
  final String name;
  final int days;
  final double basePrice;

  const AdPlan({
    required this.id,
    required this.name,
    required this.days,
    required this.basePrice,
  });
}

class PauteAquiScreen extends StatefulWidget {
  const PauteAquiScreen({super.key});

  @override
  State<PauteAquiScreen> createState() => _PauteAquiScreenState();
}

class _PauteAquiScreenState extends State<PauteAquiScreen> {
  static const String _wompiUrl = 'https://checkout.wompi.co/l/VPOS_3Odu3K';
  static const String _bancolombiaAccount = '31954613201';
  static const String _bancolombiaKey = '71663024';
  static const String _supportEmail = 'soporte.applay65@gmail.com';

  final List<AdPlan> _plans = const [
    AdPlan(id: '1m', name: 'Plan 1 Mes', days: 30, basePrice: 50000),
    AdPlan(id: '6m', name: 'Plan 6 Meses', days: 180, basePrice: 250000),
    AdPlan(id: '1y', name: 'Plan 1 Año', days: 365, basePrice: 500000),
  ];

  late AdPlan _selectedPlan;
  bool _showUploadForm = false;
  bool _includeIva = true;

  // Controladores del formulario de subida de pauta
  final _uploadFormKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _bannerTextController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _wompiRefController = TextEditingController();
  final TextEditingController _bannerImageUrlController = TextEditingController();

  String _selectedCategory = 'Taller Mecánico';
  final List<String> _categories = [
    'Taller Mecánico',
    'Servicio de Grúa',
    'Almacén de Repuestos',
    'Montallantas / Baterías',
    'Lavadero / Detailing',
    'Aseguradora / CDA',
    'Otro Comercio Automotriz',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans[0];
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _bannerTextController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _wompiRefController.dispose();
    _bannerImageUrlController.dispose();
    super.dispose();
  }

  // Cálculo de impuestos (IVA 19%) y comisión Wompi (2.65% + $700 + IVA comisión)
  double get _taxAmount => _includeIva ? _selectedPlan.basePrice * 0.19 : 0.0;

  double get _subtotalWithTax => _selectedPlan.basePrice + _taxAmount;

  double get _wompiCommission {
    final baseCommission = (_subtotalWithTax * 0.0265) + 700.0;
    final commissionIva = baseCommission * 0.19;
    return baseCommission + commissionIva;
  }

  double get _totalToPay => _subtotalWithTax + _wompiCommission;

  String _formatCop(double value) {
    final intVal = value.round();
    final str = intVal.toString();
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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _handleWompiPayment() async {
    await Clipboard.setData(const ClipboardData(text: _wompiUrl));
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Pasarela de Pago Wompi')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El enlace oficial de Wompi ha sido copiado al portapapeles para que lo abras en tu navegador:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const SelectableText(
                  _wompiUrl,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Valor total a ingresar en Wompi: ${_formatCop(_totalToPay)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Wompi dispersa directamente a Bancolombia Ahorros N.° $_bancolombiaAccount (Llave $_bancolombiaKey).\n'
                '• Guarda el número de aprobación del pago.\n'
                '• Luego pulsa el botón "2. SUBIR FORMATO DE PAUTA" en esta pantalla.\n'
                '• Tu anuncio aparecerá activo a más tardar 24 horas después de verificado el pago.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _showUploadForm = true;
              });
            },
            child: const Text('Ya pagué, subir pauta ahora'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _submitAdUpload() {
    if (!_uploadFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos obligatorios de tu pauta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final now = DateTime.now();
    // Inicio máximo en 24h tras verificación de pago
    final startDate = now.add(const Duration(hours: 24));
    final expirationDate = startDate.add(Duration(days: _selectedPlan.days));
    final reminderDate = expirationDate.subtract(const Duration(days: 2));

    final Map<String, dynamic> adSubmission = {
      'planId': _selectedPlan.id,
      'planName': _selectedPlan.name,
      'basePrice': _selectedPlan.basePrice,
      'taxAmount': _taxAmount.round(),
      'wompiCommission': _wompiCommission.round(),
      'totalPaid': _totalToPay.round(),
      'wompiReference': _wompiRefController.text.trim(),
      'businessName': _businessNameController.text.trim(),
      'category': _selectedCategory,
      'bannerText': _bannerTextController.text.trim(),
      'bannerImageUrl': _bannerImageUrlController.text.trim(),
      'advertiserWhatsapp': _whatsappController.text.trim(),
      'advertiserEmail': _emailController.text.trim(),
      'activationDeadline': startDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'reminderDate2DaysBefore': reminderDate.toIso8601String(),
      'adminNotificationEmail': _supportEmail,
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Pauta Registrada con Éxito')),
          ],
        ),
        content: Text(
          'Hemos recibido los datos y el comprobante (${adSubmission['wompiReference']}) de "${adSubmission['businessName']}".\n\n'
          '• Activación: A más tardar en 24 horas (${_formatDate(startDate)}).\n'
          '• Vencimiento del plan: ${_formatDate(expirationDate)}.\n'
          '• Alerta automática: Te enviaremos un recordatorio a tu WhatsApp (${adSubmission['advertiserWhatsapp']}) y correo (${adSubmission['advertiserEmail']}) 2 días antes del vencimiento (${_formatDate(reminderDate)}).',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, adSubmission);
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paute Aquí - S.O.S. Auto'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner informativo superior
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.campaign, color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Anuncia tu taller, grúa o negocio automotriz en el banner dinámico de S.O.S. Auto. Tu pauta aparecerá activa a más tardar 24 horas después de haberla pagado.',
                        style: TextStyle(fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Paso 1: Elige tu Plan Publicitario',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),

              // Selector de planes
              ..._plans.map((plan) {
                final isSelected = _selectedPlan.id == plan.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<AdPlan>(
                    value: plan,
                    groupValue: _selectedPlan,
                    title: Text(
                      plan.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Duración: ${plan.days} días en banner rotativo'),
                    secondary: Text(
                      _formatCop(plan.basePrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPlan = value;
                        });
                      }
                    },
                  ),
                );
              }),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Incluir IVA Colombia (19%)',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Aplica para facturación nacional en Colombia',
                  style: TextStyle(fontSize: 12),
                ),
                value: _includeIva,
                onChanged: (val) {
                  setState(() {
                    _includeIva = val;
                  });
                },
              ),

              // Desglose de tarifa + impuestos + comisión
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Valor base (${_selectedPlan.name}):',
                      _formatCop(_selectedPlan.basePrice),
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Impuestos (IVA 19%):',
                      _formatCop(_taxAmount),
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Comisión pasarela Wompi:',
                      _formatCop(_wompiCommission),
                    ),
                    const Divider(height: 18),
                    _buildSummaryRow(
                      'TOTAL A PAGAR EN WOMPI:',
                      _formatCop(_totalToPay),
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Instrucciones de pago y cuenta destino
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instrucciones de Pago y Formato:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '1. Pulsa "1. PAGAR EN PASARELA WOMPI" e ingresa el valor total indicado arriba.\n'
                      '2. Wompi transfiere directamente a Bancolombia Ahorros N.° $_bancolombiaAccount o Llave $_bancolombiaKey.\n'
                      '3. Al terminar el pago, copia el número de aprobación y pulsa "2. SUBIR FORMATO DE PAUTA".\n'
                      '4. Formato recomendado del arte: Imagen horizontal 1200 x 300 px (JPG/PNG) con logo, servicio y teléfono.\n'
                      '5. Tu pauta se activa a más tardar 24 horas después de confirmado el pago.',
                      style: TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // BOTÓN 1: IR A PAGAR EN WOMPI
              ElevatedButton.icon(
                onPressed: _handleWompiPayment,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  '1. PAGAR EN PASARELA WOMPI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // BOTÓN 2: SUBIR FORMATO DE PAUTA
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showUploadForm = !_showUploadForm;
                  });
                },
                icon: Icon(
                  _showUploadForm ? Icons.expand_less : Icons.upload_file,
                ),
                label: const Text(
                  '2. SUBIR FORMATO DE PAUTA (POST-PAGO)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // ==========================================
              // FORMULARIO DESPLEGABLE PARA SUBIR PAUTA
              // ==========================================
              if (_showUploadForm) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _uploadFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Datos y Formato de tu Pauta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Se publicará en el banner máximo 24 horas después de validar tu pago. Te avisaremos por WhatsApp y correo 2 días antes de vencer.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _wompiRefController,
                            decoration: const InputDecoration(
                              labelText: 'N.° de Referencia / Aprobación Wompi *',
                              hintText: 'Ej: 123456-ABC',
                              prefixIcon: Icon(Icons.receipt_long),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa la referencia del pago Wompi'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Comercio / Empresa *',
                              prefixIcon: Icon(Icons.store),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa el nombre del negocio'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Categoría del Servicio *',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bannerTextController,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'Texto corto para el banner *',
                              hintText: 'Ej: Grúas 24/7 en toda la ciudad - Tel 300...',
                              prefixIcon: Icon(Icons.short_text),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Escribe el mensaje corto del anuncio'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bannerImageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Enlace de imagen del banner (1200x300 px)',
                              hintText: 'URL de Drive/imagen o deja vacío si lo envías por WhatsApp',
                              prefixIcon: Icon(Icons.image),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp para alerta de vencimiento *',
                              hintText: 'Ej: 3116479280',
                              prefixIcon: Icon(Icons.phone_android),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa el WhatsApp del anunciante';
                              }
                              if (v.trim().length < 10) {
                                return 'Debe tener 10 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico para alerta de vencimiento *',
                              hintText: 'ejemplo@correo.com',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa el correo del anunciante';
                              }
                              if (!v.contains('@')) {
                                return 'Correo no válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _submitAdUpload,
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'ENVIAR PAUTA Y ACTIVAR ALERTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
