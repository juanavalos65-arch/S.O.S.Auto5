import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vehicle_session.dart';
import 'paute_aqui_screen.dart';

class AlliesScreen extends StatefulWidget {
  const AlliesScreen({super.key});

  @override
  State createState() => _AlliesScreenState();
}

class _AlliesScreenState extends State {
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double? _userLat;
  double? _userLng;

  final List _categories = [
    'Todos',
    'Talleres / Mecánica',
    'Grúas',
    'Baterías / Eléctricos',
    'Montallantas',
    'Cerrajería',
    'Abogados / Seguros',
  ];

  final List _realAllies = [
    {
      'id': 'royman_mecanica_sincelejo',
      'name': 'Royman - Mecánica Automotriz',
      'category': 'Talleres / Mecánica',
      'city': 'Sincelejo, Sucre',
      'description': 'Servicio especializado en mecánica automotriz general, diagnóstico y desvare en Sincelejo.',
      'phone': '573107304782',
      'lat': 9.3047,
      'lng': -75.3978,
      'activo': true,
    },
    {
      'id': 'neider_marin_mecanica_sincelejo',
      'name': 'Neider Marín - Mecánica Automotriz',
      'category': 'Talleres / Mecánica',
      'city': 'Sincelejo, Sucre',
      'description': 'Mecánica automotriz profesional, mantenimiento preventivo, sincronización y atención en vía.',
      'phone': '573044670715',
      'lat': 9.3025,
      'lng': -75.3960,
      'activo': true,
    },
  ];

  List _firestoreAllies = [];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _syncAlliesWithFirestore();
  }

  Future _syncAlliesWithFirestore() async {
    try {
      final col = FirebaseFirestore.instance.collection('aliados');
      final snap = await col.get().timeout(const Duration(seconds: 6));

      if (snap.docs.isEmpty) {
        for (final item in _realAllies) {
          final map = Map.from(item as Map);
          await col.doc(map['id'].toString()).set({
            ...map,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        final List loaded = [];
        for (final doc in snap.docs) {
          final map = Map.from(doc.data());
          if (map['activo'] != false) {
            loaded.add(map);
          }
        }
        if (mounted && loaded.isNotEmpty) {
          setState(() {
            _firestoreAllies = loaded;
          });
        }
      }
    } catch (_) {}
  }

  Future _loadUserLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 5));
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
    _searchController.dispose();
    super.dispose();
  }

  double? _calculateDistanceKm(Map ally) {
    try {
      final lat = double.tryParse(ally['lat']?.toString() ?? '');
      final lng = double.tryParse(ally['lng']?.toString() ?? '');
      if (_userLat == null || _userLng == null || lat == null || lng == null) {
        return null;
      }
      final meters = Geolocator.distanceBetween(_userLat!, _userLng!, lat, lng);
      return meters / 1000.0;
    } catch (_) {
      return null;
    }
  }

  Future _contactAlly(String rawPhone, String allyName, {bool whatsapp = false}) async {
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
      'Necesito asistencia mecánica.',
    );

    final Uri uri = whatsapp
        ? Uri.parse('https://wa.me/$digits?text=$msg')
        : Uri.parse('tel:+$digits');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List _getVisibleAllies() {
    final Map byId = {};
    for (final item in _realAllies) {
      final m = Map.from(item as Map);
      byId[m['id'].toString()] = m;
    }
    for (final item in _firestoreAllies) {
      final m = Map.from(item as Map);
      final key = (m['id'] ?? m['phone'] ?? m['name']).toString();
      byId[key] = m;
    }

    final list = byId.values.where((item) {
      final map = item as Map;
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

    list.sort((a, b) {
      final distA = _calculateDistanceKm(a as Map);
      final distB = _calculateDistanceKm(b as Map);
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visibleAllies = _getVisibleAllies();

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
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar taller, mecánico, ciudad o servicio...',
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
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index].toString();
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
          Expanded(
            child: visibleAllies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_mall_directory_outlined,
                              size: 54, color: Colors.black45),
                          const SizedBox(height: 10),
                          const Text(
                            'No hay aliados en esta categoría todavía.',
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: visibleAllies.length,
                    itemBuilder: (context, index) {
                      final ally = visibleAllies[index] as Map;
                      final String name =
                          (ally['name'] ?? ally['nombre'] ?? 'Aliado S.O.S. Auto').toString();
                      final String category =
                          (ally['category'] ?? ally['categoria'] ?? 'Talleres / Mecánica').toString();
                      final String city =
                          (ally['city'] ?? ally['ciudad'] ?? 'Sincelejo, Sucre').toString();
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
                                    child: Icon(Icons.build_circle, color: Color(0xFF1B5E20)),
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
                  ),
          ),
        ],
      ),
    );
  }
}
