import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerFeedService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('banner_alerts');

  static final List defaultBanners = [
    {
      'id': 'default_ad_1',
      'category': 'ad',
      'tag': 'ALIADO DESTACADO — PAUTE AQUÍ',
      'title': 'Grúas y Talleres 24/7 — Asistencia inmediata',
    },
    {
      'id': 'default_road_1',
      'category': 'road',
      'tag': 'NOVEDAD EN LA VÍA',
      'title': 'Conduce con precaución — Reporta novedades en tiempo real',
    },
    {
      'id': 'default_ad_2',
      'category': 'ad',
      'tag': 'PAUTE AQUÍ — S.O.S. AUTO',
      'title': 'Anuncia tu taller, grúa o serviteca a miles de conductores',
    },
  ];

  /// Publica una alerta en el banner en vivo (robo, novedad vial o pauta)
  static Future publishAlert({
    required String id,
    required String category,
    required String tag,
    required String title,
    String city = '',
    String plate = '',
  }) async {
    try {
      await _collection.doc(id).set({
        'category': category,
        'tag': tag,
        'title': title,
        'city': city,
        'plate': plate,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Desactiva una alerta del banner (cuando se despeja la vía o se recupera el auto)
  static Future deactivateAlert(String id) async {
    try {
      await _collection.doc(id).set({
        'active': false,
        'resolvedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Stream en tiempo real para HomeScreen
  static Stream watchActiveBanners() {
    return _collection
        .where('active', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return List.from(defaultBanners);
      }
      final List live = snapshot.docs.map((doc) {
        final data = doc.data() as Map;
        return {
          'id': doc.id,
          'category': data['category'] ?? 'road',
          'tag': data['tag'] ?? 'ALERTA S.O.S. AUTO',
          'title': data['title'] ?? '',
        };
      }).toList();

      // Intercala siempre la invitación de pauta comercial si solo hay alertas
      live.add(defaultBanners.first);
      return live;
    });
  }

  static Color colorForCategory(String category) {
    if (category == 'stolen') return const Color(0xFFB71C1C);
    if (category == 'road') return const Color(0xFFE65100);
    return const Color(0xFF1B5E20);
  }

  static IconData iconForCategory(String category) {
    if (category == 'stolen') return Icons.warning_amber_rounded;
    if (category == 'road') return Icons.traffic;
    return Icons.storefront;
  }
}
