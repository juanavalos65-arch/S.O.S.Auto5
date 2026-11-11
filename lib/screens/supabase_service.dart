import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initializeApp() async {
    await Supabase.initialize(
      url: 'https://TU-PROYECTO.supabase.co',
      publishableKey: 'TU_PUBLISHABLE_KEY', // Actualizado según la nueva API
    );
  }

  static Future<List>> getActiveAlerts() async {
    try {
      final response = await client
          .from('emergencias')
          .select()
          .eq('activa', true);
      return List>.from(response);
    } catch (e) {
      return [];
    }
  }
}
