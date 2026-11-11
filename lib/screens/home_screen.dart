class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Mapa Base con OpenStreetMap + MapLibre
          const SOSMapWidget(),

          // 2. Cabecera y Banner Dinámico Superior
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Logotipo Oficial
                Image.asset('assets/images/logo_sos_auto.png', height: 40),
                const SizedBox(height: 8),
                // Banner Intercalado (Pauta / Vehículos Robados / Novedades)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "⚠️ Alerta vial en vía principal: Precaución por carril reducido",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 3. Botones Flotantes sobre el Mapa (Acceso Rápido)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text("Me Varé"),
                    backgroundColor: Colors.yellow[700],
                    onPressed: () {
                      // Lógica de asistencia directa sin intermediarios
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("Me Accidenté"),
                    backgroundColor: Colors.red,
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      // Activar cuenta regresiva de 5 segundos con PIN/biometría
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("Paute Aquí"),
                    backgroundColor: Colors.blue,
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      // Abrir pasarela Wompi o planes publicitarios
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
