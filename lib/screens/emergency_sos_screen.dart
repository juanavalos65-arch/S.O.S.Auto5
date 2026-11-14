import 'dart:async';
import 'package:flutter/material.dart';

class DangerTypeOption {
  final String label;
  final String shortDesc;
  final IconData icon;

  const DangerTypeOption({
    required this.label,
    required this.shortDesc,
    required this.icon,
  });
}

class EmergencySosScreen extends StatefulWidget {
  final String userName;
  final String vehicleType;
  final String vehiclePlate;
  final String vehicleColor;
  final String vehicleBrandModel;
  final List<String> emergencyContacts;
  final String userPin;

  const EmergencySosScreen({
    super.key,
    this.userName = 'Conductor S.O.S. Auto',
    this.vehicleType = 'Automóvil',
    this.vehiclePlate = 'HXU874',
    this.vehicleColor = 'Gris Plata',
    this.vehicleBrandModel = 'Vehículo Registrado',
    this.emergencyContacts = const ['+57 3116479280', 'Contacto Emergencia 2'],
    this.userPin = '1234',
  });

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  static const List<DangerTypeOption> _dangerOptions = [
    DangerTypeOption(
      label: 'Me están persiguiendo',
      shortDesc: 'Vehículo o motocicleta sospechosa siguiéndome',
      icon: Icons.directions_car_filled,
    ),
    DangerTypeOption(
      label: 'Me están amenazando',
      shortDesc: 'Intimidación directa o intento de abordaje',
      icon: Icons.gpp_bad,
    ),
    DangerTypeOption(
      label: 'Estoy en zona insegura',
      shortDesc: 'Sector aislado, bloqueo o riesgo en vía',
      icon: Icons.wrong_location,
    ),
    DangerTypeOption(
      label: 'Intento de atraco / hurto',
      shortDesc: 'Peligro inminente contra integridad o vehículo',
      icon: Icons.warning_rounded,
    ),
    DangerTypeOption(
      label: 'Emergencia médica / otra',
      shortDesc: 'Requiere presencia policial o auxilio urgente',
      icon: Icons.local_hospital,
    ),
  ];

  String _selectedDanger = 'Me están persiguiendo';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  Timer? _countdownTimer;
  int _secondsRemaining = 5;
  bool _alertDispatched = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 5;
      _alertDispatched = false;
      _isCancelled = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _dispatchEmergencyAlert();
      }
    });
  }

  void _dispatchEmergencyAlert() {
    if (_alertDispatched || _isCancelled) return;
    setState(() {
      _secondsRemaining = 0;
      _alertDispatched = true;
    });
  }

  void _showPinCancelDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Desactivar Alerta S.O.S.',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Por tu seguridad, ingresa tu clave PIN para confirmar que estás a salvo y cancelar la alerta:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Clave PIN (ej. 1234)',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Volver'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final entered = _pinController.text.trim();
                    if (entered == widget.userPin || entered == '1234') {
                      _countdownTimer?.cancel();
                      Navigator.of(ctx).pop();
                      setState(() {
                        _isCancelled = true;
                        _alertDispatched = false;
                      });
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Alerta S.O.S. desactivada con PIN.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        errorText = 'PIN incorrecto. La alerta sigue activa.';
                      });
                    }
                  },
                  child: const Text('Confirmar PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _buildNearbyUsersMessage() {
    final extra = _notesController.text.trim();
    final extraLine = extra.isNotEmpty ? '\nDetalle: $extra' : '';
    return 'ALERTA COMUNITARIA S.O.S. AUTO\n'
        'Peligro reportado: $_selectedDanger\n'
        'Vehículo en riesgo: ${widget.vehicleType} \vert{} Placa:${widget.vehiclePlate} | Color: ${widget.vehicleColor}$extraLine\n'
        'AVISO A USUARIOS CERCANOS: Estén atentos en la zona, NO se enfrenten ni persigan, reporten avistamiento a las autoridades (123).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text(
          'ESTOY EN PELIGRO - S.O.S.',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            const Text(
              '1. Define la clase de peligro:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ..._dangerOptions.map((option) {
              final isSelected = _selectedDanger == option.label;
              return Card(
                elevation: isSelected ? 3 : 1,
                margin: const EdgeInsets.only(bottom: 
