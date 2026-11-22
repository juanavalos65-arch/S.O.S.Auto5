import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_vehicle_screen.dart';
import 'paute_aqui_screen.dart';
import 'me_vare_screen.dart';
import 'accidente_screen.dart';
import 'estoy_en_peligro_screen.dart';
import 'agente_transito_screen.dart';
import 'stolen_car_screen.dart';
import 'repot_incident_screen.dart';
import 'camera_background_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _inicialController = TextEditingController(text: 'Mi ubicación actual');
  final TextEditingController _destinoController = TextEditingController();

  LatLng _currentPosition = const LatLng(6.2442, -75.5812);
  bool _hasGpsFix = false;

  LatLng? _origenElegido;
  LatLng? _destino;
  List<LatLng> _rutaPuntos = [];
  bool _calculandoRuta = false;
  String _infoRuta = '';
  bool _modoElegirDestino = false;
  bool _modoElegirInicial = false;

  List<Map<String, dynamic>> _sugerenciasInicial = [];
  List<Map<String, dynamic>> _sugerenciasDestino = [];

  @override
  void initState() {
    super.initState();
    _locateUser();
  }

  Future<void> _locateUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() { _currentPosition = userLatLng; _hasGpsFix = true; _origenElegido = userLatLng; });
        _mapController.move(userLatLng, 15.5);
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _buscarLugares(String texto) async {
    if (texto.length < 3) return [];
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=$texto&format=json&limit=5&countrycodes=co';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'sosauto-app'});
      final List data = jsonDecode(resp.body);
      return data.map((e) => {'nombre': e['display_name'] as String, 'lat': double.parse(e['lat']), 'lng': double.parse(e['lon'])}).toList();
    } catch (_) { return []; }
  }

  void _onCambioInicial(String texto) async {
    if (texto == 'Mi ubicación actual') { setState(() { _origenElegido = _currentPosition; _sugerenciasInicial = []; }); return; }
    final res = await _buscarLugares(texto);
    setState(() => _sugerenciasInicial = res);
  }

  void _onCambioDestino(String texto) async {
    final res = await _buscarLugares(texto);
    setState(() => _sugerenciasDestino = res);
  }

  void _seleccionarInicial(Map<String, dynamic> lugar) {
    FocusScope.of(context).unfocus();
    setState(() {
      _origenElegido = LatLng(lugar['lat'], lugar['lng']);
      _inicialController.text = lugar['nombre'].split(',').first;
      _sugerenciasInicial = [];
    });
  }

  void _seleccionarDestino(Map<String, dynamic> lugar) {
    FocusScope.of(context).unfocus();
    setState(() {
      _destino = LatLng(lugar['lat'], lugar['lng']);
      _destinoController.text = lugar['nombre'].split(',').first;
      _sugerenciasDestino = [];
    });
  }

  void _usarMiUbicacionComoInicial() {
    setState(() { _origenElegido = _currentPosition; _inicialController.text = 'Mi ubicación actual'; _sugerenciasInicial = []; });
  }

  void _intercambiar() {
    setState(() {
      final tempTexto = _inicialController.text;
      final tempPunto = _origenElegido;
      _inicialController.text = _destinoController.text;
      _destinoController.text = tempTexto;
      _origenElegido = _destino;
      _destino = tempPunto;
    });
  }

  void _onTapMapa(TapPosition _, LatLng punto) {
    if (_modoElegirInicial) {
      setState(() { _origenElegido = punto; _inicialController.text = 'Punto en el mapa'; _modoElegirInicial = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Punto inicial listo, ahora elige tu destino'), backgroundColor: Colors.green));
      return;
    }
    if (_modoElegirDestino) {
      setState(() { _destino = punto; _destinoController.text = 'Punto en el mapa'; _modoElegirDestino = false; });
      return;
    }
  }

  Future<void> _buscarRuta() async {
    FocusScope.of(context).unfocus();
    setState(() { _sugerenciasInicial = []; _sugerenciasDestino = []; });

    if (_destino == null || _destinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Primero escribe o elige tu destino'), backgroundColor: Colors.orange));
      return;
    }
    final LatLng origen = _origenElegido ?? _currentPosition;
    setState(() { _calculandoRuta = true; _infoRuta = 'Buscando tu ruta...'; });
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${origen.longitude},${origen.latitude};${_destino!.longitude},${_destino!.latitude}?overview=full&geometries=geojson';
      final resp = await http.get(Uri.parse(url));
      final data = jsonDecode(resp.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      final puntos = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
      final double distanciaKm = (data['routes'][0]['distance'] as num).toDouble() / 1000;
      final double durMin = (data['routes'][0]['duration'] as num).toDouble() / 60;
      setState(() { _rutaPuntos = puntos; _calculandoRuta = false; _infoRuta = '✅ Ruta lista: ${distanciaKm.toStringAsFixed(1)} km - ${durMin.toInt()} min - Te avisaremos de cámaras en esta ruta'; });
      setRutaActual(puntos);
      await FirebaseFirestore.instance.collection('ruta_activa').doc('actual').set({
        'puntos': puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'actualizado': FieldValue.serverTimestamp(),
      });
      _mapController.move(origen, 13.5);
    } catch (e) {
      setState(() { _calculandoRuta = false; _infoRuta = 'No se pudo encontrar ruta, intenta de nuevo'; });
    }
  }

  void _limpiarRuta() {
    setState(() {
      _destino = null; _rutaPuntos = []; _infoRuta = ''; _destinoController.clear();
      _inicialController.text = 'Mi ubicación actual'; _origenElegido = _currentPosition;
    });
    setRutaActual([]);
    FirebaseFirestore.instance.collection('ruta_activa').doc('actual').delete();
  }

  void _abrirPantalla(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _handleAction(String actionId) {
    switch (actionId) {
      case 'register': _abrirPantalla(const RegisterVehicleScreen()); break;
      case 'paute_aqui': _abrirPantalla(const PauteAquiScreen()); break;
      case 'me_vare': _abrirPantalla(const MeVareScreen()); break;
      case 'accident': _abrirPantalla(const AccidenteScreen()); break;
      case 'danger': _abrirPantalla(const EstoyEnPeligroScreen()); break;
      case 'traffic_stop': _abrirPantalla(const AgenteTransitoScreen()); break;
      case 'stolen_car': _abrirPantalla(const StolenCarScreen()); break;
      case 'traffic_news': _abrirPantalla(const ReportIncidentScreen()); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool sinRuta = _rutaPuntos.isEmpty;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentPosition, initialZoom: 14.0, minZoom: 5.0, maxZoom: 18.0, onTap: _onTapMapa, onLongPress: (pos, punto) => _onTapMapa(pos, punto)),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ge.sosauto.app'),
              if (_rutaPuntos.isNotEmpty)
                PolylineLayer(polylines: [Polyline(points: _rutaPuntos, color: Colors.blue.shade700, strokeWidth: 6)]),
              MarkerLayer(
                markers: [
                  Marker(point: _currentPosition, width: 48, height: 48, child: Container(decoration: BoxDecoration(color: (_hasGpsFix ? Colors.red : Colors.blueGrey).withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.navigation, color: _hasGpsFix ? Colors.red.shade700 : Colors.blueGrey, size: 32))),
                  if (_origenElegido != null && _inicialController.text != 'Mi ubicación actual')
                    Marker(point: _origenElegido!, width: 48, height: 48, child: const Icon(Icons.flag, color: Colors.green, size: 40)),
                  if (_destino != null)
                    Marker(point: _destino!, width: 48, height: 48, child: const Icon(Icons.location_on, color: Colors.red, size: 44)),
                ],
              ),
            ],
          ),

          Positioned(
            top: 40, left: 16, right: 16,
            child: Column(
              children: [
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.security, color: Colors.redAccent, size: 28), SizedBox(width: 8), Text('S.O.S. Auto', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))]),
                const SizedBox(height: 10),

                // AVISO DE BUSCAR RUTA
                if (sinRuta)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)]),
                    child: const Row(
                      children: [
                        Icon(Icons.route, color: Colors.black, size: 22),
                        SizedBox(width: 8),
                        Expanded(child: Text('🔍 BUSCA TU RUTA para activar las alertas de cámaras en tu camino', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                if (sinRuta) const SizedBox(height: 8),

                // CAJA INICIAL Y DESTINO
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)]),
                  child: Column(
                    children: [
                      // INICIAL
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('Inicial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _inicialController,
                              onChanged: _onCambioInicial,
                              decoration: const InputDecoration(hintText: '¿Desde dónde sales?', border: InputBorder.none, isDense: true),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.gps_fixed, color: Colors.green, size: 20), onPressed: _usarMiUbicacionComoInicial, tooltip: 'Usar mi ubicación'),
                        ],
                      ),
                      const Divider(height: 8),
                      // DESTINO
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text('Destino:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _destinoController,
                              onChanged: _onCambioDestino,
                              decoration: const InputDecoration(hintText: '¿A dónde vas?', border: InputBorder.none, isDense: true),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.swap_vert, color: Colors.blue), onPressed: _intercambiar, tooltip: 'Intercambiar'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // BOTONES DE ELEGIR EN MAPA
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _modoElegirInicial = true; _modoElegirDestino = false; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👆 Toca en el mapa tu punto inicial'))); }, icon: const Icon(Icons.flag, size: 16), label: const Text('Elegir Inicial en mapa', style: TextStyle(fontSize: 11)))),
                          const SizedBox(width: 6),
                          Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _modoElegirDestino = true; _modoElegirInicial = false; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👆 Toca en el mapa tu destino'))); }, icon: const Icon(Icons.pin_drop, size: 16), label: const Text('Elegir Destino en mapa', style: TextStyle(fontSize: 11)))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // BOTON BUSCAR RUTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _calculandoRuta ? null : _buscarRuta,
                          icon: _calculandoRuta ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search, color: Colors.white),
                          label: Text(_calculandoRuta ? 'BUSCANDO RUTA...' : '🔍 BUSCAR RUTA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      if (_modoElegirInicial || _modoElegirDestino)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_modoElegirInicial ? '👆 Ahora toca en el mapa tu punto INICIAL' : '👆 Ahora toca en el mapa tu DESTINO', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
                  ),
                ),

                // SUGERENCIAS INICIAL
                if (_sugerenciasInicial.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: _sugerenciasInicial.map((s) => ListTile(leading: const Icon(Icons.flag, color: Colors.green), title: Text(s['nombre'].split(',').first, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(s['nombre'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)), onTap: () => _seleccionarInicial(s))).toList()),
                  ),
                // SUGERENCIAS DESTINO
                if (_sugerenciasDestino.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: _sugerenciasDestino.map((s) => ListTile(leading: const Icon(Icons.location_on, color: Colors.red), title: Text(s['nombre'].split(',').first, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(s['nombre'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)), onTap: () => _seleccionarDestino(s))).toList()),
                  ),

                if (_infoRuta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 20), const SizedBox(width: 8), Expanded(child: Text(_infoRuta, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))), InkWell(onTap: _limpiarRuta, child: const Icon(Icons.close, color: Colors.white, size: 18))]),
                  ),
                ],
              ],
            ),
          ),

          Positioned(right: 16, bottom: 185, child: FloatingActionButton.small(heroTag: 'btn_my_location_osm', backgroundColor: Colors.white, foregroundColor: Colors.red.shade700, onPressed: _locateUser, child: const Icon(Icons.my_location))),
          Positioned(
            bottom: 20, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]),
              child: GridView.count(
                crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 6.0, crossAxisSpacing: 6.0, childAspectRatio: 1.0,
                children: [
                  _buildEmergencyButton(icon: Icons.person_add, label: 'Regístrese', color: Colors.blue, onTap: () => _handleAction('register')),
                  _buildEmergencyButton(icon: Icons.campaign, label: 'Paute Aquí', color: Colors.amber, onTap: () => _handleAction('paute_aqui')),
                  _buildEmergencyButton(icon: Icons.car_repair, label: 'Me Varé', color: Colors.orange, onTap: () => _handleAction('me_vare')),
                  _buildEmergencyButton(icon: Icons.car_crash, label: 'Accidente', color: Colors.red, onTap: () => _handleAction('accident')),
                  _buildEmergencyButton(icon: Icons.warning, label: 'Peligro', color: Colors.deepOrange, onTap: () => _handleAction('danger')),
                  _buildEmergencyButton(icon: Icons.local_police, label: 'Tránsito', color: Colors.indigo, onTap: () => _handleAction('traffic_stop')),
                  _buildEmergencyButton(icon: Icons.local_shipping, label: 'Robo Auto', color: Colors.redAccent, onTap: () => _handleAction('stolen_car')),
                  _buildEmergencyButton(icon: Icons.announcement, label: 'Novedades', color: Colors.teal, onTap: () => _handleAction('traffic_news')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(10),
      child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 22, color: color), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.black87))])),
    );
  }
}
