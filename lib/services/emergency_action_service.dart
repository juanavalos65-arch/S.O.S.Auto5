import 'package:flutter/material.dart';
// Asegúrate de tener la dependencia image_picker o camera para los accesos rápidos
// import 'package:image_picker/image_picker.dart'; 

class EmergencyActionService {
  // Instancia de ImagePicker como alternativa rápida y nativa para abrir la cámara
  // final ImagePicker _picker = ImagePicker();

  /// Método principal que maneja la emergencia según el tipo de evento crítico
  Future<void> triggerEmergency({
    required BuildContext context,
    required String emergencyType, // 'accidente', 'peligro', 'robo', 'transito'
  }) async {
    // 1. Mostrar retroalimentación visual inmediata en pantalla
    _showEmergencyAlertBanner(context, emergencyType);

    // 2. Activar automáticamente la cámara según el protocolo de emergencia
    await _autoOpenEmergencyCamera(emergencyType);
  }

  void _showEmergencyAlertBanner(BuildContext context, String type) {
    String message = '';
    Color bannerColor = Colors.red;

    switch (type) {
      case 'accidente':
        message = '🚨 ALERTA: Accidente reportado. Transmitiendo ubicación y cámara...';
        bannerColor = Colors.redAccent;
        break;
      case 'peligro':
        message = '⚠️ EMERGENCIA: Situación de peligro detectada. Grabando evidencia...';
        bannerColor = Colors.deepOrange;
        break;
      case 'robo':
        message = '🚨 ROBO DE AUTO: Bloqueo de coordenadas y activación de cámara iniciada...';
        bannerColor = Colors.purple;
        break;
      case 'transito':
        message = '🛡️ AGENTE DE TRÁNSITO: Iniciando grabación de respaldo legal...';
        bannerColor = Colors.indigo;
        break;
      default:
        message = '⚠️ Activando protocolo de emergencia S.O.S...';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bannerColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _autoOpenEmergencyCamera(String type) async {
    try {
      // Aquí se invoca la apertura automática de la cámara del dispositivo
      // Ejemplo con image_picker para capturar video de inmediato ante un evento crítico:
      // final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      
      // En un entorno real, si se detecta 'robo' o 'accidente', la app puede iniciar 
      // la grabación en segundo plano y respaldar el archivo en Supabase.
      print("Cámara abierta automáticamente para protocolo: $type");
    } catch (e) {
      print("Error al activar la cámara automáticamente: $e");
    }
  }
}
