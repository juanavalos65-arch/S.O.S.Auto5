import 'package:flutter/material.dart';

/// Repositorio en memoria compartible con el banner rotativo de HomeScreen
class NovedadesViaStore {
  static final List> novedadesActivas = [
    {
      'id': 'nov-1',
      'tipo': 'Cierre vial',
      'via': 'Autopista Norte • Sector Peaje',
      'detalle': 'Paso restringido a un carril por mantenimiento de calzada. Tomar vía alterna.',
      'hora': 'Hace 12 min',
      'confirmaciones': 14,
      'enBanner': true,
    },
    {
      'id': 'nov-2',
      'tipo': 'Accidente en vía',
      'via': 'Avenida Regional • Altura Puente Sur',
      'detalle': 'Choque simple entre dos vehículos en carril izquierdo, congestión moderada.',
      'hora': 'Hace 25 min',
      'confirmaciones': 9,
      'enBanner': true,
    },
    {
      'id': 'nov-3',
      'tipo': 'Derrumbe / Obra',
      'via': 'Troncal de Occidente • Km 18',
      'detalle': 'Caída de material sobre la berma y lluvia fuerte. Conducir con precaución.',
      'hora': 'Hace 40 min',
      'confirmaciones': 21,
      'enBanner': true,
    },
  ];
}

class ReportIncidentScreen extends StatefulWidget {
  final String? ciudadActual;

  const ReportIncidentScreen({
    super.key,
    this.ciudadActual,
  });

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _viaSectorCtrl = TextEditingController();
  final TextEditingController _observacionesCtrl = TextEditingController();

  String _filtroCategoria = 'Todas';
  String _tipoNovedadSeleccionada = 'Cierre vial';
  bool _publicarEnBanner = true;

  final List> _tiposNovedad = [
    {
      'titulo': 'Cierre vial',
      'icono': Icons.block,
      'color': const Color(0xFFC62828),
    },
    {
      'titulo': 'Accidente en vía',
      'icono': Icons.car_crash,
      'color': const Color(0xFFD84315),
    },
    {
      'titulo': 'Derrumbe / Obra',
      'icono': Icons.landslide,
      'color': const Color(0xFFEF6C00),
    },
    {
      'titulo': 'Retén / Control',
      'icono': Icons.local_police,
      'color': const Color(0xFF1565C0),
    },
    {
      'titulo': 'Vía mojada / Peligro',
      'icono': Icons.warning_amber_rounded,
      'color': const Color(0xFF6A1B9A),
    },
    {
      'titulo': 'Congestión fuerte',
      'icono': Icons.traffic,
      'color': const Color(0xFF2E7D32),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viaSectorCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Color _colorPorTipo(String tipo) {
    final encontrado = _tiposNovedad.firstWhere(
      (t) => t['titulo'] == tipo,
      orElse: () => {'color': const Color(0xFF283593)},
    );
    return encontrado['color'] as Color;
  }

  IconData _iconoPorTipo(String tipo) {
    final encontrado = _tiposNovedad.firstWhere(
      (t) => t['titulo'] == tipo,
      orElse: () => {'icono': Icons.alt_route},
    );
    return encontrado['icono'] as IconData;
  }

  List> get _novedadesFiltradas {
    if (_filtroCategoria == 'Todas') {
      return NovedadesViaStore.novedadesActivas;
    }
    return NovedadesViaStore.novedadesActivas
        .where((n) => n['tipo'] == _filtroCategoria)
        .toList();
  }

  void _confirmarVigencia(Map<String, dynamic> novedad) {
    setState(() {
      novedad['confirmaciones'] = (novedad['confirmaciones'] as int) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gracias: confirmaste que esta novedad sigue activa en el banner.'),
        backgroundColor: Color(0xFF283593),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _marcarViaDespejada(Map<String, dynamic> novedad) {
    setState(() {
      NovedadesViaStore.novedadesActivas.removeWhere((item) => item['id'] == novedad['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Novedad marcada como despejada y retirada del banner.'),
        backgroundColor: Color(0xFF0B6E4F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _enviarReporteNovedad() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor indica la vía o sector de la novedad.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final nuevaNovedad = <String, dynamic>{
      'id': 'nov-${DateTime.now().millisecondsSinceEpoch}',
      'tipo': _tipoNovedadSeleccionada,
      'via': _viaSectorCtrl.text.trim(),
      'detalle': _observacionesCtrl.text.trim().isEmpty
          ? 'Reporte comunitario activo. Conducir con precaución.'
          : _observacionesCtrl.text.trim(),
      'hora': 'Justo ahora',
      'confirmaciones': 1,
      'enBanner': _publicarEnBanner,
    };

    setState(() {
      NovedadesViaStore.novedadesActivas.insert(0, nuevaNovedad);
      _filtroCategoria = 'Todas';
      _viaSectorCtrl.clear();
      _observacionesCtrl.clear();
    });

    // Cambia automáticamente a la pestaña "Conocer novedades" para verla publicada
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _publicarEnBanner
              ? '¡Novedad publicada en la red y activada en el BANNER superior!'
              : '¡Novedad registrada en la lista de alertas viales!',
        ),
        backgroundColor: const Color(0xFF0B6E4F),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.alt_route, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Novedades en la vía',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.campaign_outlined, size: 20),
              text: 'Conocer novedades (${NovedadesViaStore.novedadesActivas.length})',
            ),
            const Tab(
              icon: Icon(Icons.add_alert_outlined, size: 20),
              text: 'Reportar novedad',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSeccionConocerNovedades(),
            _buildSeccionReportarNovedad(),
          ],
        ),
      ),
    );
  }

  /// =========================================================================
  /// SECCIÓN 1: CONOCER LAS NOVEDADES EN LA VÍA (Y SU ESTADO EN EL BANNER)
  /// =========================================================================
  Widget _buildSeccionConocerNovedades() {
    final lista = _novedadesFiltradas;

    return Column(
      children: [
        // Aviso de sincronización con el banner rotativo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFFE8EAF6),
          child: Row(
            children: [
              const Icon(Icons.view_carousel, color: Color(0xFF283593), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Estas novedades rotan en vivo en el banner superior de S.O.S. Auto para alertar a todos los conductores.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF1A237E)),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text(
                  '+ Reportar',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283593)),
                ),
              ),
            ],
          ),
        ),

        // Filtros horizontales por categoría
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chipFiltro('Todas'),
              ..._tiposNovedad.map((t) => _chipFiltro(t['titulo'] as String)),
            ],
          ),
        ),

        // Listado de novedades activas
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF0B6E4F)),
                        const SizedBox(height: 10),
                        const Text(
                          'No hay novedades reportadas en esta categoría.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF283593),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_alert),
                          label: const Text('REPORTAR UNA NOVEDAD AHORA'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final nov = lista[index];
                    final String tipo = nov['tipo'] as String;
                    final Color colorTipo = _colorPorTipo(tipo);
                    final bool enBanner = nov['enBanner'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorTipo.withOpacity(0.45), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorTipo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_iconoPorTipo(tipo), color: Colors.white, size: 15),
                                    const SizedBox(width: 5),
                                    Text(
                                      tipo.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (enBanner)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade700),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.campaign, size: 13, color: Colors.amber),
                                      SizedBox(width: 3),
                                      Text(
                                        'EN BANNER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4E342E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nov['via'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nov['detalle'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Colors.black87,
                              height: 1.32,
                            ),
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${nov['hora']} • ${nov['confirmaciones']} conf.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _confirmarVigencia(nov),
                                icon: const Icon(Icons.thumb_up_alt_outlined, size: 15),
                                label: const Text('Sigue ahí', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton.icon(
                                onPressed: () => _marcarViaDespejada(nov),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0B6E4F),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 15),
                                label: const Text('Despejada', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chipFiltro(String titulo) {
    final bool activo = _filtroCategoria == titulo;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(titulo),
        selected: activo,
        selectedColor: const Color(0xFF283593),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: activo ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _filtroCategoria = titulo),
      ),
    );
  }

  /// =========================================================================
  /// SECCIÓN 2: REPORTAR UNA NOVEDAD EN LA VÍA Y PUBLICAR EN EL BANNER
  /// =========================================================================
  Widget _buildSeccionReportarNovedad() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC5CAE9)),
              ),
              child: const Text(
                'Reporta retenes, accidentes, cierres viales o peligros en la vía para alertar a la red de conductores y publicarlo en el banner dinámico.',
                style: TextStyle(fontSize: 14, color: Color(0xFF1A237E), height: 1.35),
              ),
            ),
            const SizedBox(height: 16),

            // Selector rápido de Tipo de Novedad
            const Text(
              '1. Tipo de novedad *',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tiposNovedad.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = _tiposNovedad[index];
                final String titulo = item['titulo'] as String;
                final Color color = item['color'] as Color;
                final bool seleccionado = _tipoNovedadSeleccionada == titulo;

                return InkWell(
                  onTap: () => setState(() => _tipoNovedadSeleccionada = titulo),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: seleccionado ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado ? color : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icono'] as IconData,
                          size: 20,
                          color: seleccionado ? Colors.white : color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: seleccionado ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Campo obligatorio: Vía o sector
            TextFormField(
              controller: _viaSectorCtrl,
              decoration: InputDecoration(
                labelText: 'Vía o sector de la novedad *',
                hintText: 'Ej. Troncal de Occidente km 12, Calle 30 con Carrera 20...',
                prefixIcon: const Icon(Icons.add_location_alt, color: Color(0xFF283593)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio: indica la vía o sector' : null,
            ),
            const SizedBox(height: 14),

            // Observaciones adicionales
            TextFormField(
              controller: _observacionesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observaciones adicionales y rutas alternas',
                hintText: 'Describe qué ocurre, carril cerrado o desvíos recomendados...',
                prefixIcon: const Icon(Icons.notes, color: Color(0xFF283593)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Interruptor de publicación en el Banner dinámico
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                value: _publicarEnBanner,
                activeColor: const Color(0xFF283593),
                title: const Text(
                  'Publicar en el banner superior',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Muestra esta alerta en el carrusel rotativo para conductores cercanos.',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _publicarEnBanner = val),
              ),
            ),
            const SizedBox(height: 20),

            // Botón enviar reporte
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _enviarReporteNovedad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283593),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'ENVIAR REPORTE Y PUBLICAR EN BANNER',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
