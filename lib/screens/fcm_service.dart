import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initializeFCM() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Suscripción al canal de novedades en vía y emergencias regionales
      await _fcm.subscribeToTopic("alertas_viales");
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Manejar notificación recibida en primer plano
        print("Alerta S.O.S. recibida: ${message.notification?.title}");
      });
    }
  }
}
