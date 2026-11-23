import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tiposNovedad = [
    'Vía cerrada / Obra / Derrumbe',
    'Congestión vehicular fuerte',
    'Inundación / Árbol caído',
    'Hueco peligroso / Mancha de aceite',
    'Accidente en la vía (Tráfico lento)',
    'Puesto de control / Retén',
    'Cámara de fotodetección / Radar',
    'Manifestación / Bloqueo vial',
    'Otra novedad vial',
  ];

  final List<String> _estadosPaso = [
    'Paso restringido (1 carril)',
    'Vía totalmente cerrada',
    'Tráfico lento / Precaución',
    'Paso normal con alerta',
  ];

  String _tipoSeleccionado = 'Vía cerrada / Obra / Derrumbe';
  String _estadoSeleccionado = 'Paso restringido (1 carril)';
  final TextEditingController _sectorController = TextEditingController();
  final TextEditingController _detalleController = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sectorController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  /// Calcula la duración de vigencia según el tipo de novedad
  Duration? _obtenerDuracionNovedad(String tipo) {
    if (tipo.contains('fotodetección') || tipo.contains('Radar')) {
      return null; // Permanente
    }
    if (tipo.contains('Accidente') ||
        tipo.contains('Congestión') ||
        tipo.contains('Retén')) {
      return const Duration(hours: 3);
    }
    if (tipo.contains('Vía cerrada') ||
        tipo.contains('Derrumbe') ||
        tipo.contains('Inundación')) {
      return const Duration(hours: 24);
    }
    return const Duration(hours: 12); // Hueco, manifestación u otra novedad
  }

  Future<Position?> _obtenerUbicacionSegura() async {
    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _publicarNovedad() async {
    final sector = _sectorController.text.trim();
    final detalle = _detalleController.text.trim();

    // Si elige "Otra novedad vial", exigir que escriba cuál es
    if (_tipoSeleccionado == 'Otra novedad vial' && detalle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe cuál es la novedad en el campo de detalle.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final posicion = await _obtenerUbicacionSegura();
      final ahora = DateTime.now();
      final duracion = _obtenerDuracionNovedad(_tipoSeleccionado);
      final bool esPermanente = duracion == null;
      final DateTime? fechaExpiracion =
          esPermanente ? null : ahora.add(duracion);

      final String tituloFinal = _tipoSeleccionado == 'Otra novedad vial'
          ? 'Novedad vial: $detalle'
          : _tipoSeleccionado;

      await FirebaseFirestore.instance.collection('novedades_viales').add({
        'tipo': tituloFinal,
        'categoriaBase': _tipoSeleccionado,
        'estadoPaso': _estadoSeleccionado,
        'sector': sector,
        'detalle': detalle,
        'lat': posicion?.latitude,
        'lng': posicion?.longitude,
        'activo': true,
        'esPermanente': esPermanente,
        'creadaEn': FieldValue.serverTimestamp(),
        'expiraEn': fechaExpiracion != null
            ? Timestamp.fromDate(fechaExpiracion)
            : null,
        'confirmaciones': 1,
        'reportesYaPaso': 0,
      });

      if (!mounted) return;
      _sectorController.clear();
      _detalleController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esPermanente
                ? 'Cámara de fotodetección guardada de forma permanente en el mapa.'
                : 'Novedad publicada en el banner y mapa (activa por ${duracion.inHours}h).',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // Cambiar automáticamente a la pestaña "Conocer novedades" para verla publicada
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar novedad: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esOtraNovedad = _tipoSeleccionado == 'Otra novedad vial';
    final Duration? duracionActual = _obtenerDuracionNovedad(_tipoSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novedades en la Vía',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF6C00),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_alert), text: 'Reportar novedad'),
            Tab(icon: Icon(Icons.list_alt), text: 'Conocer novedades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: REPORTAR NOVEDAD
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tipo de novedad vial:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _tipoSeleccionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  items: _tiposNovedad.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(
                        tipo,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() => _tipoSeleccionado = valor);
                    }
                  },
                ),
                const SizedBox(height: 6),
                // Etiqueta informativa de cuánto durará activa la novedad
                Row(
                  children: [
                    Icon(
                      duracionActual == null ? Icons.all_inclusive : Icons.timer_outlined,
                      size: 16,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duracionActual == null
                          ? 'Vigencia: Permanente en el mapa'
                          : 'Vigencia automática: ${duracionActual.inHours} horas',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estado del paso vehicular:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  items: _estadosPaso.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() => _estadoSeleccionado = valor);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sectorController,
                  decoration: InputDecoration(
                    labelText: 'Sector, vía o kilómetro (opcional)',
                    hintText: 'Ej: Troncal de Occidente km 12 / Av. Las Palmas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _detalleController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: esOtraNovedad
                        ? 'Describe la novedad vial (obligatorio) *'
                        : 'Detalle adicional para otros conductores (opcional)',
                    hintText: esOtraNovedad
                        ? 'Ej: Ganado suelto en la vía, semáforo dañado, neblina...'
                        : 'Ej: Tomar vía alterna, cámara en sentido norte-sur...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _enviando ? null : _publicarNovedad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.campaign),
                  label: Text(
                    _enviando ? 'PUBLICANDO...' : 'PUBLICAR EN BANNER Y MAPA',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PESTAÑA 2: CONOCER NOVEDADES EN TIEMPO REAL
          _ListaNovedadesVigentes(),
        ],
      ),
    );
  }
}

class _ListaNovedadesVigentes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('novedades_viales')
          .orderBy('creadaEn', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ahora = DateTime.now();
        final docsVigentes = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['activo'] == false) return false;
          final bool esPermanente = data['esPermanente'] ?? false;
          if (esPermanente) return true;
          final Timestamp? expiraTs = data['expiraEn'] as Timestamp?;
          if (expiraTs != null && expiraTs.toDate().isBefore(ahora)) {
            return false;
          }
          return true;
        }).toList();

        if (docsVigentes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay novedades viales activas en este momento.\n¡Buen viaje!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docsVigentes.length,
          itemBuilder: (context, index) {
            final data = doc.data() as Map<String, dynamic>;

            final data = doc.data();
            final bool esPermanente = data['esPermanente'] ?? false;
            final String tipo = data['tipo'] ?? 'Novedad vial';
            final String estado = data['estadoPaso'] ?? '';
            final String sector = data['sector'] ?? '';
            final String detalle = data['detalle'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          esPermanente
                              ? Icons.speed
                              : Icons.warning_amber_rounded,
                          color: esPermanente
                              ? Colors.red.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tipo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: esPermanente
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            esPermanente ? 'Fija' : 'Temporal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: esPermanente
                                  ? Colors.red.shade800
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (estado.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Estado: $estado',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                    if (sector.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Sector: $sector'),
                    ],
                    if (detalle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(detalle,
                          style: const TextStyle(color: Colors.black87)),
                    ],
                    if (!esPermanente) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await doc.reference.update({
                                'activo': false,
                              });
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18, color: Colors.green),
                            label: const Text(
                              'Ya se despejó',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
