import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'banner_feed_service.dart';

class AnalyticsAndAdsService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _deviceIdKey = 'sos_auto_unique_device_id';

  /// Registra el dispositivo único en tiempo real en Firestore ('instalaciones')
  static Future registerUniqueInstall() async {
    try {
      final db = FirebaseFirestore.instance;
      String? deviceId = await _storage.read(key: _deviceIdKey);
      final bool isFirstInstall = deviceId == null || deviceId.isEmpty;

      if (isFirstInstall) {
        final rand = Random().nextInt(999999).toString().padLeft(6, '0');
        deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
        await _storage.write(key: _deviceIdKey, value: deviceId);

        await db.collection('estadisticas').doc('app').set({
          'totalInstalaciones': FieldValue.increment(1),
          'ultimaInstalacionEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      String platform = 'android';
      if (kIsWeb) {
        platform = 'web_iphone';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      }

      await db.collection('instalaciones').doc(deviceId).set({
        'deviceId': deviceId,
        'plataforma': platform,
        'ultimaConexionEn': FieldValue.serverTimestamp(),
        if (isFirstInstall) 'instaladoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Revisa pautas vencidas: las desactiva en 'aliados', 'pautas_comerciales' y el banner
  static Future checkAndDeactivateExpiredAds() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = Timestamp.now();

      final expiredAllies = await db
          .collection('aliados')
          .where('activo', isEqualTo: true)
          .where('expiraEn', isLessThanOrEqualTo: now)
          .limit(25)
          .get();

      for (final doc in expiredAllies.docs) {
        await db.collection('aliados').doc(doc.id).update({
          'activo': false,
          'estadoVencimiento': 'vencida_automaticamente',
        });
        await BannerFeedService.deactivateAlert('ad_${doc.id}');
      }

      final expiredPautas = await db
          .collection('pautas_comerciales')
          .where('activa', isEqualTo: true)
          .where('expiraEn', isLessThanOrEqualTo: now)
          .limit(25)
          .get();

      for (final doc in expiredPautas.docs) {
        await db.collection('pautas_comerciales').doc(doc.id).update({
          'activa': false,
          'estadoVencimiento': 'vencida',
        });
      }
    } catch (_) {}
  }
}
