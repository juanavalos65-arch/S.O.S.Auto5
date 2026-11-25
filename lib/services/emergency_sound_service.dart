import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class EmergencySoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static final Set<String> _alreadySounded = {};

  // Se llama cada vez que llega un banner nuevo
  static Future<void> checkAndSound(List<Map<String, dynamic>> banners) async {
    for (final b in banners) {
      final String id = b['id'].toString();
      final String category = (b['category'] ?? '').toString();

      // SOLO suena para emergencias, NO para novedades ni publicidad
      final bool isEmergency = category == 'incident' || category == 'stolen';
      if (!isEmergency) continue;

      // Si ya sonó por este id, no vuelvas a sonar
      if (_alreadySounded.contains(id)) continue;
      _alreadySounded.add(id);

      // Si hay más de 50 guardados, limpia para no llenar memoria
      if (_alreadySounded.length > 50) _alreadySounded.clear();

      await playSiren();
      break; // Solo suena 1 vez aunque vengan 2 emergencias juntas
    }
  }

  static Future<void> playSiren() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      // Vibración fuerte para que se sienta aunque esté en silencio
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      }
      // Sirena 2 veces
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sounds/sirena.mp3'));
      // Espera a que termine y repite 1 vez más
      await Future.delayed(const Duration(seconds: 4));
      if (_isPlaying) {
        await _player.play(AssetSource('sounds/sirena.mp3'));
      }
    } catch (_) {}
    // Apaga después de 8 segundos para no quedar sonando infinito
    Future.delayed(const Duration(seconds: 8), () {
      stop();
    });
  }

  static Future<void> stop() async {
    _isPlaying = false;
    try { await _player.stop(); } catch (_) {}
  }

  // Para probar el sonido con un botón
  static Future<void> testSound() async {
    _alreadySounded.clear();
    await playSiren();
  }
}
