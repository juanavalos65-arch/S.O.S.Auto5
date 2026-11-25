import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerFeedService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('banner_alerts');

  static final List> _localBanners =
      >[];
  static final StreamController<List>> _localController =
      StreamController<List>>.broadcast();

  static final ValueNotifier<List>> bannersNotifier =
      ValueNotifier<List>>(
          List>.from(defaultBanners));

  static final List> defaultBanners =
      >[
    <String, dynamic>{
      'id': 'default_ad_1',
      'category': 'ad',
      'tag': 'ALIADO DESTACADO — PAUTE AQUÍ',
      'title': 'Grúas y Talleres 24/7 — Asistencia inmediata',
    },
    <String, dynamic>{
      'id': 'default_road_1',
      'category': 'road',
      'tag': 'NOVEDAD EN LA VÍA',
      'title': 'Conduce con precaución — Reporta novedades en tiempo real',
    },
  ];

  static List> get currentBanners {
    if (_localBanners.isEmpty) {
      return List>.from(defaultBanners);
    }
    return >[
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
    _localBanners.removeWhere((Map<String, dynamic> b) => b['id'] == id);
    _localBanners.insert(0, <String, dynamic>{
      'id': id,
      'category': category,
      'tag': tag,
      'title': title,
      'isLocal': true,
    });
    final snapshot = List>.from(_localBanners);
    bannersNotifier.value = currentBanners;
    if (!_localController.isClosed) {
      _localController.add(snapshot);
    }
  }

  static void removeInstant(String id) {
    _localBanners.removeWhere((Map<String, dynamic> b) => b['id'] == id);
    final snapshot = List>.from(_localBanners);
    bannersNotifier.value = currentBanners;
    if (!_localController.isClosed) {
      _localController.add(snapshot);
    }
  }

  static Future<void> publishAlert({
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
      await _collection.doc(id).set(<String, dynamic>{
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

  static Future<void> deactivateAlert(String id) async {
    removeInstant(id);
    try {
      await _collection.doc(id).set(<String, dynamic>{
        'active': false,
        'resolvedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Stream<List>> watchActiveBanners() {
    final Stream<List>> firebaseStream = _collection
        .where('active', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((QueryDocumentSnapshot doc) {
        final data = (doc.data() as Map?) ?? <dynamic, dynamic>{};
        return <String, dynamic>{
          'id': doc.id,
          'category': (data['category'] ?? 'road').toString(),
          'tag': (data['tag'] ?? 'ALERTA S.O.S. AUTO').toString(),
          'title': (data['title'] ?? '').toString(),
        };
      }).toList();
    }).handleError((_) {});

    return StreamGroup.combine2<List>,
        List>, List>>(
      _localController.stream
          .startWith(List>.from(_localBanners)),
      firebaseStream,
      (List> local, List> firebase) {
        final seen = <String>{};
        final combined = >[];

        for (final b in local) {
          if (seen.add(b['id'].toString())) combined.add(b);
        }
        for (final b in firebase) {
          if (seen.add(b['id'].toString())) combined.add(b);
        }

        if (combined.isEmpty) {
          return List>.from(defaultBanners);
        }
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

class StreamGroup {
  static Stream<R> combine2<A, B, R>(
    Stream<A> s1,
    Stream<B> s2,
    R Function(A a, B b) combiner, {
    required B fallbackB,
  }) {
    late final StreamController<R> controller;
    StreamSubscription<A>? sub1;
    StreamSubscription<B>? sub2;
    A? lastA;
    B lastB = fallbackB;
    bool hasA = false;

    void emit() {
      if (hasA && !controller.isClosed) {
        controller.add(combiner(lastA as A, lastB));
      }
    }

    controller = StreamController<R>.broadcast(
      onListen: () {
        sub1 = s1.listen((A v) {
          lastA = v;
          hasA = true;
          emit();
        });
        sub2 = s2.listen(
          (B v) {
            lastB = v;
            emit();
          },
          onError: (_) {
            emit();
          },
        );
      },
      onCancel: () async {
        await sub1?.cancel();
        await sub2?.cancel();
      },
    );

    return controller.stream;
  }
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
