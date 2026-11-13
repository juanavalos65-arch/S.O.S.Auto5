  void _onTap(String title) {
    // Aquí direccionamos cada botón a su respectiva pantalla existente
    Widget targetScreen;

    switch (title) {
      case 'Regístrese':
        targetScreen = const RegisterVehicleScreen(); // O tu pantalla de registro
        break;
      case 'Paute Aquí':
        targetScreen = const AlliesScreen(); // O la pantalla de aliados/pauta
        break;
      case 'Me Varé':
        targetScreen = const EmergencySosScreen(); // O pantalla de asistencia
        break;
      case 'Accidente':
        targetScreen = const ReportIncidentScreen(); // Pantalla de incidente/accidente
        break;
      case 'Peligro':
        targetScreen = const EmergencySosScreen();
        break;
      case 'Tránsito':
        targetScreen = const TrafficStopScreen(); // Pantalla específica de agente de tránsito
        break;
      case 'Robo Auto':
        targetScreen = const StolenCarScreen(); // Pantalla de reporte de robo
        break;
      case 'Novedades':
      default:
        targetScreen = const BannerDinamicoScreen(); // O novedades en vía
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }
