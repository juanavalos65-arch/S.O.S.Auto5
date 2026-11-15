import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PauteAquiScreen extends StatefulWidget {
  const PauteAquiScreen({super.key});

  @override
  State<PauteAquiScreen> createState() => _PauteAquiScreenState();
}

class _PauteAquiScreenState extends State<PauteAquiScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _empresaCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  // Planes oficiales en COP
  final List _planes = [
    {'id': '1m', 'titulo': '1 Mes', 'base': 50000.0, 'dias': 30},
    {'id': '6m', 'titulo': '6 Meses', 'base': 250000.0, 'dias': 180},
    {'id': '1y', 'titulo': '1 Año', 'base': 500000.0, 'dias': 365},
  ];

  // Configuración por país: impuesto local, moneda ISO y tasa de respaldo por 1 COP
  final Map<String, Map<String, dynamic>> _paisesConfig = {
    'Colombia': {
      'tasaImpuesto': 0.19,
      'nombreImpuesto': 'IVA (19%)',
      'moneda': 'COP',
      'simbolo': '\$',
      'tasaRespaldoDesdeCOP': 1.0,
    },
    'México': {
      'tasaImpuesto': 0.16,
      'nombreImpuesto': 'IVA (16%)',
      'moneda': 'MXN',
      'simbolo': 'MX\$',
      'tasaRespaldoDesdeCOP': 0.0046,
    },
    'Perú': {
      'tasaImpuesto': 0.18,
      'nombreImpuesto': 'IGV (18%)',
      'moneda': 'PEN',
      'simbolo': 'S/',
      'tasaRespaldoDesdeCOP': 0.00086,
    },
    'Chile': {
      'tasaImpuesto': 0.19,
      'nombreImpuesto': 'IVA (19%)',
      'moneda': 'CLP',
      'simbolo': 'CLP\$',
      'tasaRespaldoDesdeCOP': 0.22,
    },
    'Ecuador': {
      'tasaImpuesto': 0.15,
      'nombreImpuesto': 'IVA (15%)',
      'moneda': 'USD',
      'simbolo': 'US\$',
      'tasaRespaldoDesdeCOP': 0.00023,
    },
    'Argentina': {
      'tasaImpuesto': 0.21,
      'nombreImpuesto': 'IVA (21%)',
      'moneda': 'ARS',
      'simbolo': 'AR\$',
      'tasaRespaldoDesdeCOP': 0.24,
    },
    'Estados Unidos': {
      'tasaImpuesto': 0.07,
      'nombreImpuesto': 'Sales Tax (7%)',
      'moneda': 'USD',
      'simbolo': 'US\$',
      'tasaRespaldoDesdeCOP': 0.00023,
    },
    'Otro País (USD)': {
      'tasaImpuesto': 0.19,
      'nombreImpuesto': 'Impuesto Local (19%)',
      'moneda': 'USD',
      'simbolo': 'US\$',
      'tasaRespaldoDesdeCOP': 0.00023,
    },
  };

  String _planSeleccionadoId = '1m';
  String _paisSeleccionado = 'Colombia';

  // Estado de tasa de cambio en vivo
  Map<String, double> _tasasEnVivoDesdeCOP = {'COP': 1.0};
  bool _cargandoTasa = false;
  bool _tasaEnVivoDisponible = false;
  DateTime? _ultimaActualizacionTasa;

  // Estado post-pago
  bool _pagoAprobado = false;
  String _referenciaWompi = '';
  String _metodoPagoUsado = '';
  String? _archivoBannerSeleccionado;

  @override
  void initState() {
    super.initState();
    _actualizarTasasEnVivo();
  }

  Future<void> _actualizarTasasEnVivo() async {
    setState(() => _cargandoTasa = true);
    try {
      final uri = Uri.parse('https://open.er-api.com/v6/latest/COP');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null) {
          final Map<String, double> nuevasTasas = {'COP': 1.0};
          rates.forEach((key, value) {
            if (value is num) {
              nuevasTasas[key] = value.toDouble();
            }
          });
          if (mounted) {
            setState(() {
              _tasasEnVivoDesdeCOP = nuevasTasas;
              _tasaEnVivoDisponible = true;
              _ultimaActualizacionTasa = DateTime.now();
              _cargandoTasa = false;
            });
          }
          return;
        }
      }
    } catch (_) {
      // Usa tasa de respaldo si no hay conexión
    }
    if (mounted) {
      setState(() {
        _tasaEnVivoDisponible = false;
        _cargandoTasa = false;
      });
    }
  }

  Map<String, dynamic> get _planActual =>
      _planes.firstWhere((p) => p['id'] == _planSeleccionadoId);

  Map<String, dynamic> get _configPaisActual => _paisesConfig[_paisSeleccionado]!;

  double get _valorBaseCOP => _planActual['base'] as double;

  double get _tasaImpuestoPais => _configPaisActual['tasaImpuesto'] as double;

  String get _nombreImpuestoPais => _configPaisActual['nombreImpuesto'] as String;

  String get _monedaDestino => _configPaisActual['moneda'] as String;

  String get _simboloDestino => _configPaisActual['simbolo'] as String;

  double get _tasaConversionActual {
    if (_monedaDestino == 'COP') return 1.0;
    return _tasasEnVivoDesdeCOP[_monedaDestino] ??
        (_configPaisActual['tasaRespaldoDesdeCOP'] as double);
  }

  double get _valorImpuestoCOP => _valorBaseCOP * _tasaImpuestoPais;

  // Comisión estándar Wompi Colombia: 2.65% + $700 COP + IVA 19% sobre comisión
  double get _comisionWompiCOP {
    final subtotal = _valorBaseCOP + _valorImpuestoCOP;
    final baseComision = (subtotal * 0.0265) + 700.0;
    return baseComision * 1.19;
  }

  double get _totalPagarCOP => _valorBaseCOP + _valorImpuestoCOP + _comisionWompiCOP;

  String _formatearCOP(double valor) {
    final entero = valor.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      final posDesdeDerecha = entero.length - i;
      if (i > 0 && posDesdeDerecha % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(entero[i]);
    }
    return '\$${buffer.toString()} COP';
  }

  String _formatearMonedaLocal(double valorCOP) {
    if (_monedaDestino == 'COP') {
      return _formatearCOP(valorCOP);
    }
    final convertido = valorCOP * _tasaConversionActual;
    if (_monedaDestino == 'CLP') {
      return '$_simboloDestino${convertido.round()} $_monedaDestino';
    }
    return '$_simboloDestino${convertido.toStringAsFixed(2)} $_monedaDestino';
  }

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _ciudadCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirWompiSandbox() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_monedaDestino != 'COP') {
      await _actualizarTasasEnVivo();
    }

    if (!mounted) return;

    final refGenerada =
        'SOS-TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${Random().nextInt(900) + 100}';

    final Map<String, dynamic>? resultado =
        await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WompiSandboxModal(
        referencia: refGenerada,
        empresa: _empresaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefonoInicial: _telefonoCtrl.text.trim(),
        planTitulo: _planActual['titulo'] as String,
        totalCOP: _totalPagarCOP,
        totalCOPFormateado: _formatearCOP(_totalPagarCOP),
        totalLocalFormateado: _formatearMonedaLocal(_totalPagarCOP),
        esMonedaExtranjera: _monedaDestino != 'COP',
        tasaInfo: _monedaDestino == 'COP'
            ? 'Moneda base COP'
            : '1 $_monedaDestino ≈ ${(1 / _tasaConversionActual).round()} COP (${_tasaEnVivoDisponible ? "Tasa real en vivo" : "Tasa referencial"})',
      ),
    );

    if (resultado != null && resultado['aprobado'] == true && mounted) {
      setState(() {
        _pagoAprobado = true;
        _referenciaWompi = refGenerada;
        _metodoPagoUsado = resultado['metodo'] as String? ?? 'Wompi Sandbox';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.campaign, size: 24),
            SizedBox(width: 8),
            Text(
              'Paute aquí',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _pagoAprobado ? _buildConfirmacionPostPago() : _buildFormulario(),
      ),
    );
  }

  Widget _buildFormulario() {
    final bool esExtranjero = _monedaDestino != 'COP';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner informativo superior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECE9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFB7CDC6)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anuncia tu taller, grúa, aseguradora o comercio en el banner superior y directorio de S.O.S. Auto con pago seguro Wompi.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1D2B27),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.science, size: 16, color: Color(0xFF0B6E4F)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Wompi MODO PRUEBA: Nequi, Daviplata, Banco, PSE y Código QR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B6E4F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nombre empresa
            TextFormField(
              controller: _empresaCtrl,
              decoration: _inputDecoration(
                'Nombre de la empresa o taller *',
                Icons.store_mall_directory_outlined,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre de tu empresa' : null,
            ),
            const SizedBox(height: 12),

            // País
            DropdownButtonFormField<String>(
              value: _paisSeleccionado,
              decoration: _inputDecoration('País *', Icons.public),
              items: _paisesConfig.keys.map((pais) {
                final moneda = _paisesConfig[pais]!['moneda'];
                return DropdownMenuItem(
                  value: pais,
                  child: Text('$pais ($moneda)'),
                );
              }).toList(),
              onChanged: (nuevoPais) {
                if (nuevoPais != null) {
                  setState(() => _paisSeleccionado = nuevoPais);
                  if (_paisesConfig[nuevoPais]!['moneda'] != 'COP' && !_tasaEnVivoDisponible) {
                    _actualizarTasasEnVivo();
                  }
                }
              },
            ),
            const SizedBox(height: 12),

            // Ciudad
            TextFormField(
              controller: _ciudadCtrl,
              decoration: _inputDecoration('Ciudad *', Icons.location_city),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa la ciudad de operación' : null,
            ),
            const SizedBox(height: 12),

            // Teléfono / WhatsApp
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                'Teléfono / WhatsApp de contacto *',
                Icons.phone_android,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 7) ? 'Ingresa un número válido' : null,
            ),
            const SizedBox(height: 12),

            // Correo electrónico
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                'Correo electrónico *',
                Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
                if (!v.contains('@') || !v.contains('.')) return 'Correo electrónico no válido';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Observaciones
            TextFormField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                'Observaciones adicionales (servicios, horarios)',
                Icons.notes,
              ),
            ),
            const SizedBox(height: 20),

            // Selector de Plan
            const Text(
              'Selecciona tu plan publicitario:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2B27),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _planes.map((plan) {
                final bool seleccionado = plan['id'] == _planSeleccionadoId;
                final double basePlan = plan['base'] as double;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _planSeleccionadoId = plan['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                      decoration: BoxDecoration(
                        color: seleccionado ? const Color(0xFF0B6E4F) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado ? const Color(0xFF0B6E4F) : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            plan['titulo'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: seleccionado ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearCOP(basePlan),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: seleccionado ? Colors.amberAccent : const Color(0xFF0B6E4F),
                            ),
                          ),
                          if (esExtranjero) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatearMonedaLocal(basePlan),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: seleccionado ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Liquidación automática de tarifas, impuestos, Wompi y conversión real
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Resumen de Liquidación',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (esExtranjero)
                        InkWell(
                          onTap: _cargandoTasa ? null : _actualizarTasasEnVivo,
                          child: Row(
                            children: [
                              Icon(
                                Icons.currency_exchange,
                                size: 15,
                                color: _tasaEnVivoDisponible ? const Color(0xFF0B6E4F) : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _cargandoTasa
                                    ? 'Actualizando...'
                                    : (_tasaEnVivoDisponible ? 'TRM en vivo' : 'Actualizar TRM'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B6E4F),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  _filaCosto(
                    'Tarifa base (${_planActual['titulo']}):',
                    _formatearCOP(_valorBaseCOP),
                    subValor: esExtranjero ? _formatearMonedaLocal(_valorBaseCOP) : null,
                  ),
                  _filaCosto(
                    '$_nombreImpuestoPais ($_paisSeleccionado):',
                    _formatearCOP(_valorImpuestoCOP),
                    subValor: esExtranjero ? _formatearMonedaLocal(_valorImpuestoCOP) : null,
                  ),
                  _filaCosto(
                    'Comisión pasarela Wompi:',
                    _formatearCOP(_comisionWompiCOP),
                    subValor: esExtranjero ? _formatearMonedaLocal(_comisionWompiCOP) : null,
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL A PAGAR:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            esExtranjero
                                ? _formatearMonedaLocal(_totalPagarCOP)
                                : _formatearCOP(_totalPagarCOP),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0B6E4F),
                            ),
                          ),
                          if (esExtranjero)
                            Text(
                              'Equivalente: ${_formatearCOP(_totalPagarCOP)}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (esExtranjero) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 15, color: Color(0xFF0B6E4F)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tasa aplicada al momento: 1 $_monedaDestino ≈ ${(1 / _tasaConversionActual).round()} COP'
                              '${_ultimaActualizacionTasa != null ? " (${_ultimaActualizacionTasa!.hour.toString().padLeft(2, '0')}:${_ultimaActualizacionTasa!.minute.toString().padLeft(2, '0')})" : ""}',
                              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón Continuar a Wompi Sandbox
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _cargandoTasa ? null : _abrirWompiSandbox,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6E4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'CONTINUAR A PAUTA WOMPI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmacionPostPago() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de éxito y activación automática
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0B6E4F), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, color: Color(0xFF0B6E4F), size: 54),
                const SizedBox(height: 10),
                const Text(
                  '¡PAGO APROBADO Y PAUTA ACTIVADA!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B6E4F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Referencia Wompi (Prueba): $_referenciaWompi\n'
                  'Medio de pago: $_metodoPagoUsado\n'
                  'Empresa: ${_empresaCtrl.text.trim()} (${_ciudadCtrl.text.trim()}, $_paisSeleccionado)\n'
                  'Valor pagado: ${_formatearMonedaLocal(_totalPagarCOP)}'
                  '${_monedaDestino != "COP" ? " (${_formatearCOP(_totalPagarCOP)})" : ""}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront, color: Color(0xFF0B6E4F)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu negocio ya quedó registrado y activo automáticamente en el Directorio de Anunciantes / Colaboradores de S.O.S. Auto.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Aviso de tiempo máximo de publicación (24 horas)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_filled, color: Colors.amber, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tiempo de publicación: Tu pauta estará visible en el banner superior en un plazo máximo de 24 horas después de haber realizado el pago.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Indicaciones técnicas del formato de la pauta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.design_services, color: Color(0xFF0B6E4F)),
                    SizedBox(width: 8),
                    Text(
                      'Indicaciones del Formato de tu Pauta',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _itemIndicacion(
                    'Dimensiones recomendadas:', '1200 x 300 píxeles (proporción horizontal 4:1).'),
                _itemIndicacion(
                    'Formatos aceptados:', 'PNG o JPG de alta resolución (peso máximo 2 MB).'),
                _itemIndicacion('Contenido visual:',
                    'Logo de tu empresa, servicio principal (ej. Grúa 24h, Taller, Baterías) y teléfono/WhatsApp legible.'),
                _itemIndicacion('Restricciones:',
                    'No incluir texto excesivo ni imágenes borrosas; los márgenes de seguridad son de 20 px.'),
                const SizedBox(height: 14),

                // Botón para adjuntar pieza gráfica
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _archivoBannerSeleccionado =
                          'banner_${_empresaCtrl.text.trim().replaceAll(' ', '_').toLowerCase()}.png';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Arte de pauta cargado y vinculado a tu campaña activa.'),
                        backgroundColor: Color(0xFF0B6E4F),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _archivoBannerSeleccionado == null
                        ? 'ADJUNTAR DISEÑO DEL BANNER (OPCIONAL AHORA)'
                        : 'ARCHIVO CARGADO: $_archivoBannerSeleccionado',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B6E4F),
                    side: const BorderSide(color: Color(0xFF0B6E4F)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E4F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'FINALIZAR Y VOLVER AL MAPA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0B6E4F)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _filaCosto(String etiqueta, String valorCOP, {String? subValor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 13.5))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subValor ?? valorCOP,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              if (subValor != null)
                Text(
                  valorCOP,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemIndicacion(String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(text: '$titulo ', style: const TextStyle(fontWeight: FontWeight.bold)),
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

/// Modal interactivo Wompi Sandbox con Nequi, Daviplata, Banco, PSE y Generador QR
class _WompiSandboxModal extends StatefulWidget {
  final String referencia;
  final String empresa;
  final String email;
  final String telefonoInicial;
  final String planTitulo;
  final double totalCOP;
  final String totalCOPFormateado;
  final String totalLocalFormateado;
  final bool esMonedaExtranjera;
  final String tasaInfo;

  const _WompiSandboxModal({
    required this.referencia,
    required this.empresa,
    required this.email,
    required this.telefonoInicial,
    required this.planTitulo,
    required this.totalCOP,
    required this.totalCOPFormateado,
    required this.totalLocalFormateado,
    required this.esMonedaExtranjera,
    required this.tasaInfo,
  });

  @override
  State<_WompiSandboxModal> createState() => _WompiSandboxModalState();
}

class _WompiSandboxModalState extends State<_WompiSandboxModal> {
  // Opciones: 'nequi', 'daviplata', 'banco', 'pse', 'qr'
  String _modalidad = 'nequi';
  String _bancoSeleccionado = 'Bancolombia';
  String _tipoPersonaPSE = 'Persona Natural';
  late final TextEditingController _celularBilleteraCtrl;
  bool _procesando = false;

  final List<String> _bancosDisponibles = [
    'Bancolombia',
    'Davivienda',
    'Banco de Bogotá',
    'BBVA Colombia',
    'Banco de Occidente',
    'Banco AV Villas',
    'Scotiabank Colpatria',
    'Banco Popular',
    'Nequi (PSE)',
    'Daviplata (PSE)',
  ];

  @override
  void initState() {
    super.initState();
    _celularBilleteraCtrl = TextEditingController(text: widget.telefonoInicial);
  }

  @override
  void dispose() {
    _celularBilleteraCtrl.dispose();
    super.dispose();
  }

  String get _descripcionMetodoFinal {
    switch (_modalidad) {
      case 'nequi':
        return 'Nequi (${_celularBilleteraCtrl.text.trim()})';
      case 'daviplata':
        return 'Daviplata (${_celularBilleteraCtrl.text.trim()})';
      case 'banco':
        return 'Transferencia Bancaria ($_bancoSeleccionado)';
      case 'pse':
        return 'PSE - $_bancoSeleccionado ($_tipoPersonaPSE)';
      case 'qr':
        return 'Código QR Interoperable Wompi / Bre-B';
      default:
        return 'Wompi Sandbox';
    }
  }

  String get _payloadQR {
    return 'WOMPI-SOSAUTO|REF:${widget.referencia}|MONTO:${widget.totalCOP.round()}COP|CTA:31954613201|LLAVE:71663024|EMP:${widget.empresa}';
  }

  Future<void> _simularPagoAprobado() async {
    if ((_modalidad == 'nequi' || _modalidad == 'daviplata') &&
        _celularBilleteraCtrl.text.trim().length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un número celular válido para la billetera.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop({
        'aprobado': true,
        'metodo': _descripcionMetodoFinal,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera Wompi Sandbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFF2C2A29)),
                    SizedBox(width: 8),
                    Text(
                      'Wompi Checkout',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade700),
                  ),
                  child: Text(
                    'MODO PRUEBA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Resumen de comercio y valor
            Text('Comercio: S.O.S. Auto (${widget.planTitulo})',
                style: const TextStyle(fontSize: 13)),
            Text('Anunciante: ${widget.empresa}', style: const TextStyle(fontSize: 13)),
            Text('Ref: ${widget.referencia}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        widget.totalLocalFormateado,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B6E4F),
                        ),
                      ),
                    ],
                  ),
                  if (widget.esMonedaExtranjera) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Liquidación Wompi: ${widget.totalCOPFormateado} • ${widget.tasaInfo}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Selector de modalidades de pago
            const Text(
              'Elige tu modalidad de pago:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chipModalidad('nequi', 'Nequi', Icons.smartphone),
                _chipModalidad('daviplata', 'Daviplata', Icons.phone_iphone),
                _chipModalidad('banco', 'Banco', Icons.account_balance),
                _chipModalidad('pse', 'PSE', Icons.assured_workload),
                _chipModalidad('qr', 'Código QR', Icons.qr_code_2),
              ],
            ),
            const SizedBox(height: 14),

            // Panel dinámico según la modalidad seleccionada
            _buildDetalleModalidad(),
            const SizedBox(height: 16),

            // Botón de confirmación / simulación
            _procesando
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Color(0xFF0B6E4F)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _simularPagoAprobado,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6E4F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(_modalidad == 'qr' ? Icons.qr_code_scanner : Icons.check_circle_outline),
                    label: Text(
                      _modalidad == 'qr'
                          ? 'CONFIRMAR QR ESCANEADO (SANDBOX)'
                          : 'PAGAR CON ${_modalidad.toUpperCase()} (PRUEBA)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _procesando ? null : () => Navigator.of(context).pop(null),
              child: const Text('Cancelar transacción', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipModalidad(String id, String titulo, IconData icono) {
    final bool activo = _modalidad == id;
    return ChoiceChip(
      selected: activo,
      onSelected: (_) => setState(() => _modalidad = id),
      selectedColor: const Color(0xFF0B6E4F),
      backgroundColor: const Color(0xFFF3F6F5),
      labelStyle: TextStyle(
        color: activo ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 12.5,
      ),
      avatar: Icon(
        icono,
        size: 17,
        color: activo ? Colors.white : const Color(0xFF0B6E4F),
      ),
      label: Text(titulo),
    );
  }

  Widget _buildDetalleModalidad() {
    switch (_modalidad) {
      case 'nequi':
      case 'daviplata':
        final nombreBilletera = _modalidad == 'nequi' ? 'Nequi' : 'Daviplata';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pago directo con $nombreBilletera',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _celularBilleteraCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Número celular asociado a $nombreBilletera',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'En modo prueba se enviará notificación push simulada a tu app $nombreBilletera.',
                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
            ],
          ),
        );

      case 'banco':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transferencia Bancaria / Botón Banco',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bancoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Selecciona tu banco',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _bancosDisponibles
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _bancoSeleccionado = v);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuenta destino recaudadora: Bancolombia Ahorros 31954613201 • Llave Bre-B: 71663024',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF0B6E4F), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

      case 'pse':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Débito Bancario PSE (Pagos Seguros en Línea)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoPersonaPSE,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cliente',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Persona Natural', child: Text('Persona Natural')),
                  DropdownMenuItem(value: 'Persona Jurídica', child: Text('Persona Jurídica (Empresa)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoPersonaPSE = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bancoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Banco PSE',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _bancosDisponibles
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _bancoSeleccionado = v);
                },
              ),
            ],
          ),
        );

      case 'qr':
      default:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0B6E4F)),
          ),
          child: Column(
            children: [
              const Text(
                'Escanea este Código QR desde Nequi, Daviplata o tu App Bancaria',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: CustomPaint(
                  size: const Size(165, 165),
                  painter: _QrCodeMatrixPainter(data: _payloadQR),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ref: ${widget.referencia} • ${widget.totalCOPFormateado}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B6E4F),
                ),
              ),
              const Text(
                'QR Interoperable Wompi / Bancolombia / Bre-B (Llave 71663024)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        );
    }
  }
}

/// Generador visual determinístico de matriz QR (25x25 con patrones de posición estándar)
class _QrCodeMatrixPainter extends CustomPainter {
  final String data;

  _QrCodeMatrixPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const int gridSize = 25;
    final double cellSize = size.width / gridSize;
    final Paint darkPaint = Paint()..color = const Color(0xFF111815);
    final Paint lightPaint = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    final List<List<bool>> matrix = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );
    final List<List<bool>> reserved = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );

    void placeFinder(int startRow, int startCol) {
      for (int r = -1; r <= 7; r++) {
        for (int c = -1; c <= 7; c++) {
          final int rr = startRow + r;
          final int cc = startCol + c;
          if (rr >= 0 && rr < gridSize && cc >= 0 && cc < gridSize) {
            reserved[rr][cc] = true;
            final bool isBorder = r == 0 || r == 6 || c == 0 || c == 6;
            final bool isCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
            final bool isQuiet = r == -1 || r == 7 || c == -1 || c == 7;
            matrix[rr][cc] = !isQuiet && (isBorder || isCenter);
          }
        }
      }
    }

    // Tres esquinas de localización QR
    placeFinder(0, 0);
    placeFinder(0, gridSize - 7);
    placeFinder(gridSize - 7, 0);

    // Patrones de sincronización (timing)
    for (int i = 8; i < gridSize - 8; i++) {
      reserved[6][i] = true;
      matrix[6][i] = i % 2 == 0;
      reserved[i][6] = true;
      matrix[i][6] = i % 2 == 0;
    }

    // Relleno determinístico basado en los bytes de la transacción
    int hash = 2166136261;
    for (final codeUnit in data.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    final Random rng = Random(hash);

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (!reserved[r][c]) {
          matrix[r][c] = rng.nextBool();
        }
      }
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodeMatrixPainter oldDelegate) =>
      oldDelegate.data != data;
}
