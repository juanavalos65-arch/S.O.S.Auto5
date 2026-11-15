import 'package:flutter/material.dart';

class MeVareScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? tipoVehiculoRegistrado;
  final String? detalleVehiculoRegistrado;
  final String? ciudadActual;

  const MeVareScreen({
    super.key,
    this.placaRegistrada,
    this.tipoVehiculoRegistrado,
    this.detalleVehiculoRegistrado,
    this.ciudadActual,
  });

  @override
  State<MeVareScreen> createState() => _MeVareScreenState();
}

class _MeVareScreenState extends State<MeVareScreen> {
  final TextEditingController _detalleAdicionalCtrl = TextEditingController();

  String _motivoSeleccionadoId = 'llanta';
  bool _reporteEnviado = false;

  String get _placaActiva =>
      (widget.placaRegistrada != null && widget.placaRegistrada!.trim().isNotEmpty)
          ? widget.placaRegistrada!.trim().toUpperCase()
          : 'VEHÍCULO REGISTRADO';

  String get _tipoActivo =>
      (widget.tipoVehiculoRegistrado != null && widget.tipoVehiculoRegistrado!.trim().isNotEmpty)
          ? widget.tipoVehiculoRegistrado!.trim()
          : 'Automóvil';

  String get _detalleActivo =>
      (widget.detalleVehiculoRegistrado != null &&
              widget.detalleVehiculoRegistrado!.trim().isNotEmpty)
          ? widget.detalleVehiculoRegistrado!.trim()
          : 'Datos cargados desde tu perfil S.O.S. Auto';

  String get _ubicacionActiva =>
      (widget.ciudadActual != null && widget.ciudadActual!.trim().isNotEmpty)
          ? widget.ciudadActual!.trim()
          : 'Tu ubicación GPS actual';

  // Catálogo de motivos, soluciones paso a paso y categoría de colaborador asociada
  final List _motivosVarada = [
    {
      'id': 'llanta',
      'titulo': 'Llanta',
      'icono': Icons.tire_repair,
      'categoriaColaborador': 'Montallantas y Llantas',
      'advertencia': 'Nunca cambies una llanta sobre el carril activo ni en terreno inclinado.',
      'soluciones': [
        'Asegura el freno de mano y coloca el cambio en Primera (mecánico) o P (automático).',
        'Afloja levemente las tuercas en cruz antes de levantar el vehículo con el gato.',
        'Ubica el gato únicamente en el punto de apoyo reforzado del chasis indicado por el fabricante.',
        'Coloca la llanta de repuesto, baja el vehículo y aprieta firmemente las tuercas en estrella.',
        'Si no tienes repuesto, cruceta o el birlo está aislado, contacta un montallantas móvil abajo.',
      ],
    },
    {
      'id': 'bateria',
      'titulo': 'Batería',
      'icono': Icons.battery_alert,
      'categoriaColaborador': 'Baterías y Electricidad',
      'advertencia': 'Evita chispas cerca de la batería; no conectes los cables invertidos.',
      'soluciones': [
        'Apaga luces, aire acondicionado, radio y cualquier accesorio eléctrico.',
        'Revisa si los bornes de la batería están flojos o sulfatados (polvo blanco/verdoso).',
        'Para iniciar con cables: conecta Rojo (+) a batería descargada, luego Rojo (+) a batería auxiliar; Negro (-) a batería auxiliar y Negro (-) a una pieza metálica del chasis del carro varado.',
        'Enciende el vehículo auxiliar 3 minutos y luego intenta dar arranque al tuyo.',
        'Si al soltar los cables el motor se apaga, puede ser falla del alternador: solicita asistencia.',
      ],
    },
    {
      'id': 'gasolina',
      'titulo': 'Gasolina',
      'icono': Icons.local_gas_station,
      'categoriaColaborador': 'Suministro Combustible / Grúa',
      'advertencia': 'Nunca transportes gasolina en envases plásticos improvisados sin tapa hermética.',
      'soluciones': [
        'No insistas dando arranque repetidamente: puedes descargar la batería o recalentar la bomba de combustible.',
        'Si el vehículo es diésel y se quedó totalmente seco, requerirá purgar el sistema de inyección antes de encender.',
        'Solicita un colaborador de auxilio vial cercano para suministro seguro de galón de combustible en tu punto GPS.',
      ],
    },
    {
      'id': 'frenos',
      'titulo': 'Frenos',
      'icono': Icons.disc_full,
      'categoriaColaborador': 'Grúas y Frenos',
      'advertencia': 'PELIGRO CRÍTICO: No conduzcas el vehículo si el pedal se va al fondo o está bloqueado.',
      'soluciones': [
        'Detén la marcha de inmediato usando caja (rebajando cambios) y freno de mano de forma progresiva.',
        'Verifica visualmente si hay fuga de líquido debajo de las ruedas o bajo el depósito del capó.',
        'Si sientes olor a quemado en una rueda, espera 20 minutos a que enfríe; no eches agua fría sobre los discos calientes.',
        'Por seguridad vial, este caso requiere traslado en grúa cama baja hasta un taller especializado.',
      ],
    },
    {
      'id': 'motor',
      'titulo': 'Motor no enciende',
      'icono': Icons.engineering,
      'categoriaColaborador': 'Mecánica / Carro-Taller',
      'advertencia': 'Si escuchas golpes metálicos fuertes o ves humo, no vuelvas a intentar encenderlo.',
      'soluciones': [
        'En carros automáticos, verifica que la palanca esté exactamente en P (Parking) o N (Neutro).',
        'En carros mecánicos, pisa a fondo el pedal del embrague (clutch) al girar la llave o pulsar el botón Start.',
        'Verifica si el testigo de llave/inmovilizador parpadea en el tablero (prueba con la llave de repuesto o acerca la llave al botón de encendido).',
        'Revisa que no se haya disparado el interruptor de corte de combustible tras un golpe o bache fuerte.',
        'Solicita diagnóstico con escáner en sitio a uno de los talleres colaboradores.',
      ],
    },
    {
      'id': 'temperatura',
      'titulo': 'Recalentamiento',
      'icono': Icons.thermostat,
      'categoriaColaborador': 'Mecánica / Grúas',
      'advertencia': '¡NUNCA abras la tapa del radiador con el motor caliente! El vapor a presión causa quemaduras graves.',
      'soluciones': [
        'Oríllate de inmediato y apaga el motor; deja el capó entreabierto para disipar calor.',
        'Espera al menos 30 a 45 minutos hasta que la aguja de temperatura baje por completo.',
        'Revisa el nivel del tanque auxiliar (vaso de expansión) sin abrir el radiador; si está vacío, completa con refrigerante o agua limpia.',
        'Revisa si la correa de accesorios está rota o si hay mangueras sueltas.',
      ],
    },
    {
      'id': 'cerrajeria',
      'titulo': 'Cerrajería',
      'icono': Icons.vpn_key,
      'categoriaColaborador': 'Cerrajería Automotriz',
      'advertencia': 'No fuerces el marco de la puerta con varillas improvisadas: puedes dañar airbags laterales o vidrios.',
      'soluciones': [
        'Verifica si alguna puerta trasera o el baúl quedó sin seguro eléctrico.',
        'Si la llave inteligente no responde, cambia la pila CR2032 del control o usa la llave mecánica oculta dentro del control.',
        'Contacta un cerrajero automotriz certificado del directorio de colaboradores.',
      ],
    },
    {
      'id': 'otro',
      'titulo': 'Otro / Grúa',
      'icono': Icons.local_shipping,
      'categoriaColaborador': 'Grúas 24 Horas',
      'advertencia': 'Si el vehículo quedó bloqueando la vía, prioriza tu integridad física fuera del carro.',
      'soluciones': [
        'Describe brevemente qué ocurrió en el cuadro de detalles para orientar al colaborador.',
        'Verifica si tu póliza SOAT o seguro todo riesgo incluye asistencia de grúa.',
        'Contacta directamente a una grúa o carro-taller de la lista inferior (acuerdo directo sin comisiones).',
      ],
    },
  ];

  // Directorio de anunciantes/colaboradores ordenados por ubicación y categoría
  final List> _directorioColaboradores = [
    {
      'nombre': 'Grúas Express 24/7',
      'categorias': ['Grúas 24 Horas', 'Grúas y Frenos', 'Mecánica / Grúas', 'Suministro Combustible / Grúa'],
      'zona': 'Cobertura Metropolitana y Vías Nacionales',
      'distancia': '1.2 km',
      'tiempoEstimado': '15 min',
      'telefono': '+57 311 647 9280',
      'verificado': true,
    },
    {
      'nombre': 'Serviteca y Montallantas Móvil El Rápido',
      'categorias': ['Montallantas y Llantas'],
      'zona': 'Sector Urbano y Periferia',
      'distancia': '1.8 km',
      'tiempoEstimado': '20 min',
      'telefono': '+57 300 412 8890',
      'verificado': true,
    },
    {
      'nombre': 'Baterías y Eléctricos Automotrices Al Instante',
      'categorias': ['Baterías y Electricidad', 'Mecánica / Carro-Taller'],
      'zona': 'Cobertura Norte, Centro y Sur',
      'distancia': '2.4 km',
      'tiempoEstimado': '25 min',
      'telefono': '+57 315 789 3321',
      'verificado': true,
    },
    {
      'nombre': 'Carro-Taller Mecánica Total & Escáner',
      'categorias': ['Mecánica / Carro-Taller', 'Mecánica / Grúas', 'Grúas y Frenos'],
      'zona': 'Zona Industrial y Corredores Viales',
      'distancia': '3.1 km',
      'tiempoEstimado': '30 min',
      'telefono': '+57 312 654 1109',
      'verificado': true,
    },
    {
      'nombre': 'Cerrajería Automotriz Llave Segura 24h',
      'categorias': ['Cerrajería Automotriz'],
      'zona': 'Toda la ciudad',
      'distancia': '2.9 km',
      'tiempoEstimado': '25 min',
      'telefono': '+57 318 902 4410',
      'verificado': true,
    },
    {
      'nombre': 'Auxilio Vial Combustible & Desvare',
      'categorias': ['Suministro Combustible / Grúa', 'Montallantas y Llantas', 'Baterías y Electricidad'],
      'zona': 'Autopistas y Salidas Principales',
      'distancia': '3.6 km',
      'tiempoEstimado': '30 min',
      'telefono': '+57 320 551 7740',
      'verificado': true,
    },
  ];

  Map<String, dynamic> get _motivoActual =>
      _motivosVarada.firstWhere((m) => m['id'] == _motivoSeleccionadoId);

  List> get _colaboradoresFiltrados {
    final String catBuscada = _motivoActual['categoriaColaborador'] as String;
    final filtrados = _directorioColaboradores.where((col) {
      final cats = col['categorias'] as List<String>;
      return cats.contains(catBuscada);
    }).toList();
    return filtrados.isNotEmpty ? filtrados : _directorioColaboradores;
  }

  @override
  void dispose() {
    _detalleAdicionalCtrl.dispose();
    super.dispose();
  }

  void _confirmarReporteVarada() {
    setState(() => _reporteEnviado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reporte de varada (${_motivoActual['titulo']}) activado con tu ubicación GPS. Contacta un colaborador abajo.',
        ),
        backgroundColor: const Color(0xFFE65100),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _contactarColaborador(Map<String, dynamic> colaborador) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: Color(0xFFE65100)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                colaborador['nombre'] as String,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubicación de asistencia: $_ubicacionActiva'),
            const SizedBox(height: 6),
            Text('Vehículo: $_tipoActivo ($_placaActiva)'),
            Text('Falla reportada: ${_motivoActual['titulo']}'),
            const Divider(height: 18),
            Text(
              'Teléfono / WhatsApp directo:\n${colaborador['telefono']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Nota: S.O.S. Auto no cobra comisiones ni intermedia pagos. Acuerda el valor del servicio directamente con el colaborador.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> soluciones = _motivoActual['soluciones'] as List<String>;
    final String advertencia = _motivoActual['advertencia'] as String;
    final String categoriaActiva = _motivoActual['categoriaColaborador'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.car_repair, size: 24),
            SizedBox(width: 8),
            Text(
              'Me varé',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera automática con datos del vehículo ya registrado en la app
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car, color: Color(0xFFE65100), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_tipoActivo • $_placaActiva',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _detalleActivo,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.my_location, size: 13, color: Color(0xFFE65100)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _ubicacionActiva,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // =========================================================
              // SECCIÓN 1: RECOMENDACIONES INMEDIATAS DE SEGURIDAD VIAL
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFA000), width: 1.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Color(0xFFE65100), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1. Recomendaciones de Seguridad',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E342E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _itemRecomendacion(
                        'Orilla el vehículo:', 'Si es posible, llévalo a la berma o a un lugar iluminado y seguro fuera del flujo vehicular.'),
                    _itemRecomendacion(
                        'Enciende las estacionarias:', 'Activa de inmediato las luces de parqueo para alertar a otros conductores.'),
                    _itemRecomendacion(
                        'Señaliza la vía:', 'Coloca los triángulos o conos reflectivos entre 30 y 50 metros detrás del vehículo.'),
                    _itemRecomendacion(
                        'Protégete:', 'Usa chaleco reflectivo si desciendes y espera detrás de la baranda o en zona segura.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 2: REPORTE EL MOTIVO DE LA VARADA
              // =========================================================
              const Text(
                '2. Reporte el motivo de la varada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _motivosVarada.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final motivo = _motivosVarada[index];
                  final bool seleccionado = motivo['id'] == _motivoSeleccionadoId;
                  return InkWell(
                    onTap: () => setState(() => _motivoSeleccionadoId = motivo['id'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: seleccionado ? const Color(0xFFE65100) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado ? const Color(0xFFE65100) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            motivo['icono'] as IconData,
                            size: 20,
                            color: seleccionado ? Colors.white : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              motivo['titulo'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
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
              const SizedBox(height: 10),
              TextField(
                controller: _detalleAdicionalCtrl,
                decoration: InputDecoration(
                  hintText: 'Detalle opcional (ej. rueda delantera derecha, sin repuesto...)',
                  prefixIcon: const Icon(Icons.edit_note, color: Color(0xFFE65100)),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 3: POSIBLES SOLUCIONES E INDICACIONES
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build_circle, color: Color(0xFF0B6E4F), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '3. Posibles soluciones: ${_motivoActual['titulo']}',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Alerta preventiva específica del problema
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advertencia,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(soluciones.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFF0B6E4F),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                soluciones[i],
                                style: const TextStyle(fontSize: 13.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 4: COLABORADORES / ANUNCIANTES POR UBICACIÓN Y CATEGORÍA
              // =========================================================
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0B6E4F).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.store_mall_directory, color: Color(0xFFE65100), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '4. Colaboradores cercanos',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Filtrados por ubicación ($_ubicacionActiva) y categoría: $categoriaActiva',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF0B6E4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 18),
                    ..._colaboradoresFiltrados.map((col) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          col['nombre'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (col['verificado'] == true)
                                        const Icon(Icons.verified, size: 16, color: Color(0xFF0B6E4F)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${col['zona']} • A ${col['distancia']} (~${col['tiempoEstimado']})',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    col['telefono'] as String,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _contactarColaborador(col),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B6E4F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text(
                                'Contactar',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Botón de confirmación / compartir alerta de varada
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _confirmarReporteVarada,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _reporteEnviado ? const Color(0xFF0B6E4F) : const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_reporteEnviado ? Icons.check_circle : Icons.share_location),
                  label: Text(
                    _reporteEnviado
                        ? 'UBICACIÓN DE VARADA COMPARTIDA'
                        : 'ACTIVAR ALERTA DE VARADA EN MI GPS',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRecomendacion(String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(text: '$titulo ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: detalle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
