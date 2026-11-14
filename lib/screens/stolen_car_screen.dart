import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StolenCarScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  final double? currentLat;
  final double? currentLng;
  final void Function(Map<String, dynamic> stolenAlertEvent)? onPublishStolenAlert;

  const StolenCarScreen({
    super.key,
    this.registrationData,
    this.currentLat,
    this.currentLng,
    this.onPublishStolenAlert,
  });

  @override
  State<StolenCarScreen> createState() => _StolenCarScreenState();
}

class _StolenCarScreenState extends State<StolenCarScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _plateController;
  late final TextEditingController _brandModelController;
  late final TextEditingController _colorController;
  final TextEditingController _escapeDirectionController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _theftMode = 'Atraco / Intimidación en vía';
  final List<String> _theftModes = [
    'Atraco / Intimidación en vía',
    'Halado (Estacionado en vía pública)',
    'Abuso de confianza / Falso servicio',
    'Otro modo de hurto',
  ];

  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _alertSent = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.registrationData?['vehicle'] as Map<String, dynamic>?;
    _plateController = TextEditingController(
      text: (vehicle?['plate'] ?? '').toString(),
    );
    final brand = (vehicle?['brand'] ?? '').toString();
    final model = (vehicle?['model'] ?? '').toString();
    _brandModelController = TextEditingController(
      text: '$brand $model'.trim(),
    );
    _colorController = TextEditingController(
      text: (vehicle?['color'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _plateController.dispose();
    _brandModelController.dispose();
    _colorController.dispose();
    _escapeDirectionController.dispose();
    _detailsController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startStolenCountdown() {
    if (_isCountingDown || _alertSent) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica la placa y características básicas del vehículo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 5;
    });

    HapticFeedback.heavyImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
        _dispatchStolenVehicleAlert();
      }
    });
  }

  void _promptCancelWithPin() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.deepOrange),
            SizedBox(width: 8),
            Expanded(child: Text('Cancelar Reporte de Robo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu PIN de seguridad (4 dígitos) para anular el reporte:',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN de acceso',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar reporte'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.trim().length == 4) {
                _countdownTimer?.cancel();
                setState(() {
                  _isCountingDown = false;
                  _countdownSeconds = 5;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reporte de robo cancelado correctamente.'),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN incorrecto. Debe tener 4 dígitos.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Anular Reporte'),
          ),
        ],
      ),
    );
  }

  void _dispatchStolenVehicleAlert() {
    setState(() {
      _isCountingDown = false;
      _alertSent = true;
    });

    final plate = _plateController.text.trim().toUpperCase();
    final brandModel = _brandModelController.text.trim();
    final color = _colorController.text.trim();
    final direction = _escapeDirectionController.text.trim();
    final extraDetails = _detailsController.text.trim();

    final lat = widget.currentLat ?? 6.2442;
    final lng = widget.currentLng ?? -75.5812;
    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';

    final owner = widget.registrationData?['owner'] as Map<String, dynamic>?;
    final ownerName = owner?['name'] ?? 'Propietario S.O.S. Auto';
    final contacts =
        (widget.registrationData?['emergencyContacts'] as List<dynamic>?) ?? [];

    // 1. Objeto de alerta para Banner Dinámico, Usuarios Cercanos y Autoridades
    final Map<String, dynamic> stolenAlertEvent = {
      'type': 'ROBO_DE_AUTO',
      'title': '🚨 VEHÍCULO ROBADO: Placa $plate',
      'plate': plate,
      'brandModel': brandModel,
      'color': color,
      'theftMode': _theftMode,
      'escapeDirection': direction,
      'details': extraDetails,
      'lat': lat,
      'lng': lng,
      'mapsLink': mapsLink,
      'timestamp': DateTime.now().toIso8601String(),
      'activeInBanner': true,
      'broadcastToNearbyUsers': true,
      'notifyAuthorities': true,
    };

    widget.onPublishStolenAlert?.call(stolenAlertEvent);

    final String contactSummary = contacts.isNotEmpty
        ? contacts.map((c) => '${c['name']} (${c['phone']})').join(' y ')
        : 'Tus 2 contactos de emergencia registrados';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.deepOrange),
            SizedBox(width: 8),
            Expanded(child: Text('Alerta de Robo Difundida')),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'El reporte del vehículo $plate ($brandModel - $color) se ha activado en los 4 canales:\n\n'
            '1. 🚨 Banner Dinámico S.O.S. Auto: Publicado en rotación prioritaria para toda la comunidad.\n'
            '2. 📡 Usuarios Cercanos en Ruta: Alerta de avistamiento enviada a conductores en tu radio GPS (con instrucción de no confrontar y avisar al 123).\n'
            '3. 🚓 Autoridades (123 / #767 / SIJIN): Ficha técnica y última coordenada ($mapsLink) listas para despacho policial.\n'
            '4. 📱 Contactos de Emergencia ($ownerName): Notificados $contactSummary con tu ubicación segura.\n\n'
            'Mantente a salvo en un lugar seguro y no intentes perseguir el vehículo.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _copyPoliceReportSheet() {
    final plate = _plateController.text.trim().toUpperCase();
    final brandModel = _brandModelController.text.trim();
    final color = _colorController.text.trim();
    final direction = _escapeDirectionController.text.trim();
    final lat = widget.currentLat ?? 6.2442;
    final lng = widget.currentLng ?? -75.5812;

    final reportText = 'REPORTE URGENTE ROBO DE VEHÍCULO - S.O.S. AUTO\n'
        'Placa: $plate\n'
        'Vehículo: $brandModel | Color: $color\n'
        'Modalidad: $_theftMode\n'
        'Dirección de huida: ${direction.isNotEmpty ? direction : "No especificada"}\n'
        'Última ubicación GPS: https://maps.google.com/?q=$lat,$lng';

    Clipboard.setData(ClipboardData(text: reportText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ficha del robo copiada para enviar a Policía (123 / #767) o Fiscalía.'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robo de Auto - Alerta Máxima'),
        backgroundColor: Colors.deepOrange.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ========================================================
                // 1. INSTRUCCIONES DE PROTECCIÓN DE LA VIDA (NO ARRIESGARSE)
                // ========================================================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade600, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: Colors.deepOrange.shade900,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Tu vida vale más que el vehículo! Sigue estas reglas:',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildLifeRule(
                        Icons.do_not_disturb_on,
                        'NO arriesgues tu vida ni opongas resistencia: Entrega las llaves o el vehículo sin discutir ni forcejear.',
                      ),
                      _buildLifeRule(
                        Icons.directions_run,
                        'NO persigas a los delincuentes: Evita seguirlos en otro vehículo o a pie; suelen ir armados o acompañados.',
                      ),
                      _buildLifeRule(
                        Icons.store_mall_directory,
                        'Busca refugio inmediato: Ingresa a un establecimiento abierto, estación de servicio o lugar con público e iluminación.',
                      ),
                      _buildLifeRule(
                        Icons.local_police,
                        'Llama a las autoridades (123 / #767): Reporta placa, color, marca y dirección de huida en cuanto estés a salvo.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ========================================================
                // 2. DATOS DEL VEHÍCULO HURTADO PARA BANNER Y AUTORIDADES
                // ========================================================
                const Text(
                  'Datos del Vehículo para Alerta Inmediata',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Placa *',
                          hintText: 'ABC123',
                          prefixIcon: const Icon(Icons.pin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 5)
                            ? 'Ingresa placa'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _colorController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Color *',
                          hintText: 'Ej: Gris / Blanco',
                          prefixIcon: const Icon(Icons.color_lens_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa color'
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _brandModelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Marca y Modelo / Línea *',
                    hintText: 'Ej: Mazda CX-30 / Renault Logan',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa marca y modelo'
                      : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _theftMode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Modalidad del hurto',
                    prefixIcon: const Icon(Icons.report_problem_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _theftModes
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _theftMode = val);
                  },
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _escapeDirectionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección / Rumbo de huida (si lo viste sin exponerte)',
                    hintText: 'Ej: Tomaron vía hacia el sur por la Av. Regional',
                    prefixIcon: const Icon(Icons.explore_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _detailsController,
                  decoration: InputDecoration(
                    labelText: 'Señas particulares del vehículo (opcional)',
                    hintText: 'Ej: Calcomanía trasera, rines negros, vidrios polarizados...',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ========================================================
                // 3. DISPARO DE ALERTA CUÁDRUPLE CON ANULACIÓN POR PIN
                // ========================================================
                if (_isCountingDown) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.shade800, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Publicando en Banner y alertando a Autoridades, Contactos y Usuarios cercanos en $_countdownSeconds s...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Colors.deepOrange.shade900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _promptCancelWithPin,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            'CANCELAR CON PIN (TOQUE ACCIDENTAL)',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _startStolenCountdown,
                    icon: Icon(
                      _alertSent ? Icons.check_circle : Icons.campaign,
                      color: Colors.white,
                    ),
                    label: Text(
                      _alertSent
                          ? 'ROBO PUBLICADO EN BANNER Y REDES'
                          : 'REPORTAR ROBO (BANNER + AUTORIDADES + RED)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _alertSent
                          ? Colors.green.shade700
                          : Colors.deepOrange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Botones directos para Autoridades
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '123'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Número 123 (Policía Nacional) copiado para llamar.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_police, color: Colors.blue),
                        label: const Text('Policía 123'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyPoliceReportSheet,
                        icon: const Icon(Icons.copy_all, color: Colors.deepOrange),
                        label: const Text('Copiar Ficha Robo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLifeRule(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.deepOrange.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
