import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'paute_aqui_screen.dart';

class MeVareScreen extends StatefulWidget {
  const MeVareScreen({super.key});

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _detalleCtrl = TextEditingController();

  String _fallaSeleccionada = 'Grúa / Remolque';
  final List _tiposFalla = [
    {'titulo': 'Grúa / Remolque', 'icono': Icons.local_shipping, 'cat': 'Grúa y Asistencia Vial'},
    {'titulo': 'Batería descargada', 'icono': Icons.battery_alert, 'cat': 'Montallantas y Baterías'},
    {'titulo': 'Llanta pinchada', 'icono': Icons.tire_repair, 'cat': 'Montallantas y Baterías'},
    {'titulo': 'Falla mecánica', 'icono': Icons.build, 'cat': 'Taller Mecánico y Eléctrico'},
    {'titulo': 'Sin combustible', 'icono': Icons.local_gas_station, 'cat': 'Grúa y Asistencia Vial'},
    {'titulo': 'Cerrajería / Llaves', 'icono': Icons.vpn_key, 'cat': 'Taller Mecánico y Eléctrico'},
  ];

  String _placa = 'SIN PLACA';
  String _vehiculoDesc = 'Vehículo registrado';
  String _conductor = 'Conductor S.O.S. Auto';
  String _ciudad = 'Colombia';
  List _contactos = [];

  double? _lat;
  double? _lng;
  String _gpsTexto = 'Obteniendo ubicación GPS...';
  bool _solicitudPublicada = false;

  String get _mapsUrl => (_lat != null && _lng != null)
      ? 'https://maps.google.com/?q=$_lat,$_lng'
      : 'Ubicación aproximada en $_ciudad';

  @override
  void initState() {
    super.initState();
    _cargarDatosYGps();
  }

  Future<void> _cargarDatosYGps() async {
    try {
      final raw = await _secureStorage.read(key: 'sos_auto_registered_vehicle');
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final v = data['vehicle'] as Map<String, dynamic>? ?? {};
        final o = data['owner'] as Map<String, dynamic>? ?? {};
        final l = data['location'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _placa = (v['plate'] ?? 'SIN PLACA').toString().toUpperCase();
            _vehiculoDesc = '${v['type'] ?? 'Auto'}${v['brand'] ?? ''} ${v['model'] ?? ''} (${v['color'] ?? ''})'.trim();
            _conductor = (o['name'] ?? 'Conductor S.O.S. Auto').toString();
            _ciudad = (l['city'] ?? 'Colombia').toString();
            _contactos = data['emergencyContacts'] as List? ?? [];
          });
        }
      }
    } catch (_) {}

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _gpsTexto = '${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
          });
        }
      } else if (mounted) {
        setState(() => _gpsTexto = 'GPS sin permiso ($_ciudad)');
      }
    } catch (_) {
      if (mounted) setState(() => _gpsTexto = 'Sector: $_ciudad');
    }
  }

  @override
  void dispose() {
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _publicarSolicitudVarada() async {
    try {
      await FirebaseFirestore.instance.collection('solicitudes_asistencia').add({
        'tipo': 'ME_VARE',
        'falla': _fallaSeleccionada,
        'detalle': _detalleCtrl.text.trim(),
        'placa': _placa,
        'vehiculo': _vehiculoDesc,
        'conductor': _conductor,
        'ciudad': _ciudad,
