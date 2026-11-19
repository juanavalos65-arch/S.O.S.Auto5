import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vehicle_session.dart';
import 'paute_aqui_screen.dart';

class AlliesScreen extends StatefulWidget {
  const AlliesScreen({super.key});

  @override
  State<AlliesScreen> createState() => _AlliesScreenState();
}

class _AlliesScreenState extends State<AlliesScreen> {
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double? _userLat;
  double? _userLng;
  bool _timedOut = false;
  bool _isSeeding = false;
  Timer? _waitTimer;

  final List<String> _categories = [
    'Todos',
    'Grúas',
    'Talleres / Mecánica',
    'Baterías / Eléctricos',
    'Montallantas',
    'Cerrajería',
    'Abogados / Seguros',
  ];

  final List> _defaultAllies = [
    {
      'id': 'gruas_express_247',
      'name': 'Grúas Express 24/7',
      'category': 'Grúas',
      'city': 'Medellín / Área Metropolitana',
      'description': 'Grúa plataforma y gancho, rescate vehicular 24 horas en ciudad y carretera.',
      'phone': '573001112233',
      'lat': 6.2442,
      'lng': -75.5812,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'gruas_sabana_sincelejo',
      'name': 'Grúas y Asistencia La Sabana',
      'category': 'Grúas',
      'city': 'Sincelejo / Sucre',
      'description': 'Servicio de grúa planchón 24/7 en Sincelejo, Tolú, Coveñas y Troncal de Occidente.',
      'phone': '573002223344',
      'lat': 9.3047,
      'lng': -75.3978,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'baterias_el_rayo',
      'name': 'Baterías y Eléctricos El Rayo',
      'category': 'Baterías / Eléctricos',
      'city': 'Medellín / Sincelejo',
      'description': 'Paso de corriente, diagnóstico de alternador e instalación de baterías a domicilio.',
      'phone': '573004445566',
      'lat': 9.3012,
      'lng': -75.3950,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'taller_automotriz_integral',
      'name': 'Taller Mecánico Automotriz Express',
      'category': 'Talleres / Mecánica',
      'city': 'Sincelejo / Medellín',
      'description': 'Mecánica rápida en vía, escáner automotriz, frenos, suspensión y sincronización.',
      'phone': '573005556677',
      'lat': 9.3080,
      'lng': -75.4010,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'serviteca_la_33',
      'name': 'Serviteca y Montallantas Móvil 24H',
      'category': 'Montallantas',
      'city': 'Medellín / Sincelejo',
      'description': 'Despinche móvil en vía, calibración y cambio de llantas a domicilio.',
      'phone': '573007778899',
      'lat': 6.2389,
      'lng': -75.5901,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'cerrajeria_llave_maestra',
      'name': 'Cerrajería Automotriz Llave Maestra',
      'category': 'Cerrajería',
      'city': 'Cobertura Urbana 24/7',
      'description': 'Apertura de vehículos sin daño y duplicado de llaves con chip y control.',
      'phone': '573009990011',
      'lat': 9.3035,
      'lng': -75.3965,
      'activo': true,
      'verified': true,
    },
    {
      'id': 'asistencia_juridica_vial',
      'name': 'Asesoría Jurídica y Seguros Viales',
      'category': 'Abogados / Seguros',
      'city': 'Nacional (Colombia)',
      'description': 'Acompañamiento legal en accidentes de tránsito, comparendos y reclamaciones.',
      'phone': '573116479280',
      'lat': 6.2518,
      'lng': -75.5636,
      'activo': true,
      'verified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _ensureInitialAlliesInFirestore();
    _waitTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_timedOut) {
        setState(() => _timedOut = true);
      }
    });
  }

  Future<void> _ensureInitialAlliesInFirestore() async {
    if (_isSeeding) return;
    _isSeeding = true;
    try {
      final col = FirebaseFirestore.instance.collection('aliados');
      final existing = await col.limit(1).get().timeout(const Duration(seconds: 5));
      if (existing.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final ally in _defaultAllies) {
          final docRef = col.doc(ally['id'] as String);
          batch.set(docRef, {
            ...ally,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (_) {
      // Si las reglas de Firestore aún restringen escritura, la lista de respaldo sigue funcionando
    } finally {
      _isSeeding = false;
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  double? _calculateDistanceKm(Map<String, dynamic> ally) {
    final lat = (ally['lat'] as num?)?.toDouble();
    final lng = (ally['lng'] as num?)?.toDouble();
    if (_userLat == null || _userLng == null || lat == null || lng == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(_userLat!, _userLng!, lat, lng);
    return meters / 1000.0;
  }

  Future<void> _contactAlly(String rawPhone, String allyName, {bool whatsapp = false}) async {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final String vehicleInfo = VehicleSession.hasVehicle
        ? 'Vehículo: ${VehicleSession.summary}'
        : 'Conductor usuario de S.O.S. Auto';
    final String gpsInfo = (_userLat != null && _userLng != null)
        ? '\nMi ubicación GPS: https://maps.google.com/?q=$_userLat,$_userLng'
        : '';

    final String msg = Uri.encodeComponent(
      'Hola *$allyName*, te contacto desde el directorio de aliados de *S.O.S. Auto*.\n'
      '$vehicleInfo$gpsInfo\n'
      'Necesito información / asistencia.',
    );

    final Uri uri = whatsapp
        ? Uri.parse('https://wa.me/$digits?text=$msg')
        : Uri.parse('tel:+$digits');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text(
          'Aliados Comerciales 24/7',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PauteAquiScreen()),
              );
            },
            icon: const Icon(Icons.add_business, color: Color(0xFFFFC107), size: 18),
            label: const Text(
              'Pautar',
              style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner informativo de trato directo sin comisiones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFFE8F5E9),
              child: const Row(
                children: [
                  Icon(Icons.handshake, color: Color(0xFF1B5E20), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trato directo entre conductor y aliado • 0% comisiones ni intermediarios.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Buscar taller, grúa, ciudad o servicio...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Filtros horizontales por categoría
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Listado en tiempo real desde Firestore ('aliados') con respaldo inmediato
            Expanded(
              child: StreamBuilder<QuerySnapshot>>(
                stream: FirebaseFirestore.instance
                    .collection('aliados')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_timedOut) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.hasData ? snapshot.data!.docs : [];
                  final bool usingFallback = docs.isEmpty;

                  final List> rawList = usingFallback
                      ? List>.from(_defaultAllies)
                      : docs
                          .map((d) => d.data())
                          .where((m) => m['activo'] != false)
                          .toList();

                  // Filtrar por categoría y búsqueda
                  final filtered = rawList.where((map) {
                    final cat = (map['category'] ?? map['categoria'] ?? '').toString();
                    final name = (map['name'] ?? map['nombre'] ?? '').toString().toLowerCase();
                    final city = (map['city'] ?? map['ciudad'] ?? '').toString().toLowerCase();
                    final desc = (map['description'] ?? map['descripcion'] ?? '').toString().toLowerCase();

                    final matchesCat =
                        _selectedCategory == 'Todos' || cat == _selectedCategory;
                    final matchesQuery = _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        city.contains(_searchQuery) ||
                        desc.contains(_searchQuery) ||
                        cat.toLowerCase().contains(_searchQuery);

                    return matchesCat && matchesQuery;
                  }).toList();

                  // Ordenar por cercanía GPS si hay coordenadas disponibles
                  filtered.sort((a, b) {
                    final distA = _calculateDistanceKm(a);
                    final distB = _calculateDistanceKm(b);
                    if (distA == null && distB == null) return 0;
                    if (distA == null) return 1;
                    if (distB == null) return -1;
                    return distA.compareTo(distB);
                  });

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.store_mall_directory_outlined,
                                size: 54, color: Colors.black45),
                            const SizedBox(height: 10),
                            const Text(
                              'No hay aliados en esta categoría o búsqueda todavía.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PauteAquiScreen()),
                                );
                              },
                              icon: const Icon(Icons.campaign),
                              label: const Text('Anunciar mi negocio aquí'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ally = filtered[index];
                      final String name =
                          (ally['name'] ?? ally['nombre'] ?? 'Aliado S.O.S. Auto').toString();
                      final String category =
                          (ally['category'] ?? ally['categoria'] ?? 'Asistencia Vial').toString();
                      final String city =
                          (ally['city'] ?? ally['ciudad'] ?? 'Colombia').toString();
                      final String desc =
                          (ally['description'] ?? ally['descripcion'] ?? '').toString();
                      final String phone =
                          (ally['phone'] ?? ally['telefono'] ?? '').toString();
                      final double? distKm = _calculateDistanceKm(ally);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFE8F5E9),
                                    child: Icon(Icons.verified, color: Color(0xFF1B5E20)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$category • $city',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (distKm != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${distKm.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          color: Color(0xFF0D47A1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: phone.isEmpty
                                          ? null
                                          : () => _contactAlly(phone, name),
                                      icon: const Icon(Icons.phone, size: 18),
                                      label: const Text('Llamar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: phone.isEmpty
                                          ? null
                                          : () => _contactAlly(phone, name, whatsapp: true),
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('WhatsApp'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
