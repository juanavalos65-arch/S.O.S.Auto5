import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class EmergencySoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static final Set<String> _alreadySounded = <String>{};

  static Future<void> checkAndSound(List banners) async {
    for (final b in banners) {
      if (b is! Map) continue;
      final String id = (b['id'] ?? '').toString();
      final String category = (b['category'] ?? '').toString();

      final bool isEmergency = category == 'incident' || category == 'stolen';
      if (!isEmergency) continue;

      if (_alreadySounded.contains(id)) continue;
      _alreadySounded.add(id);

      if (_alreadySounded.length > 50) _alreadySounded.clear();

      await playSiren();
      break;
    }
  }

  static Future<void> playSiren() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      // Vibración nativa de Flutter (funciona en todos los Android sin paquetes extra)
      unawaited(() async {
        for (int i = 0; i < 6; i++) {
          if (!_isPlaying) break;
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }());

      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sounds/sirena.mp3'));

      await Future.delayed(const Duration(seconds: 4));
      if (_isPlaying) {
        await _player.play(AssetSource('sounds/sirena.mp3'));
      }
    } catch (_) {}

    Future.delayed(const Duration(seconds: 8), () {
      stop();
    });
  }

  static Future<void> stop() async {
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> testSound() async {
    _alreadySounded.clear();
    await playSiren();
  }
}
