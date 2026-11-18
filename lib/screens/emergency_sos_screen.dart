import 'dart:async';
import 'package:flutter/material.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  int _seconds = 5;
  bool _alertaActiva = false;
  Timer? _timer;
  String _amenaza = 'Intento de hurto / Atraco en vía';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds > 1) {
        setState(() => _seconds--);
      } else {
        t.cancel();
        setState(() => _alertaActiva = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8E0000),
      appBar: AppBar(
        title: const Text('ESTOY EN PELIGRO — SOS'),
        backgroundColor: const Color(0xFF5F0000),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _alertaActiva ? Icons.notifications_active : Icons.timer,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              _alertaActiva
                  ? '¡ALERTA SOS ENVIADA!'
                  : 'Enviando alerta silenciosa en $_seconds s...',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _amenaza,
              dropdownColor: const Color(0xFF5F0000),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
              items: const [
                DropdownMenuItem(value: 'Intento de hurto / Atraco en vía', child: Text('Intento de hurto / Atraco en vía')),
                DropdownMenuItem(value: 'Persecución sospechosa', child: Text('Persecución sospechosa')),
                DropdownMenuItem(value: 'Retén ilegal / Zona insegura', child: Text('Retén ilegal / Zona insegura')),
                DropdownMenuItem(value: 'Emergencia médica urgente', child: Text('Emergencia médica urgente')),
              ],
              onChanged: (v) => setState(() => _amenaza = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF8E0000)),
                onPressed: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text('CANCELAR / DESACTIVAR ALERTA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
