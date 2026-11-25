import 'package:url_launcher/url_launcher.dart';
import 'vehicle_session.dart';

class EmergencyNotifierService {
  /// Envía la alerta de emergencia ÚNICAMENTE a los contactos registrados del vehículo.
  /// No envía información al correo ni al WhatsApp del administrador.
  static Future> enviarAlertaContactos({
    required String tipoEmergencia, // Ej: 'ESTOY EN PELIGRO', 'ACCIDENTE', 'ROBO DE AUTO'
    String detalleAdicional = '',
    double? latitud,
    double? longitud,
    String mapsUrlManual = '',
  }) async {
    // 1. Asegura que los datos del vehículo y contactos estén cargados desde memoria persistente
    await VehicleSession.cargar();

    final placa = VehicleSession.placa.trim().isEmpty
        ? 'SIN PLACA'
        : VehicleSession.placa.trim().toUpperCase();

    final marca = VehicleSession.marca.trim();
    final modelo = VehicleSession.modelo.trim();
    final color = VehicleSession.color.trim();
    final vehiculoDesc = [marca, modelo, color].where((e) => e.isNotEmpty).join(' ');

    final conductor = VehicleSession.nombreConductor.trim().isEmpty
        ? 'Conductor registrado en S.O.S. Auto'
        : VehicleSession.nombreConductor.trim();

    // 2. Construye el enlace de ubicación GPS
    String ubicacionTexto = 'GPS no disponible';
    if (mapsUrlManual.isNotEmpty) {
      ubicacionTexto = mapsUrlManual;
    } else if (latitud != null && longitud != null) {
      ubicacionTexto = 'https://maps.google.com/?q=$latitud,$longitud';
    }

    // 3. Recopila y valida los contactos de emergencia del usuario
    final contactosBrutos = [
      VehicleSession.contacto1Telefono,
      VehicleSession.contacto2Telefono,
    ];

    final contactosValidos = contactosBrutos
        .map((tel) => tel.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((tel) => tel.length >= 7)
        .toSet() // Evita duplicados si pusieron el mismo número dos veces
        .toList();

    if (contactosValidos.isEmpty) {
      return {
        'enviado': false,
        'motivo': 'SIN_CONTACTOS',
        'mensaje': 'No hay contactos de emergencia registrados en este vehículo.',
      };
    }

    // 4. Arma el mensaje oficial de emergencia (sin exponer el teléfono de la víctima)
    final buffer = StringBuffer()
      ..writeln('🚨 *ALERTA DE EMERGENCIA - S.O.S. AUTO* 🚨')
      ..writeln('• *Tipo:* $tipoEmergencia')
      ..writeln('• *Conductor:* $conductor')
      ..writeln('• *Vehículo:* ${vehiculoDesc.isNotEmpty ? vehiculoDesc : 'No especificado'}')
      ..writeln('• *Placa:* $placa')
      ..writeln('• *Ubicación:* $ubicacionTexto');

    if (detalleAdicional.trim().isNotEmpty) {
      buffer.writeln('• *Detalle:* ${detalleAdicional.trim()}');
    }

    buffer.writeln('\n⚠️ *Mensaje automático de S.O.S. Auto. Por favor comuníquese con las autoridades o acuda en su ayuda.*');

    final mensajeCodificado = Uri.encodeComponent(buffer.toString());

    int enviados = 0;

    for (final tel in contactosValidos) {
      // Si es número celular colombiano de 10 dígitos (inicia en 3), antepone 57
      final telefonoFinal = (tel.length == 10 && tel.startsWith('3')) ? '57$tel' : tel;
      final whatsappUri = Uri.parse('https://wa.me/$telefonoFinal?text=$mensajeCodificado');

      if (await canLaunchUrl(whatsappUri)) {
        final lanzado = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        if (lanzado) enviados++;
      }
    }

    return {
      'enviado': enviados > 0,
      'cantidad': enviados,
      'motivo': enviados > 0 ? 'OK' : 'ERROR_WHATSAPP',
      'mensaje': enviados > 0
          ? 'Alerta preparada para $enviados contacto(s) de emergencia.'
          : 'No se pudo abrir WhatsApp en este dispositivo.',
    };
  }

  /// Abre el marcador telefónico con la línea de emergencias (123 por defecto)
  static Future<void> llamarAutoridades({String numeroEmergencia = '123'}) async {
    final telUri = Uri.parse('tel:$numeroEmergencia');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }
}
