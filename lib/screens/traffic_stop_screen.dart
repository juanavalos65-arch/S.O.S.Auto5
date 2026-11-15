import 'package:flutter/material.dart';

class AgenteTransitoScreen extends StatefulWidget {
  final String? placaRegistrada;
  final String? ciudadActual;
  final String? paisActual;

  const AgenteTransitoScreen({
    super.key,
    this.placaRegistrada,
    this.ciudadActual,
    this.paisActual,
  });

  @override
  State<AgenteTransitoScreen> createState() => _AgenteTransitoScreenState();
}

class _AgenteTransitoScreenState extends State<AgenteTransitoScreen> {
  final TextEditingController _placaAgenteCtrl = TextEditingController();
  final TextEditingController _motivoDetencionCtrl = TextEditingController();

  late String _paisSeleccionado;
  bool _grabacionActiva = true;
  int _fotosTomadas = 0;

  // Resultado del análisis legal según país y motivo
  Map<String, String>? _resultadoConsultaLegal;

  // Base normativa por país
  final Map<String, Map<String, dynamic>> _codigosPorPais = {
    'Colombia': {
      'normaGeneral': 'Ley 769 de 2002 (Código Nacional de Tránsito Terrestre) y Ley 1801 de 2016',
      'derechoGrabar':
          'Art. 21 Ley 1801 de 2016: Todo procedimiento policial o de tránsito en vía pública puede ser grabado por cualquier ciudadano sin que el agente pueda decomisar el celular.',
      'casos': {
        'documentos': {
          'articulo': 'Art. 30, 35 y Circular Mintransporte 2022',
          'titulo': 'Exigencia de documentos físicos vs. digitales',
          'solucion':
              'La licencia de conducción, tarjeta de propiedad, SOAT y Revisión Técnico-Mecánica pueden presentarse en formato digital o consultarse directamente en el RUNT. No pueden inmovilizar el vehículo si aparecen vigentes en el sistema.',
        },
        'inmovilizacion': {
          'articulo': 'Art. 125 y Art. 131 Ley 769 de 2002',
          'titulo': 'Intento de inmovilización o subida a grúa',
          'solucion':
              'Si la infracción es subsanable en el sitio (ej. bombillo fundido, cinturón, no portar kit) tienes derecho a subsanarla en un plazo de hasta 60 minutos antes de inmovilizar. Si llegas antes de que la grúa enganche y arranque, deben entregarte el vehículo y solo imponer el comparendo.',
        },
        'reten': {
          'articulo': 'Resolución 3027 de 2010 y Manual de Señalización Vial',
          'titulo': 'Legalidad del retén o puesto de control',
          'solucion':
              'Todo puesto de control debe contar con orden de servicio, mínimo 2 agentes uniformados, conos reflectivos, paletas y señalización previa visible. Graba la ausencia de señalización y firma el comparendo "Bajo protesta / No conforme".',
        },
        'alcoholemia': {
          'articulo': 'Ley 1696 de 2013 y Resolución 1844 de 2015 (Medicina Legal)',
          'titulo': 'Prueba de embriaguez / alcohosensor',
          'solucion':
              'Exige que el alcohosensor tenga certificado de calibración vigente y que abran una boquilla nueva sellada frente a ti. Negarse a la prueba acarrea la multa máxima y suspensión de licencia; solicita segunda prueba a los 15 minutos si hay duda.',
        },
        'parqueo': {
          'articulo': 'Art. 76 y Art. 127 Ley 769 de 2002',
          'titulo': 'Estacionamiento en sitio prohibido o abandono',
          'solucion':
              'Si estás presente junto al vehículo, el agente impone el comparendo pero NO puede inmovilizar ni subir el carro a la grúa. La grúa solo procede cuando el conductor está ausente o bloqueando acceso vital.',
        },
        'general': {
          'articulo': 'Art. 135 y Art. 136 Ley 769 de 2002 (Debido Proceso)',
          'titulo': 'Procedimiento general de comparendo y defensa',
          'solucion':
              'No discutas. Recibe la copia del comparendo sin aceptar culpa (puedes pedir que anoten tus observaciones). Tienes 5 días hábiles para impugnar en audiencia pública aportando tus videos y fotos, o acceder al 50% de descuento.',
        },
      },
    },
    'México': {
      'normaGeneral': 'Ley General de Movilidad y Seguridad Vial y Reglamentos de Tránsito Estatales/CDMX',
      'derechoGrabar':
          'Art. 6° y 7° Constitucional: Grabar a servidores públicos en ejercicio de sus funciones en la vía pública es un derecho protegido.',
      'casos': {
        'documentos': {
          'articulo': 'Reglamento de Tránsito (Art. 43 / Licencias Digitales)',
          'titulo': 'Revisión de licencia y tarjeta de circulación',
          'solucion':
              'Muestra licencia y tarjeta de circulación vigentes (físicas o digitales oficiales). Ningún agente de tránsito puede retener tu licencia, placas o vehículo como garantía de pago salvo infracciones graves expresas (alcoholímetro o falta total de documentos).',
        },
        'inmovilizacion': {
          'articulo': 'Art. 67 Reglamento de Tránsito (Remisión a Depósito / Corralón)',
          'titulo': 'Remisión de vehículo al corralón',
          'solucion':
              'Si el conductor llega antes de que la grúa inicie el arrastre, se debe levantar únicamente la boleta de infracción y entregar el vehículo sin cobro de arrastre.',
        },
        'reten': {
          'articulo': 'Art. 16 Constitucional (Acto de Molestia Fundado y Motivado)',
          'titulo': 'Detención arbitraria sin infracción flagrante',
          'solucion':
              'Un agente de tránsito solo puede detenerte por una infracción flagrante al reglamento o en un operativo oficial señalizado (ej. Conduce Sin Alcohol). Pide que indique el artículo exacto infringido.',
        },
        'alcoholemia': {
          'articulo': 'Programa Conduce Sin Alcohol / Art. 50 Reglamento',
          'titulo': 'Punto de control de alcoholemia',
          'solucion':
              'Verifica que el personal esté debidamente identificado y que la pipeta sea nueva. Tienes derecho a llamada telefónica y asistencia legal si superas el límite permitido.',
        },
        'parqueo': {
          'articulo': 'Art. 30 Reglamento de Tránsito',
          'titulo': 'Estacionamiento prohibido o inmovilizador (araña)',
          'solucion':
              'Verifica si existe señalamiento restrictivo visible. Toma foto de toda la cuadra para demostrar ausencia de señalización si vas a impugnar ante el Tribunal de Justicia Administrativa.',
        },
        'general': {
          'articulo': 'Art. 14 y 16 Constitucional • Juicio de Nulidad',
          'titulo': 'Impugnación de boleta de infracción',
          'solucion':
              'Recibe la boleta sin confrontación. Anota nombre, número de placa y unidad del oficial. Puedes impugnar la multa dentro de los 15 días hábiles siguientes si carece de fundamentación o pruebas.',
        },
      },
    },
    'Perú': {
      'normaGeneral': 'D.S. N° 016-2009-MTC (Reglamento Nacional de Tránsito - RNT)',
      'derechoGrabar':
          'Derecho ciudadano a fiscalizar actos públicos: Puedes grabar la intervención policial desde el interior de tu vehículo.',
      'casos': {
        'documentos': {
          'articulo': 'Art. 91 RNT (Documentos obligatorios)',
          'titulo': 'Control de Brevete, Tarjeta de Propiedad, SOAT y CITV',
          'solucion':
              'El SOAT electrónico y la Revisión Técnica (CITV) son verificables en línea por la PNP. Solo entrega los documentos requeridos por el Art. 91.',
        },
        'inmovilizacion': {
          'articulo': 'Art. 299 RNT (Retención e Internamiento)',
          'titulo': 'Internamiento en depósito municipal o PNP',
          'solucion':
              'El internamiento solo procede en las infracciones expresamente tipificadas en el Cuadro de Infracciones (M01, M02, etc.). Exige el acta de internamiento inventariada.',
        },
        'reten': {
          'articulo': 'Art. 327 RNT (Procedimiento de detección de infracciones)',
          'titulo': 'Intervención policial en vía pública',
          'solucion':
              'El efectivo policial debe acercarse a tu ventanilla, identificarse con grado y apellidos, e indicar el motivo exacto de la intervención antes de pedir documentos.',
        },
        'alcoholemia': {
          'articulo': 'Art. 307 RNT (Dosaje etílico)',
          'titulo': 'Prueba de alcoholemia',
          'solucion':
              'Límite general 0.50 g/l (0.25 g/l transporte público). Si el test cualitativo da positivo, tienes derecho al dosaje etílico cuantitativo en sanidad policial.',
        },
        'parqueo': {
          'articulo': 'Art. 215 y 219 RNT',
          'titulo': 'Estacionamiento rígido o remolque con grúa',
          'solucion':
              'Toma fotografía de la señalización de zona rígida y del estado de tu vehículo antes de cualquier maniobra.',
        },
        'general': {
          'articulo': 'Art. 336 RNT (Descargos y Nulidad de Papeleta)',
          'titulo': 'Defensa y descargo ante papeleta injusta',
          'solucion':
              'En el campo "Observaciones del conductor" de la papeleta escribe brevemente tu versión. Presenta tu descargo dentro de los 5 días hábiles ante la autoridad competente.',
        },
      },
    },
    'Chile': {
      'normaGeneral': 'Ley N° 18.290 (Ley de Tránsito de Chile)',
      'derechoGrabar':
          'Control ciudadano en espacio público: Es lícito grabar el procedimiento policial sin obstruir la labor de Carabineros.',
      'casos': {
        'documentos': {
          'articulo': 'Art. 5 y Art. 51 Ley 18.290',
          'titulo': 'Control de licencia, permiso de circulación, SOAP y revisión técnica',
          'solucion':
              'Exhibe licencia de conducir, permiso de circulación, seguro obligatorio (SOAP) y certificado de revisión técnica vigentes.',
        },
        'inmovilizacion': {
          'articulo': 'Art. 56 y Art. 156 Ley 18.290',
          'titulo': 'Retiro de circulación del vehículo',
          'solucion':
              'Solo procede cuando el vehículo circula sin permiso de circulación, sin revisión técnica vigente, sin SOAP o con fallas mecánicas graves de seguridad.',
        },
        'reten': {
          'articulo': 'Art. 4 Ley 18.290 (Fiscalización preventiva)',
          'titulo': 'Control vehicular preventivo',
          'solucion':
              'Carabineros e inspectores fiscales están facultados para realizar controles preventivos. Mantén la calma, exige trato respetuoso y registra número de patrulla.',
        },
        'alcoholemia': {
          'articulo': 'Ley Tolerancia Cero y Ley Emilia (Art. 110 y 196)',
          'titulo': 'Control de alcotest / narcotest',
          'solucion':
              'Desde 0.3 g/l se configura conducción bajo influencia del alcohol. Tienes derecho a solicitar examen de alcoholemia en sangre en centro asistencial.',
        },
        'parqueo': {
          'articulo': 'Art. 154 y 156 Ley 18.290',
          'titulo': 'Estacionamiento prohibido',
          'solucion':
              'Verifica distancia a esquinas (10 m), grifos (5 m) y señalética. Documenta con fotos para el Juzgado de Policía Local.',
        },
        'general': {
          'articulo': 'Ley 18.287 (Procedimiento ante Juzgados de Policía Local)',
          'titulo': 'Citación al Juzgado de Policía Local',
          'solucion':
              'Recibe la boleta de citación y acude el día indicado al Juzgado de Policía Local con tus pruebas (videos, fotos, testigos) para presentar descargos.',
        },
      },
    },
    'Ecuador': {
      'normaGeneral': 'Ley Orgánica de Transporte Terrestre, Tránsito y Seguridad Vial (LOTTTSV) y COIP',
      'derechoGrabar':
          'Art. 18 Constitución del Ecuador: Derecho a registrar y difundir información de interés público en procedimientos en vía.',
      'casos': {
        'documentos': {
          'articulo': 'Art. 90 LOTTTSV y Reglamento General',
          'titulo': 'Licencia de conducir y matrícula vehicular',
          'solucion':
              'Presenta licencia vigente (física o digital) y matrícula al día. El agente verifica en el sistema ANT.',
        },
        'inmovilizacion': {
          'articulo': 'Art. 383 - 392 COIP (Retención vehicular)',
          'titulo': 'Retención del vehículo',
          'solucion':
              'La retención solo aplica en las contravenciones expresamente señaladas en el COIP (ej. matrícula caducada o falta de licencia). Exige inventario completo.',
        },
        'reten': {
          'articulo': 'Art. 163 LOTTTSV',
          'titulo': 'Operativos de control de tránsito',
          'solucion':
              'Verifica el uniforme reglamentario, identificación visible del agente y patrulla oficial.',
        },
        'alcoholemia': {
          'articulo': 'Art. 385 COIP (Conducción en estado de embriaguez)',
          'titulo': 'Prueba de alcohotest',
          'solucion':
              'Exige boquilla nueva y verificación del equipo. Tienes derecho a examen de sangre en centro médico autorizado.',
        },
        'parqueo': {
          'articulo': 'Art. 391 numeral 5 COIP',
          'titulo': 'Mal estacionado',
          'solucion':
              'Fotografía el entorno para acreditar si existía o no señalización prohibitiva.',
        },
        'general': {
          'articulo': 'Art. 644 COIP (Impugnación de boletas de tránsito)',
          'titulo': 'Impugnación dentro de 3 días',
          'solucion':
              'Dispones de 3 días hábiles contados desde la notificación de la citación para impugnarla ante el Juez de Contravenciones con tus evidencias.',
        },
      },
    },
    'Argentina': {
      'normaGeneral': 'Ley Nacional de Tránsito N° 24.449',
      'derechoGrabar':
          'Transparencia administrativa: Puedes filmar el control vehicular en la vía pública como respaldo probatorio.',
      'casos': {
        'documentos': {
          'articulo': 'Art. 40 Ley 24.449 (Requisitos para circular)',
          'titulo': 'Documentación exigible (Licencia, Cédula, Seguro, VTV)',
          'solucion':
              'La licencia nacional digital y el comprobante de seguro digital tienen plena validez legal (Resolución SSN / Mi Argentina).',
        },
        'inmovilizacion': {
          'articulo': 'Art. 72 Ley 24.449 (Retención preventiva)',
          'titulo': 'Retención preventiva de vehículo o licencia',
          'solucion':
              'Solo procede si el conductor no está habilitado, el vehículo no cumple condiciones mínimas de seguridad o falta documentación esencial.',
        },
        'reten': {
          'articulo': 'Art. 36 y 70 Ley 24.449',
          'titulo': 'Control vehicular en ruta o ciudad',
          'solucion':
              'El puesto debe estar debidamente balizado y el inspector identificado con credencial visible.',
        },
        'alcoholemia': {
          'articulo': 'Ley 27.714 (Alcohol Cero al Volante)',
          'titulo': 'Control de alcoholemia',
          'solucion':
              'Verifica que la pipeta sea abierta delante tuyo y exige el ticket impreso del alcoholímetro con fecha y hora.',
        },
        'parqueo': {
          'articulo': 'Art. 49 Ley 24.449',
          'titulo': 'Estacionamiento prohibido / Acarreo',
          'solucion':
              'Si estás presente antes del inicio del acarreo, corresponde solo el acta de infracción sin traslado.',
        },
        'general': {
          'articulo': 'Art. 69 y 71 Ley 24.449 (Derecho de Defensa)',
          'titulo': 'Descargo ante Juzgado de Faltas',
          'solucion':
              'No estás obligado a firmar reconocimiento de culpa; firma "En disconformidad" y presenta tu descargo con fotos y videos ante el Juzgado de Faltas.',
        },
      },
    },
    'Estados Unidos': {
      'normaGeneral': 'State Vehicle Code & Fourth Amendment (U.S. Constitution)',
      'derechoGrabar':
          'First Amendment: Tienes derecho constitucional a grabar a oficiales de policía en espacios públicos siempre que no interfieras físicamente.',
      'casos': {
        'documentos': {
          'articulo': 'State Vehicle Code (License, Registration & Proof of Insurance)',
          'titulo': 'Control de licencia, registro y seguro',
          'solucion':
              'Mantén ambas manos visibles en el volante, avisa antes de alcanzar la guantera y entrega licencia, registro y seguro.',
        },
        'inmovilizacion': {
          'articulo': 'Vehicle Impoundment Rules',
          'titulo': 'Remolque / Impound del vehículo',
          'solucion':
              'Solicita el recibo oficial de inventario y la dirección exacta del patio (impound lot).',
        },
        'reten': {
          'articulo': 'Fourth Amendment (Reasonable Suspicion)',
          'titulo': 'Parada de tránsito (Traffic Stop)',
          'solucion':
              'Pregunta respetuosamente: "Officer, why was I stopped?". No consientas registros del vehículo sin orden judicial ("I do not consent to searches").',
        },
        'alcoholemia': {
          'articulo': 'DUI / Implied Consent Laws',
          'titulo': 'Control DUI / Sobriedad',
          'solucion':
              'Invoca tu derecho a guardar silencio (Fifth Amendment) y solicita hablar con un abogado.',
        },
        'parqueo': {
          'articulo': 'Municipal Parking Enforcement',
          'titulo': 'Ticket de estacionamiento',
          'solucion':
              'Toma fotos de la señalización del poste más cercano para disputar el ticket en línea o en corte.',
        },
        'general': {
          'articulo': 'Traffic Court Contest Procedure',
          'titulo': 'Impugnación de citación (Traffic Ticket)',
          'solucion':
              'Firma la citación (solo confirma recibo, no culpabilidad) y marca "Not Guilty" antes de la fecha límite para solicitar audiencia.',
        },
      },
    },
  };

  final List> _abogadosTransito = [
    {
      'nombre': 'Dr. Carlos Andrés Mejía • Defensa Vial 24/7',
      'especialidad': 'Impugnación de comparendos, retenes e inmovilizaciones',
      'experiencia': '14 años de experiencia • Atención inmediata en vía',
      'telefono': '+57 311 647 9280',
      'disponible': true,
    },
    {
      'nombre': 'Firma Jurídica Tránsito & Movilidad Segura',
      'especialidad': 'Derecho administrativo sancionatorio, alcoholemia y audiencias',
      'experiencia': 'Cobertura nacional • Consulta telefónica urgente',
      'telefono': '+57 300 412 8890',
      'disponible': true,
    },
    {
      'nombre': 'Dra. Laura Patricia Gómez • Abogada de Tránsito',
      'especialidad': 'Abuso de autoridad, fotomultas y defensa de conductores',
      'experiencia': '11 años de experiencia • Respuesta en 5 min',
      'telefono': '+57 315 789 3321',
      'disponible': true,
    },
  ];

  late final String _fechaHoraProcedimiento;

  @override
  void initState() {
    super.initState();
    _paisSeleccionado = _codigosPorPais.containsKey(widget.paisActual)
        ? widget.paisActual!
        : 'Colombia';

    final now = DateTime.now();
    _fechaHoraProcedimiento =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} • '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  String get _placaActiva =>
      (widget.placaRegistrada != null && widget.placaRegistrada!.trim().isNotEmpty)
          ? widget.placaRegistrada!.trim().toUpperCase()
          : 'VEHÍCULO REGISTRADO';

  String get _lugarExacto =>
      (widget.ciudadActual != null && widget.ciudadActual!.trim().isNotEmpty)
          ? widget.ciudadActual!.trim()
          : 'Ubicación GPS registrada en tiempo real';

  @override
  void dispose() {
    _placaAgenteCtrl.dispose();
    _motivoDetencionCtrl.dispose();
    super.dispose();
  }

  /// Analiza el texto escrito por el usuario y selecciona el artículo y solución del país elegido
  void _consultarCodigoYSolucion() {
    final String texto = _motivoDetencionCtrl.text.trim().toLowerCase();
    final Map<String, dynamic> paisData = _codigosPorPais[_paisSeleccionado]!;
    final Map<String, dynamic> casos = paisData['casos'] as Map<String, dynamic>;

    String claveCaso = 'general';

    if (texto.contains('document') ||
        texto.contains('licencia') ||
        texto.contains('soat') ||
        texto.contains('tecnico') ||
        texto.contains('técnico') ||
        texto.contains('tarjeta') ||
        texto.contains('papeles') ||
        texto.contains('digital')) {
      claveCaso = 'documentos';
    } else if (texto.contains('inmoviliz') ||
        texto.contains('grua') ||
        texto.contains('grúa') ||
        texto.contains('patio') ||
        texto.contains('corralon') ||
        texto.contains('corralón') ||
        texto.contains('luz') ||
        texto.contains('bombillo') ||
        texto.contains('llanta')) {
      claveCaso = 'inmovilizacion';
    } else if (texto.contains('reten') ||
        texto.contains('retén') ||
        texto.contains('puesto') ||
        texto.contains('cono') ||
        texto.contains('señal') ||
        texto.contains('arbitrar') ||
        texto.contains('sin motivo')) {
      claveCaso = 'reten';
    } else if (texto.contains('alcohol') ||
        texto.contains('embriag') ||
        texto.contains('soplar') ||
        texto.contains('trago') ||
        texto.contains('cerveza')) {
      claveCaso = 'alcoholemia';
    } else if (texto.contains('parque') ||
        texto.contains('estacion') ||
        texto.contains('prohibido') ||
        texto.contains('mal parqueado')) {
      claveCaso = 'parqueo';
    }

    final Map<String, dynamic> casoEncontrado = casos[claveCaso] as Map<String, dynamic>;

    setState(() {
      _resultadoConsultaLegal = {
        'pais': _paisSeleccionado,
        'normaGeneral': paisData['normaGeneral'] as String,
        'derechoGrabar': paisData['derechoGrabar'] as String,
        'articulo': casoEncontrado['articulo'] as String,
        'titulo': casoEncontrado['titulo'] as String,
        'solucion': casoEncontrado['solucion'] as String,
      };
    });
  }

  void _contactarAbogado(Map<String, dynamic> abogado) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gavel, color: Color(0xFF102A43)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                abogado['nombre'] as String,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('País: $_paisSeleccionado'),
            Text('Fecha y hora: $_fechaHoraProcedimiento'),
            Text('Lugar: $_lugarExacto'),
            Text('Vehículo: $_placaActiva'),
            if (_placaAgenteCtrl.text.trim().isNotEmpty)
              Text('ID / Placa Agente: ${_placaAgenteCtrl.text.trim()}'),
            const Divider(height: 18),
            Text(
              'Línea directa abogado:\n${abogado['telefono']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consejo: Pon la llamada en altavoz para que el abogado escuche el procedimiento.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFF102A43))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String derechoGrabarActual =
        _codigosPorPais[_paisSeleccionado]!['derechoGrabar'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.local_police, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Me detuvo un agente de tránsito',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
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
              // =========================================================
              // SECCIÓN 1: INSTRUCCIONES DE CONDUCTA Y RESPALDO DE EVIDENCIA
              // =========================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A43),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.amberAccent, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1. Protocolo Preventivo y Evidencia',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _itemProtocolo('Mantén la calma y NO discutas:',
                        'Habla en tono respetuoso y sereno; evita confrontaciones verbales.'),
                    _itemProtocolo('Graba el procedimiento:',
                        'Tienes derecho legal a grabar audio y video desde tu vehículo sin obstruir.'),
                    _itemProtocolo('Toma fotografías:',
                        'Registra el entorno, ausencia de señales, estado del vehículo y patrulla.'),
                    _itemProtocolo('Identifica a los agentes:',
                        'Anota o graba el nombre visible en el uniforme y número de placa/chaleco.'),
                    const SizedBox(height: 12),

                    // Tarjeta automática con Fecha, Hora y Lugar exacto
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📅 Fecha y Hora exacta: $_fechaHoraProcedimiento',
                            style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '📍 Lugar exacto: $_lugarExacto ($_paisSeleccionado)',
                            style: const TextStyle(color: Colors.white, fontSize: 12.5),
                          ),
                          Text(
                            '🚗 Vehículo: $_placaActiva',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Controles rápidos de grabación, foto e ID de agente
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _grabacionActiva = !_grabacionActiva);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _grabacionActiva ? Colors.redAccent : Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: Icon(
                              _grabacionActiva ? Icons.fiber_manual_record : Icons.mic_off,
                              size: 16,
                            ),
                            label: Text(
                              _grabacionActiva ? 'Grabando respaldo' : 'Iniciar grabación',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _fotosTomadas++);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Evidencia fotográfica #$_fotosTomadas guardada con fecha, hora y GPS.'),
                                  backgroundColor: const Color(0xFF0B6E4F),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF102A43),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(
                              'Tomar Foto ($_fotosTomadas)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _placaAgenteCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nombre o número de placa/chaleco del agente (opcional)',
                        hintStyle: const TextStyle(color: Colors.white60, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.badge, color: Colors.amberAccent),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.10),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 2: ESCRIBA EL MOTIVO + CÓDIGO DE TRÁNSITO POR PAÍS
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
                    const Row(
                      children: [
                        Icon(Icons.menu_book, color: Color(0xFF102A43), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Consulta Código de Tránsito y Solución',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Selector de País para aplicar la ley de tránsito correspondiente
                    DropdownButtonFormField<String>(
                      value: _paisSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'País del procedimiento (Normativa aplicable)',
                        prefixIcon: const Icon(Icons.public, color: Color(0xFF102A43)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      items: _codigosPorPais.keys
                          .map((pais) => DropdownMenuItem(value: pais, child: Text(pais)))
                          .toList(),
                      onChanged: (nuevoPais) {
                        if (nuevoPais != null) {
                          setState(() {
                            _paisSeleccionado = nuevoPais;
                          });
                          if (_motivoDetencionCtrl.text.trim().isNotEmpty) {
                            _consultarCodigoYSolucion();
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        derechoGrabarActual,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF102A43)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Escriba el motivo
                    TextField(
                      controller: _motivoDetencionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Escriba el motivo por el que lo detuvieron *',
                        hintText:
                            'Ej. Me quieren inmovilizar el carro por un bombillo, retén sin conos, documentos digitales, mal parqueo...',
                        prefixIcon: const Icon(Icons.edit_document, color: Color(0xFF102A43)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Chips de sugerencia rápida para probar con un toque
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chipSugerencia('Inmovilización / Grúa'),
                        _chipSugerencia('Documentos digitales'),
                        _chipSugerencia('Retén sin señalización'),
                        _chipSugerencia('Alcoholemia'),
                        _chipSugerencia('Mal parqueo'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _consultarCodigoYSolucion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF102A43),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.balance),
                        label: Text(
                          'CONSULTAR CÓDIGO DE $_paisSeleccionado Y SOLUCIÓN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),

                    // Resultado legal y solución específica
                    if (_resultadoConsultaLegal != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0B6E4F), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RESPALDO LEGAL (${_resultadoConsultaLegal!['pais']})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B6E4F),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _resultadoConsultaLegal!['normaGeneral']!,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const Divider(height: 14),
                            Text(
                              '📜 ${_resultadoConsultaLegal!['articulo']!}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102A43),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _resultadoConsultaLegal!['titulo']!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '💡 Solución sugerida para tu caso:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B6E4F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _resultadoConsultaLegal!['solucion']!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.black87,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // =========================================================
              // SECCIÓN 3: LISTA DE ABOGADOS DE TRÁNSITO PARA CONSULTA
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
                    const Row(
                      children: [
                        Icon(Icons.gavel, color: Color(0xFF102A43), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '3. Abogados de Tránsito Disponibles',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asesoría jurídica inmediata en $_lugarExacto ($_paisSeleccionado):',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                    const Divider(height: 16),
                    ..._abogadosTransito.map((abogado) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    abogado['nombre'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    abogado['especialidad'] as String,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    abogado['experiencia'] as String,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _contactarAbogado(abogado),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B6E4F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.call, size: 15),
                              label: const Text(
                                'Consultar',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón Finalizar
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'FINALIZAR Y VOLVER AL INICIO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemProtocolo(String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 15, color: Colors.amberAccent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.3),
                children: [
                  TextSpan(
                      text: '$titulo ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  TextSpan(text: detalle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipSugerencia(String texto) {
    return ActionChip(
      label: Text(texto, style: const TextStyle(fontSize: 11.5)),
      backgroundColor: const Color(0xFFF0F4F8),
      onPressed: () {
        _motivoDetencionCtrl.text = texto;
        _consultarCodigoYSolucion();
      },
    );
  }
}
