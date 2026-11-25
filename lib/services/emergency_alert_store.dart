import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class EmergencyAlertStore {
  static const String _alertsKey = 'sos_auto_local_alerts_v1';
  static const String _vehicleKey = 'sos_auto_registered_vehicle_v1';

  /// Notificador en tiempo real para que BannerDinamico se actualice al instante
  static final ValueNotifier<List>> activeAlerts =
      ValueNotifier<List>>([]);

  /// Carga alertas locales al iniciar la app
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_alertsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          activeAlerts.value =
              decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
  }

  /// Lee el vehículo registrado localmente (sin depender de Firebase)
  static Future?> getRegisteredVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_vehicleKey) ??
          prefs.getString('registered_vehicle') ??
          prefs.getString('vehiculo_registrado');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Publica alerta INMEDIATAMENTE en el Banner y sincroniza Firebase en segundo plano
  static Future> triggerEmergencyAlert({
    required String type, // 'ACCIDENTE' | 'PELIGRO' | 'ROBO'
    required String title,
    String details = '',
    double? lat,
    double? lng,
    Map<String, dynamic>? vehicleOverride,
  }) async {
    final vehicle = vehicleOverride ?? await getRegisteredVehicle() ?? {};

    final plate = (vehicle['plate'] ?? vehicle['placa'] ?? 'SIN PLACA')
        .toString()
        .toUpperCase();
    final brand = (vehicle['brand'] ?? vehicle['marca'] ?? '').toString();
    final model = (vehicle['model'] ?? vehicle['modelo'] ?? '').toString();
    final color = (vehicle['color'] ?? '').toString();
    final vehicleType =
        (vehicle['vehicleType'] ?? vehicle['tipoVehiculo'] ?? 'Vehículo')
            .toString();
    final city = (vehicle['city'] ?? vehicle['ciudad'] ?? '').toString();
    final country = (vehicle['country'] ?? vehicle['pais'] ?? 'Colombia').toString();

    final alertId = '${type}_${plate}_${DateTime.now().millisecondsSinceEpoch}';
    final vehicleSummary = '$vehicleType $brand $model $color - Placa $plate'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final alertItem = <String, dynamic>{
      'id': alertId,
      'type': type,
      'tipo': type,
      'title': title,
      'titulo': title,
      'message': '$title: $vehicleSummary${details.isNotEmpty ? " ($details)" : ""}',
      'details': details,
      'plate': plate,
      'placa': plate,
      'vehicleType': vehicleType,
      'brand': brand,
      'marca': brand,
      'model': model,
      'modelo': model,
      'color': color,
      'city': city,
      'country': country,
      'lat': lat,
      'lng': lng,
      'active': true,
      'createdAt': DateTime.now().toIso8601String(),
      'syncedToCloud': false,
    };

    // 1. ACTUALIZACIÓN INSTANTÁNEA EN EL BANNER (0 ms, sin esperar red)
    final updated = [alertItem, ...activeAlerts.value];
    activeAlerts.value = updated;

    // 2. PERSISTENCIA LOCAL INMEDIATA
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsKey, jsonEncode(updated));
    } catch (_) {}

    // 3. SINCRONIZACIÓN ASÍNCRONA EN SEGUNDO PLANO (sin await para no frenar la UI)
    unawaited(_syncAlertToFirebaseBackground(alertItem));

    return alertItem;
  }

  /// Sube la alerta a Firestore y, si es ROBO, la guarda en 'stolen_vehicles'
  static Future<void> _syncAlertToFirebaseBackground(
    Map<String, dynamic> alertItem,
  ) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final db = FirebaseFirestore.instance;
      final id = alertItem['id'].toString();
      final plate = alertItem['plate'].toString();

      // Guarda en colección general de alertas activas para todos los usuarios
      await db.collection('emergency_alerts').doc(id).set({
        ...alertItem,
        'syncedToCloud': true,
        'serverTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Si es ROBO DE AUTO, registra también en la lista oficial de vehículos robados
      if (alertItem['type'] == 'ROBO' && plate != 'SIN PLACA') {
        await db.collection('stolen_vehicles').doc(plate).set({
          'plate': plate,
          'placa': plate,
          'vehicleType': alertItem['vehicleType'],
          'brand': alertItem['brand'],
          'marca': alertItem['marca'],
          'model': alertItem['model'],
          'modelo': alertItem['modelo'],
          'color': alertItem['color'],
          'city': alertItem['city'],
          'country': alertItem['country'],
          'lat': alertItem['lat'],
          'lng': alertItem['lng'],
          'status': 'ROBO_ACTIVO',
          'reportedAt': FieldValue.serverTimestamp(),
          'alertId': id,
        }, SetOptions(merge: true));
      }

      // Marca como sincronizada en almacenamiento local
      final current = activeAlerts.value.map((item) {
        if (item['id'] == id) {
          return {...item, 'syncedToCloud': true};
        }
        return item;
      }).toList();
      activeAlerts.value = current;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsKey, jsonEncode(current));
    } catch (_) {
      // Si no hay internet en el momento, la alerta ya quedó activa en el banner local
    }
  }

  /// Desactiva una alerta cuando el usuario la cancela
  static Future<void> dismissAlert(String alertId) async {
    final remaining =
        activeAlerts.value.where((a) => a['id'] != alertId).toList();
    activeAlerts.value = remaining;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsKey, jsonEncode(remaining));
    } catch (_) {}

    unawaited(() async {
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('emergency_alerts')
              .doc(alertId)
              .update({'active': false});
        }
      } catch (_) {}
    }());
  }
}
