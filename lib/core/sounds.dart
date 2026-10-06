import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Kurze Töne und ein sanftes Vibrieren als Rückmeldung.
///
/// Die Töne liegen als kleine WAV-Dateien in `assets/sounds/`.
/// Ausschalten geht im Menü – dann bleibt alles still.
class Sounds {
  Sounds._();

  static final Sounds instance = Sounds._();

  final AudioPlayer _player = AudioPlayer(playerId: 'studysnap-fx')
    ..setReleaseMode(ReleaseMode.stop);

  bool enabled = true;

  Future<void> _play(String file, {double volume = 0.9}) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Ton ist nie wichtig genug für einen Absturz
    }
  }

  /// Leiser Klick beim Antippen.
  void tap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    _play('tap.wav', volume: 0.5);
  }

  /// Richtige Antwort: kleine aufsteigende Melodie.
  void correct() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    _play('correct.wav');
  }

  /// Falsche Antwort: freundlich, nicht bestrafend.
  void wrong() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    _play('wrong.wav', volume: 0.7);
  }

  /// Ergebnis mit mindestens einem Stern.
  void win() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    _play('win.wav');
  }

  /// Alles richtig: große Fanfare.
  void perfect() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    _play('perfect.wav');
  }

  /// Neuer Sticker.
  void sticker() => _play('sticker.wav');

  void dispose() => _player.dispose();
}
