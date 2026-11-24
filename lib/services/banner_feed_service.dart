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

  static Future publishAlert({
    required String id,
    required String category,
    required String tag,
    required String title,
    String city = '',
    String plate = '',
    double? lat,
    double? lng,
    String gravedad = '',
  }) async {
    // QUITAMOS EL try/catch mudo para ver el error real
    await _collection.doc(id).set({
      'category': category,
      'tag': tag,
      'title': title,
      'city': city,
      'plate': plate,
      'lat': lat,
      'lng': lng,
      'gravedad': gravedad,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(hours: 6)),
    }, SetOptions(merge: true));
    print('✅ BANNER PUBLICADO: $id - $tag');
  }

  static Future deactivateAlert(String id) async {
    await _collection.doc(id).set({
      'active': false,
      'resolvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream watchActiveBanners() {
    return _collection
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
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
      live.add(defaultBanners.first);
      return live;
    });
  }

  static Color colorForCategory(String category) {
    if (category == 'stolen') return const Color(0xFFB71C1C);
    if (category == 'incident') return const Color(0xFFB71C1C); // ROJO ACCIDENTE
    if (category == 'road') return const Color(0xFFE65100);
    return const Color(0xFF1B5E20);
  }

  static IconData iconForCategory(String category) {
    if (category == 'stolen') return Icons.warning_amber_rounded;
    if (category == 'incident') return Icons.car_crash; // ICONO ACCIDENTE
    if (category == 'road') return Icons.traffic;
    return Icons.storefront;
  }
}
