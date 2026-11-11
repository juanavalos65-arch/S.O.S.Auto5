import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Inicialización de cliente Supabase
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://TU-PROYECTO.supabase.co',
      anonKey: 'TU_ANON_KEY',
    );
  }

  // Consulta de alertas de emergencia y aliados cercanos
  static Future<List>> getActiveAlerts() async {
    final response = await client
        .from('emergencias')
        .select()
        .eq('activa', true);
    return List>.from(response);
  }
}
