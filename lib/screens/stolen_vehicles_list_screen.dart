import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StolenVehiclesListScreen extends StatefulWidget {
  const StolenVehiclesListScreen({super.key});

  @override
  State<StolenVehiclesListScreen> createState() => _StolenVehiclesListScreenState();
}

class _StolenVehiclesListScreenState extends State<StolenVehiclesListScreen> {
  String _filtroPlaca = '';

  Future<void> _abrirMapa(String url) async {
    if (!url.startsWith('http')) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _llamar123() async {
    final uri = Uri.parse('tel:123');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.folder_special, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vehículos Reportados Robados',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            color: Colors.white,
            child: TextField(
              textCapitalization: TextCapitalization.characters,
              onChanged: (val) => setState(() => _filtroPlaca = val.trim().toUpperCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por placa o ciudad (ej. HXU874)...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB71C1C)),
                filled: true,
                fillColor: const Color(0xFFF6F7F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehiculos_robados')
                  .where('activa', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay alertas activas de vehículos robados en este momento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (_filtroPlaca.isEmpty) return true;
                  final d = doc.data() as Map<String, dynamic>;
                  final placa = (d['placa'] ?? '').toString().toUpperCase();
                  final ciudad = (d['ciudad'] ?? '').toString().toUpperCase();
                  return placa.contains(_filtroPlaca) || ciudad.contains(_filtroPlaca);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron vehículos con ese filtro.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final placa = (d['placa'] ?? 'SIN PLACA').toString().toUpperCase();
                    final tipo = (d['tipoVehiculo'] ?? 'Vehículo').toString();
                    final detalle = (d['detalleVehiculo'] ?? '').toString();
                    final ciudad = (d['ciudad'] ?? 'Colombia').toString();
                    final modalidad = (d['modalidad'] ?? '').toString().toUpperCase();
                    final huida = (d['detalleHuida'] ?? '').toString();
                    final mapsUrl = (d['mapsUrl'] ?? '').toString();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black87, width: 1.4),
                                  ),
                                  child: Text(
                                    placa,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: 1.2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tipo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        detalle,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Text(
                              '📍 Ciudad: $ciudad ${modalidad.isNotEmpty ? '• Modalidad: $modalidad' : ''}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (huida.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '🧭 Ruta/Detalles: $huida',
                                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (mapsUrl.startsWith('http'))
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _abrirMapa(mapsUrl),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFB71C1C),
                                        side: const BorderSide(color: Color(0xFFB71C1C)),
                                      ),
                                      icon: const Icon(Icons.location_on, size: 18),
                                      label: const Text('VER UBICACIÓN'),
                                    ),
                                  ),
                                if (mapsUrl.startsWith('http')) const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _llamar123,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB71C1C),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.call, size: 18),
                                    label: const Text('AVISAR AL 123'),
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
    );
  }
}
