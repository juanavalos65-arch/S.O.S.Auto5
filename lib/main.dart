class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S.O.S. Auto'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Contenedor del Mapa Interactivo de fondo
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text(
                'Mapa Interactivo Activo (Medellín / Vías)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
          // Botones flotantes de asistencia en la parte inferior
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Me Varé
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activando asistencia: Me Varé')),
                        );
                      },
                      icon: const Icon(Icons.car_repair, color: Colors.orange),
                      label: const Text('Me Varé'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Me Accidenté
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Alerta de Accidente'),
                            content: const Text('Se iniciará el protocolo de emergencia con cuenta regresiva de 5 segundos.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.warning, color: Colors.red),
                      label: const Text('Me Accidenté'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Peligro
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alerta de seguridad activada: Peligro')),
                        );
                      },
                      icon: const Icon(Icons.security, color: Colors.purple),
                      label: const Text('Peligro'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción Paute Aquí (Wompi)
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Paute Aquí - S.O.S. Auto'),
                            content: const Text('Redirigiendo a la pasarela de pagos Wompi para planes publicitarios.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.campaign, color: Colors.blue),
                      label: const Text('Paute Aquí'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
