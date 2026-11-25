import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BotonWhatsAppEmergencia extends StatelessWidget {
  final String tipoEmergencia; // Ej: "ESTOY EN PELIGRO", "ACCIDENTE DE TRÁNSITO", "ME VARÉ"
  final String? detalleAdicional;
  final String? ubicacionTexto;

  const BotonWhatsAppEmergencia({
    super.key,
    required this.tipoEmergencia,
    this.detalleAdicional,
    this.ubicacionTexto,
  });

  Future<void> _enviarWhatsApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Lee los datos guardados del registro
    final nombre = prefs.getString('conductor_nombre') ??
        prefs.getString('nombre') ??
        'Conductor S.O.S. Auto';
    final placa = (prefs.getString('vehiculo_placa') ??
            prefs.getString('placa') ??
            'SIN PLACA')
        .toUpperCase();
    final vehiculo = prefs.getString('vehiculo_modelo') ??
        prefs.getString('vehiculo') ??
        'Vehículo registrado';

    // Lee los contactos de emergencia guardados
    final contacto1 = prefs.getString('contacto1_telefono') ??
        prefs.getString('contacto_emergencia_1') ??
        '';
    final contacto2 = prefs.getString('contacto2_telefono') ??
        prefs.getString('contacto_emergencia_2') ??
        '';

    final mensaje = StringBuffer()
      ..writeln('🚨 *ALERTA S.O.S. AUTO: $tipoEmergencia* 🚨')
      ..writeln('👤 Conductor: $nombre')
      ..writeln('🚗 Vehículo: $vehiculo')
      ..writeln('🪪 Placa: *$placa*');

    if (detalleAdicional != null && detalleAdicional!.trim().isNotEmpty) {
      mensaje.writeln('⚠️ Detalle: $detalleAdicional');
    }
    if (ubicacionTexto != null && ubicacionTexto!.trim().isNotEmpty) {
      mensaje.writeln('📍 Ubicación: $ubicacionTexto');
    }
    mensaje.writeln('\nEnviado desde *S.O.S. Auto* - Por favor comunícate o ayuda.');

    final textoCodificado = Uri.encodeComponent(mensaje.toString());

    // Limpia el número del primer contacto (deja solo dígitos)
    final tel1Limpio = contacto1.replaceAll(RegExp(r'[^0-9]'), '');

    Uri url;
    if (tel1Limpio.isNotEmpty) {
      // Abre chat directo con el Contacto de Emergencia 1
      final numeroFinal =
          tel1Limpio.length == 10 ? '57$tel1Limpio' : tel1Limpio;
      url = Uri.parse('https://wa.me/$numeroFinal?text=$textoCodificado');
    } else {
      // Si no hay contacto guardado, abre WhatsApp para elegir contacto con el mensaje listo
      url = Uri.parse('https://wa.me/?text=$textoCodificado');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp en este dispositivo.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Si existe un segundo contacto, muestra aviso rápido para reenviarle también
    final tel2Limpio = contacto2.replaceAll(RegExp(r'[^0-9]'), '');
    if (tel2Limpio.isNotEmpty && context.mounted) {
      final numero2Final =
          tel2Limpio.length == 10 ? '57$tel2Limpio' : tel2Limpio;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFF128C7E),
          content: const Text('¿Enviar también al Contacto de Emergencia 2?'),
          action: SnackBarAction(
            label: 'ENVIAR A 2',
            textColor: Colors.white,
            onPressed: () async {
              final url2 =
                  Uri.parse('https://wa.me/$numero2Final?text=$textoCodificado');
              await launchUrl(url2, mode: LaunchMode.externalApplication);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => _enviarWhatsApp(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // Verde oficial WhatsApp
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.chat, size: 26, color: Colors.white),
          label: const Text(
            'ENVIAR WHATSAPP A CONTACTOS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
