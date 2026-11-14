import 'package:flutter/material.dart';
import '../services/road_news_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Vía cerrada';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  final List> _categories = [
    {'label': 'Vía cerrada', 'icon': Icons.block, 'color': Colors.red},
    {'label': 'Derrumbe', 'icon': Icons.landslide, 'color': Colors.brown},
    {'label': 'Aceite / Derrame', 'icon': Icons.oil_barrel, 'color': Colors.deepOrange},
    {'label': 'Vía mojada', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'label': 'Hueco / Obstáculo', 'icon': Icons.warning_amber_rounded, 'color': Colors.amber},
    {'label': 'Tráfico / Retén', 'icon': Icons.traffic, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    final newIncident = RoadIncident(
      id: 'INC-${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Reporte comunitario activo en ruta.'
          : _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      reportedAt: DateTime.now(),
      reporterPlate: _plateController.text.trim().isEmpty
          ? 'COMUNIDAD'
          : _plateController.text.trim().toUpperCase(),
    );

    // Publica la novedad y actualiza automáticamente el Banner Dinámico
    RoadNewsService.instance.addIncident(newIncident);

    _titleController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _plateController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Novedad publicada y enviada al Banner Dinámico en tiempo real.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Cambia automáticamente a la pestaña de consulta para ver el reporte publicado
    _tabController.animateTo(0);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  IconData _getCategoryIcon(String category) {
    final found = _categories.firstWhere(
      (c) => c['label'] == category,
      orElse: () => {'icon': Icons.warning_amber_rounded},
    );
    return found['icon'] as IconData;
  }

  Color _getCategoryColor(String category) {
    final found = _categories.firstWhere(
      (c) => c['label'] == category,
      orElse: () => {'color': Colors.amber},
    );
    return found['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novedades en la Vía',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.campaign),
              text: 'Conocer Novedades',
            ),
            Tab(
              icon: Icon(Icons.add_alert),
              text: 'Reportar Novedad',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsListTab(),
          _buildReportFormTab(),
        ],
      ),
    );
  }

  /// Pestaña 1: Conocer las novedades activas (conectadas con el Banner Dinámico)
  Widget _buildNewsListTab() {
    return AnimatedBuilder(
      animation: RoadNewsService.instance,
      builder: (context, _) {
        final incidents = RoadNewsService.instance.activeIncidents;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.sync, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sincronizado con el Banner Dinámico (${incidents.length} novedades activas)',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: incidents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green.shade600),
                            const SizedBox(height: 12),
                            const Text(
                              '¡Vías despejadas!',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'No hay novedades reportadas en este momento. Si ves algún incidente, repórtalo para alertar en el banner.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: incidents.length,
                      itemBuilder: (context, index) {
                        final item = incidents[index];
                        final catColor = _getCategoryColor(item.category);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: catColor.withOpacity(0.4)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: catColor.withOpacity(0.15),
                                      child: Icon(_getCategoryIcon(item.category),
                                          color: catColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.category.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(item.reportedAt),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.redAccent),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.location,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Reportado por: ${item.reporterPlate}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        RoadNewsService.instance
                                            .markAsResolved(item.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '✔️ Novedad marcada como resuelta y retirada del banner.'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check_circle,
                                          size: 18, color: Colors.green),
                                      label: const Text(
                                        'Problema Resuelto',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  /// Pestaña 2: Formulario para reportar una nueva novedad hacia el Banner Dinámico
  Widget _buildReportFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona el tipo de novedad:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final label = cat['label'] as String;
                final isSelected = _selectedCategory == label;
                final color = cat['color'] as Color;

                return ChoiceChip(
                  avatar: Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = label);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título breve de la novedad *',
                hintText: 'Ej: Derrumbe en un carril / Semáforo dañado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación / Vía / Kilómetro *',
                hintText: 'Ej: Vía Sincelejo - Tolú Km 8',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Indica el punto o referencia vial'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalles adicionales (opcional)',
                hintText: 'Recomendaciones para otros conductores...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Tu placa (opcional)',
                hintText: 'Ej: HXU874',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.send),
              label: const Text(
                'PUBLICAR EN BANNER Y RED VIAL',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
