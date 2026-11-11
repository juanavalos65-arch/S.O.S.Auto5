import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initializeApp() async {
    await Supabase.initialize(
      url: 'https://TU-PROYECTO.supabase.co',
      anonKey: 'TU_ANON_KEY',
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
