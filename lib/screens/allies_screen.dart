import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'paute_aqui_screen.dart';

class _AllyItem {
  final String nombre;
  final String categoria;
  final String descripcion;
  final String ubicacion;
  final String telefono;
  final String badge;

  const _AllyItem({
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.ubicacion,
    required this.telefono,
    required this.badge,
  });
}

class AlliesScreen extends StatefulWidget {
  const AlliesScreen({super.key});

  @override
  State<AlliesScreen> createState() => _AlliesScreenState();
}

class _AlliesScreenState extends State<AlliesScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  final List<String> _categories = const [
    'Todos',
    'Grúas 24/7',
    'Talleres / Mecánica',
    'Montallantas / Baterías',
    'Abogados Tránsito',
    'Repuestos',
  ];

  final List<_AllyItem> _allies = const [
    _AllyItem(
      nombre: 'Grúas Express S.O.S. 24 Horas',
      categoria: 'Grúas 24/7',
      descripcion: 'Servicio de plataforma y rescate vehicular urbano y en carretera.',
      ubicacion: 'Medellín / Área Metropolitana y Vías Nacionales',
      telefono: '573116479280',
      badge: 'ALIADO DESTACADO',
    ),
    _AllyItem(
      nombre: 'Serviteca & Baterías El Camino',
      categoria: 'Montallantas / Baterías',
      descripcion: 'Despinche móvil, cambio de baterías a domicilio y alineación.',
      ubicacion: 'Sincelejo / Costa Caribe',
      telefono: '573116479280',
      badge: 'ALIADO VERIFICADO',
    ),
    _AllyItem(
      nombre: 'Taller Automotriz Integral Bosch Car',
      categoria: 'Talleres / Mecánica',
      descripcion: 'Escáner electrónico, frenos, sincronización y mecánica rápida.',
      ubicacion: 'Medellín - Sector Laureles / La América',
      telefono: '573116479280',
      badge: 'ALIADO VERIFICADO',
    ),
    _AllyItem(
      nombre: 'Defensa Vial Colombia - Abogados',
      categoria: 'Abogados Tránsito',
      descripcion: 'Impugnación de comparendos, fotomultas y audiencias de tránsito.',
      ubicacion: 'Atención Virtual Nacional',
      telefono: '573116479280',
      badge: 'ALIADO DESTACADO',
    ),
    _AllyItem(
      nombre: 'Autopartes y Repuestos La 33',
      categoria: 'Repuestos',
      descripcion: 'Repuestos originales y homologados con envío rápido al sitio de varada.',
      ubicacion: 'Medellín y envíos nacionales',
      telefono: '573116479280',
      badge: 'ALIADO VERIFICADO',
    ),
  ];

  Future<void> _openWhatsApp(_AllyItem ally) async {
    final String msg = Uri.encodeComponent(
      'Hola ${ally.nombre}, los encontré en el Directorio de Aliados de la app S.O.S. Auto. '
      'Necesito información sobre sus servicios de ${ally.categoria}.',
    );
    final Uri uri = Uri.parse('https://wa.me/${ally.telefono}?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callAlly(String phone) async {
    final Uri uri = Uri.parse('tel:+$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_AllyItem> filteredAllies = _allies.where((ally) {
      final bool matchesCategory =
          _selectedCategory == 'Todos' || ally.categoria == _selectedCategory;
      final String q = _searchQuery.toLowerCase();
      final bool matchesQuery = q.isEmpty ||
          ally.nombre.toLowerCase().contains(q) ||
          ally.descripcion.toLowerCase().contains(q) ||
          ally.ubicacion.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIRECTORIO DE ALIADOS'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar grúa, taller, batería, ciudad...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String category = _categories[index];
                final bool isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Colors.red.shade800,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                if (filteredAllies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No se encontraron aliados con ese criterio.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ...filteredAllies.map(
                    (ally) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ally.badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  ally.categoria,
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ally.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ally.descripcion,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 15, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ally.ubicacion,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _openWhatsApp(ally),
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('WhatsApp'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _callAlly(ally.telefono),
                                    icon: const Icon(Icons.phone, size: 18),
                                    label: const Text('Llamar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '¿Tienes taller, grúa o eres abogado?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aparece en este directorio y en el banner rotativo para miles de conductores.',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PauteAquiScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.campaign),
                        label: const Text(
                          'PAUTAR MI NEGOCIO AQUÍ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
