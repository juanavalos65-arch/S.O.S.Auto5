import 'dart:async';
import 'package:flutter/material.dart';

class BottomActionGrid extends StatelessWidget {
  const BottomActionGrid({super.key});

  static const List> _botones = [
    {
      'titulo': 'Registro',
      'icono': Icons.app_registration,
      'color': Color(0xFF1E40AF),
      'bgColor': Color(0xFFDBEAFE),
      'esEmergencia': false,
    },
    {
      'titulo': 'Paute aquí',
      'icono': Icons.campaign,
      'color': Color(0xFF065F46),
      'bgColor': Color(0xFFD1FAE5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Me varé',
      'icono': Icons.car_repair,
      'color': Color(0xFF9A3412),
      'bgColor': Color(0xFFFFEDD5),
      'esEmergencia': false,
    },
    {
      'titulo': 'Accidente',
      'icono': Icons.car_crash,
      'color': Color(0xFF991B1B),
      'bgColor': Color(0xFFFEE2E2),
      'esEmergencia': true,
    },
    {
      'titulo': 'Estoy en peligro',
      'icono': Icons.gpp_maybe,
      'color': Color(0xFF7F1D1D),
      'bgColor': Color(0xFFFECACA),
      'esEmergencia': true,
    },
    {
      'titulo': 'Robo de auto',
      'icono': Icons.no_crash,
      'color': Color(0xFF881337),
      'bgColor': Color(0xFFFFE4E6),
      'esEmergencia': true,
    },
    {
      'titulo': 'Novedades en la vía',
      'icono': Icons.alt_route,
      'color': Color(0xFF3730A3),
      'bgColor': Color(0xFFE0E7FF),
      'esEmergencia': false,
    },
    {
      'titulo': 'Agente de tránsito',
      'icono': Icons.local_police,
      'color': Color(0xFF1F2937),
      'bgColor': Color(0xFFE5E7EB),
      'esEmergencia': true,
    },
  ];

  void _alPresionarBoton(BuildContext context, Map<String, dynamic> boton) {
    final String titulo = boton['titulo'] as String;
    final bool esEmergencia = boton['esEmergencia'] as bool;

    if (esEmergencia) {
      _mostrarDialogo5Segundos(context, titulo);
    } else {
      _abrirModulo(context, titulo);
    }
  }

  void _abrirModulo(BuildContext context, String titulo) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ModuloOperativoScreen(titulo: titulo),
      ),
    );
  }

  void _mostrarDialogo5Segundos(BuildContext rootContext, String tipoAlerta) {
    int segundosRestantes = 5;
    Timer? cuentaRegresiva;
    bool cancelada = false;

    showDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            cuentaRegresiva ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!dialogContext.mounted || cancelada) {
                t.cancel();
                return;
              }
              if (segundosRestantes > 1) {
                setDialogState(() {
                  segundosRestantes--;
                });
              } else {
                cancelada = true;
                t.cancel();
                Navigator.of(dialogContext).pop();
                _dispararAlertaConfirmada(rootContext, tipoAlerta);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alerta: $tipoAlerta',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enviando alerta GPS en $segundosRestantes segundos...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tienes 5 segundos para cancelar la alerta si la presionaste por error.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cancelada = true;
                        cuentaRegresiva?.cancel();
                        Navigator.of(dialogContext).pop();
                        if (rootContext.mounted) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Alerta desactivada.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'DESACTIVAR ALERTA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => cuentaRegresiva?.cancel());
  }

  void _dispararAlertaConfirmada(BuildContext context, String tipoAlerta) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Alerta "$tipoAlerta" enviada con ubicación GPS.'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
    _abrirModulo(context, tipoAlerta);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _botones.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          final btn = _botones[index];
          final Color colorPrincipal = btn['color'] as Color;
          final Color colorFondo = btn['bgColor'] as Color;

          return InkWell(
            onTap: () => _alPresionarBoton(context, btn),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorPrincipal.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    btn['icono'] as IconData,
                    color: colorPrincipal,
                    size: 26,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    btn['titulo'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorPrincipal,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModuloOperativoScreen extends StatefulWidget {
  final String titulo;
  const _ModuloOperativoScreen({required this.titulo});

  @override
  State<_ModuloOperativoScreen> createState() => _ModuloOperativoScreenState();
}

class _ModuloOperativoScreenState extends State<_ModuloOperativoScreen> {
  final _placaController = TextEditingController();
  final _detalleController = TextEditingController();
  String _planPauta = 'Plan Mensual - \$49.900 COP';

  @override
  void dispose() {
    _placaController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _construirContenidoModulo(),
      ),
    );
  }

  Widget _construirContenidoModulo() {
    switch (widget.titulo) {
      case 'Registro':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registro de Vehículo y Conductores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa del vehículo (Ej: HXU874)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Marca, modelo y color',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehículo guardado en S.O.S. Auto.')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar Vehículo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case 'Paute aquí':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pauta Comercial en S.O.S. Auto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Anuncia tu taller, grúa o serviteca en el banner superior y en el mapa de cercanía.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _planPauta,
              decoration: const InputDecoration(
                labelText: 'Selecciona tu plan',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Plan Mensual - \$49.900 COP',
                  child: Text('Plan Mensual - \$49.900 COP'),
                ),
                DropdownMenuItem(
                  value: 'Plan Trimestral - \$129.900 COP',
                  child: Text('Plan Trimestral - \$129.900 COP'),
                ),
                DropdownMenuItem(
                  value: 'Plan Anual - \$449.900 COP',
                  child: Text('Plan Anual - \$449.900 COP'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _planPauta = v);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Nombre del negocio y teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Conectando con pasarela Wompi ($_planPauta)...')),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pagar con Wompi'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF065F46),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case 'Me varé':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Asistencia Mecánica y Grúas Cercanas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Color(0xFF9A3412)),
                title: const Text('Grúas 24/7 Express'),
                subtitle: const Text('A 1.2 km de tu ubicación GPS'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitando grúa a tu ubicación GPS...')),
                    );
                  },
                  child: const Text('Pedir'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full, color: Color(0xFF9A3412)),
                title: const Text('Baterías y Despinche Móvil'),
                subtitle: const Text('A 2.4 km de tu ubicación GPS'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitando técnico móvil...')),
                    );
                  },
                  child: const Text('Pedir'),
                ),
              ),
            ),
          ],
        );

      case 'Novedades en la vía':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Reportar Novedad en la Vía',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detalleController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe el cierre, derrumbe o reten en la vía',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Novedad publicada en el banner vial.')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.send),
              label: const Text('Publicar en Banner Vial'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF3730A3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                '🚨 Protocolo activo: ${widget.titulo}\nTu ubicación GPS en tiempo real ha sido compartida con tus contactos de emergencia y la red cercana.',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Finalizar / Volver al Mapa'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
    }
  }
}
