import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AdminNotifierService {
  static const String _adminEmail = 'soporte.applay65@gmail.com';
  static const String _adminWhatsApp = '573116479280';

  /// 1. Envía el reporte automáticamente a soporte.applay65@gmail.com en segundo plano
  static Future<bool> notificarCorreo({
    required String modulo,
    required String titulo,
    required String detalle,
    String placa = 'SIN PLACA',
    String ciudad = 'Colombia',
    String mapsUrl = '',
  }) async {
    try {
      final url = Uri.parse('https://formsubmit.co/ajax/$_adminEmail');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': '🚨 S.O.S. Auto [$modulo] - $titulo',
          'Módulo': modulo,
          'Título': titulo,
          'Placa': placa,
          'Ciudad': ciudad,
          'Detalle': detalle,
          'Ubicación GPS': mapsUrl.isNotEmpty ? mapsUrl : 'No disponible',
          'Fecha': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 2. Abre tu WhatsApp (+57 311 647 9280) con el reporte listo para enviar
  static Future<void> enviarWhatsAppAdmin({
    required String modulo,
    required String detalle,
    String placa = 'SIN PLACA',
    String ciudad = 'Colombia',
  }) async {
    final texto = Uri.encodeComponent(
      '📲 *REPORTE S.O.S. AUTO ($modulo)*\n'
      '• *Placa:* $placa\n'
      '• *Ciudad:* $ciudad\n'
      '• *Reporte:* $detalle',
    );
    final uri = Uri.parse('https://wa.me/$_adminWhatsApp?text=$texto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
