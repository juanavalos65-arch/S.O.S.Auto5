import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencySosScreen extends StatefulWidget {
  final String vehicleType;
  final String vehiclePlate;
  final String vehicleColor;
  final String ownerName;
  final List<String> emergencyPhones;
  final String currentLocationText;

  const EmergencySosScreen({
    super.key,
    this.vehicleType = 'Automóvil',
    this.vehiclePlate = 'HXU874',
    this.vehicleColor = 'Gris',
    this.ownerName = 'Conductor S.O.S. Auto',
    this.emergencyPhones = const ['3116479280'],
    this.currentLocationText = 'Ubicación GPS activa en tiempo real',
  });

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  static const String _correctPin = '1234';
  int _countdown = 5;
  Timer? _timer;
  bool _alertSent = false;
  bool _isCancelled = false;

  final List<String> _dangerTypes = const [
    'Intento de hurto / Atraco',
    'Accidente grave / Heridos',
    'Persecución o amenaza en vía',
    'Falla crítica en zona insegura',
  ];

  String _selectedDanger = 'Intento de hurto / Atraco';

  @override
  void initState() {
    super.initState();
    _startEmergencyCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmergencyCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _triggerEmergencyDispatch();
      }
    });
  }

  void _triggerEmergencyDispatch() {
    if (_isCancelled || _alertSent) return;
    setState(() {
      _alertSent = true;
    });
    HapticFeedback.heavyImpact();
    _sendWhatsAppEmergencyAlert();
  }

  String _buildNearbyUsersMessage() {
    return '🚨 ALERTA S.O.S. AUTO EN TU ZONA 🚨\n'
        'Tipo de amenaza: $_selectedDanger\n'
        'Vehículo: ${widget.vehicleType} | Placa: ${widget.vehiclePlate} | Color: ${widget.vehicleColor}\n'
        'Ubicación: ${widget.currentLocationText}\n'
        'Por favor precaución en el sector y reportar a autoridades (123).';
  }

  Future<void> _sendWhatsAppEmergencyAlert() async {
    final String message = Uri.encodeComponent(
      '🆘 EMERGENCIA S.O.S. AUTO 🆘\n'
      'Conductor: ${widget.ownerName}\n'
      'Amenaza: $_selectedDanger\n'
      'Vehículo: ${widget.vehicleType} (${widget.vehicleColor}) - Placa: ${widget.vehiclePlate}\n'
      'Ubicación: ${widget.currentLocationText}\n'
      'Se requiere apoyo inmediato y aviso a la Línea 123.',
    );

    if (widget.emergencyPhones.isNotEmpty) {
      final String cleanPhone =
          widget.emergencyPhones.first.replaceAll(RegExp(r'[^0-9]'), '');
      final String formattedPhone =
          cleanPhone.startsWith('57') ? cleanPhone : '57$cleanPhone';
      final Uri waUri =
          Uri.parse('https://wa.me/$formattedPhone?text=$message');
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _callAuthorities123() async {
    final Uri telUri = Uri.parse('tel:123');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  void _showPinCancelDialog() {
    final TextEditingController pinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Cancelar Alerta S.O.S.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu PIN de seguridad de 4 dígitos para desactivar la emergencia:',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'PIN de seguridad',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Volver'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (pinController.text.trim() == _correctPin) {
                      _timer?.cancel();
                      setState(() {
                        _isCancelled = true;
                        _alertSent = false;
                      });
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Alerta S.O.S. desactivada con éxito.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        errorText = 'PIN incorrecto';
                      });
                    }
                  },
                  child: const Text('Confirmar Cancelación'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    Color bannerColor;
    IconData bannerIcon;
    String statusTitle;
    String statusSubtitle;

    if (_isCancelled) {
      bannerColor = Colors.green.shade700;
      bannerIcon = Icons.verified_user;
      statusTitle = 'EMERGENCIA CANCELADA';
      statusSubtitle = 'Desactivación verificada con PIN de seguridad.';
    } else if (_alertSent) {
      bannerColor = Colors.red.shade900;
      bannerIcon = Icons.warning_amber_rounded;
      statusTitle = '¡ALERTA S.O.S. ENVIADA!';
      statusSubtitle =
          'Notificando contactos de emergencia, autoridades y red cercana.';
    } else {
      bannerColor = Colors.orange.shade800;
      bannerIcon = Icons.timer;
      statusTitle = 'ENVIANDO ALERTA EN $_countdown s...';
      statusSubtitle = 'Presiona "Cancelar con PIN" si fue una activación accidental.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. EMERGENCIA'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del Vehículo Reportado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Divider(),
                    Text('Placa: ${widget.vehiclePlate}'),
                    Text('Tipo: ${widget.vehicleType}'),
                    Text('Color: ${widget.vehicleColor}'),
                    Text('Ubicación: ${widget.currentLocationText}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona el tipo de emergencia:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ..._dangerTypes.map(
              (danger) => RadioListTile<String>(
                title: Text(danger),
                value: danger,
                groupValue: _selectedDanger,
                activeColor: Colors.red.shade800,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDanger = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mensaje difundido a usuarios cercanos:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _buildNearbyUsersMessage(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _callAuthorities123,
              icon: const Icon(Icons.phone_in_talk),
              label: const Text(
                'LLAMAR A AUTORIDADES (123)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _sendWhatsAppEmergencyAlert,
              icon: const Icon(Icons.message),
              label: const Text(
                'ENVIAR ALERTA WHATSAPP A CONTACTOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            if (!_isCancelled)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black54, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showPinCancelDialog,
                icon: const Icon(Icons.lock_outline),
                label: const Text(
                  'DESACTIVAR ALERTA CON PIN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
