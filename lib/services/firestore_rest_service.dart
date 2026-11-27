import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FirestoreRestService {
  static const String _projectId = 'sos-auto-18e1c';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  /// Guarda un documento en cualquier colección vía HTTP estándar (Wi-Fi y Datos)
  static Future<bool> guardarDocumento({
    required String coleccion,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$coleccion');
      final Map<String, dynamic> fields = {};

      datos.forEach((key, value) {
        if (value == null) return;
        if (value is bool) {
          fields[key] = {'booleanValue': value};
        } else if (value is int) {
          fields[key] = {'integerValue': value.toString()};
        } else if (value is double) {
          fields[key] = {'doubleValue': value};
        } else if (value is DateTime) {
          fields[key] = {'timestampValue': value.toUtc().toIso8601String()};
        } else {
          fields[key] = {'stringValue': value.toString()};
        }
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fields': fields}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Error HTTP Firestore ($coleccion): ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Excepción REST Firestore ($coleccion): $e');
      return false;
    }
  }

  /// Lee los últimos documentos de una colección vía HTTP estándar
  static Future<List>> leerDocumentos({
    required String coleccion,
    int limite = 25,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$coleccion?pageSize=$limite');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('Error HTTP leyendo ($coleccion): ${response.statusCode} - ${response.body}');
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = (decoded['documents'] as List<dynamic>?) ?? [];

      return docs.map((doc) {
        final map = doc as Map<String, dynamic>;
        final name = (map['name'] ?? '').toString();
        final id = name.split('/').last;
        final rawFields = (map['fields'] as Map<String, dynamic>?) ?? {};
        final Map<String, dynamic> parsed = {'id': id};

        rawFields.forEach((key, v) {
          final valMap = v as Map<String, dynamic>;
          if (valMap.containsKey('stringValue')) {
            parsed[key] = valMap['stringValue'];
          } else if (valMap.containsKey('booleanValue')) {
            parsed[key] = valMap['booleanValue'];
          } else if (valMap.containsKey('integerValue')) {
            parsed[key] = int.tryParse(valMap['integerValue'].toString()) ?? 0;
          } else if (valMap.containsKey('doubleValue')) {
            parsed[key] = valMap['doubleValue'];
          } else if (valMap.containsKey('timestampValue')) {
            parsed[key] = valMap['timestampValue'];
          }
        });

        return parsed;
      }).toList();
    } catch (e) {
      debugPrint('Error leyendo REST Firestore ($coleccion): $e');
      return [];
    }
  }
}
