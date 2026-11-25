import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerFeedService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('banner_alerts');

  // === BANNER INSTANTÁNEO LOCAL ===
  // Esto es lo que hace que salga de inmediato, sin esperar a Firebase
  static final List<Map<String, dynamic>> _localBanners = [];
  static final StreamController<List<Map<String, dynamic>>> _localController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

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
  ];

  // 1. ESTO SE LLAMA PRIMERO - Sale en el banner en 0 segundos
  static void showInstantly({
    required String id,
    required String category,
    required String tag,
    required String title,
  }) {
    // Quita si ya existe uno igual para no duplicar
    _localBanners.removeWhere((b) => b['id'] == id);
    // Lo pone DE PRIMERO en la lista
    _localBanners.insert(0, {
      'id': id,
      'category': category,
      'tag': tag,
      'title': title,
      'isLocal': true,
    });
    _localController.add(List.from(_localBanners));
  }

  static void removeInstant(String id) {
    _localBanners.removeWhere((b) => b['id'] == id);
    _localController.add(List.from(_localBanners));
  }

  // 2. ESTO SE LLAMA DESPUÉS - Guarda en Firebase en segundo plano
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
    // Primero muéstralo ya, no esperes
    showInstantly(id: id, category: category, tag: tag, title: title);
    try {
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
      }, SetOptions(merge: true));
    } catch (_) {
      // Si Firebase falla, el banner local ya quedó mostrando la emergencia
      // No borramos el local, para que la emergencia no desaparezca
    }
  }

  static Future deactivateAlert(String id) async {
    removeInstant(id);
    try {
      await _collection.doc(id).set({
        'active': false,
        'resolvedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // 3. EL HOME ESCUCHA ESTO - Combina Local Instantáneo + Firebase
  static Stream<List<Map<String, dynamic>>> watchActiveBanners() {
    final firebaseStream = _collection
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map;
        return {
          'id': doc.id,
          'category': data['category'] ?? 'road',
          'tag': data['tag'] ?? 'ALERTA S.O.S. AUTO',
          'title': data['title'] ?? '',
        };
      }).toList();
    });

    // Combina los 2 streams: lo local primero, luego lo de Firebase sin duplicar
    return StreamGroup.combine2<List<Map<String, dynamic>>,
        List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
      _localController.stream.startWith(List.from(_localBanners)),
      firebaseStream,
      (local, firebase) {
        final seen = <String>{};
        final combined = <Map<String, dynamic>>[];
        // Primero los locales (emergencias activas ahora mismo)
        for (final b in local) {
          if (seen.add(b['id'].toString())) combined.add(b);
        }
        // Luego los de Firebase que no estén ya en local
        for (final b in firebase) {
          if (seen.add(b['id'].toString())) combined.add(b);
        }
        if (combined.isEmpty) return List.from(defaultBanners);
        combined.add(defaultBanners.first);
        return combined;
      },
    );
  }

  static Color colorForCategory(String category) {
    if (category == 'stolen') return const Color(0xFFB71C1C);
    if (category == 'incident') return const Color(0xFFB71C1C);
    if (category == 'road') return const Color(0xFFE65100);
    return const Color(0xFF1B5E20);
  }

  static IconData iconForCategory(String category) {
    if (category == 'stolen') return Icons.warning_amber_rounded;
    if (category == 'incident') return Icons.car_crash;
    if (category == 'road') return Icons.traffic;
    return Icons.storefront;
  }
}

// Helper para combinar 2 streams sin paquete externo
class StreamGroup {
  static Stream<R> combine2<A, B, R>(
    Stream<A> s1,
    Stream<B> s2,
    R Function(A a, B b) combiner,
  ) {
    final controller = StreamController<R>.broadcast();
    A? lastA;
    B? lastB;
    bool hasA = false;
    bool hasB = false;
    void emit() {
      if (hasA && hasB) controller.add(combiner(lastA as A, lastB as B));
    }
    s1.listen((v) { lastA = v; hasA = true; emit(); });
    s2.listen((v) { lastB = v; hasB = true; emit(); });
    return controller.stream;
  }
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
