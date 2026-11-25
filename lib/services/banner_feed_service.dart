import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widget/banner_dinamico.dart';

class BannerFeedService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('banner_alerts');

  static final List _localBanners = [];
  static final StreamController _localController =
      StreamController.broadcast();

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

  static final ValueNotifier bannersNotifier =
      ValueNotifier(List.from(defaultBanners));

  static List get currentBanners {
    if (_localBanners.isEmpty) {
      return List.from(defaultBanners);
    }
    return [
      ..._localBanners,
      defaultBanners.first,
    ];
  }

  static void showInstantly({
    required String id,
    required String category,
    required String tag,
    required String title,
  }) {
    _localBanners.removeWhere((b) => (b as Map)['id'] == id);
    _localBanners.insert(0, {
      'id': id,
      'category': category,
      'tag': tag,
      'title': title,
      'isLocal': true,
    });

    BannerDinamico.publicarLocal(
      id: id,
      texto: '$tag: $title',
      color: colorForCategory(category),
      icono: iconForCategory(category),
      tipo: category,
    );

    final snapshot = List.from(_localBanners);
    bannersNotifier.value = currentBanners;
    if (!_localController.isClosed) {
      _localController.add(snapshot);
    }
  }

  static void removeInstant(String id) {
    _localBanners.removeWhere((b) => (b as Map)['id'] == id);
    BannerDinamico.quitarLocal(id);

    final snapshot = List.from(_localBanners);
    bannersNotifier.value = currentBanners;
    if (!_localController.isClosed) {
      _localController.add(snapshot);
    }
  }

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
    } catch (_) {}
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

  static Stream watchActiveBanners() {
    final firebaseStream = _collection
        .where('active', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = (doc.data() as Map?) ?? {};
        return {
          'id': doc.id,
          'category': (data['category'] ?? 'road').toString(),
          'tag': (data['tag'] ?? 'ALERTA S.O.S. AUTO').toString(),
          'title': (data['title'] ?? '').toString(),
        };
      }).toList();
    }).handleError((_) {});

    late final StreamController controller;
    StreamSubscription? subLocal;
    StreamSubscription? subFb;
    List lastLocal = List.from(_localBanners);
    List lastFb = [];

    void emit() {
      if (controller.isClosed) return;
      final Set seen = Set();
      final List combined = [];

      for (final raw in lastLocal) {
        final b = Map.from(raw as Map);
        if (seen.add(b['id'].toString())) combined.add(b);
      }
      for (final raw in lastFb) {
        final b = Map.from(raw as Map);
        if (seen.add(b['id'].toString())) combined.add(b);
      }

      if (combined.isEmpty) {
        controller.add(
          defaultBanners.map((e) => Map.from(e as Map)).toList(),
        );
      } else {
        combined.add(Map.from(defaultBanners.first as Map));
        controller.add(combined);
      }
    }

    controller = StreamController.broadcast(
      onListen: () {
        emit();
        subLocal = _localController.stream.listen((v) {
          lastLocal = v as List;
          emit();
        });
        subFb = firebaseStream.listen(
          (v) {
            lastFb = v;
            emit();
          },
          onError: (_) {
            emit();
          },
        );
      },
      onCancel: () async {
        await subLocal?.cancel();
        await subFb?.cancel();
      },
    );

    return controller.stream;
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
