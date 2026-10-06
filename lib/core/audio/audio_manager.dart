import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Centralized audio manager for DashKart using `flutter_soloud`.
///
/// Handles low-latency sound effects, dynamic engine loop pitch-shifting
/// based on vehicle speed/RPM, background music streaming, voice countdowns,
/// and smooth volume fading.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool _initialized = false;
  bool _available = false;

  double _musicVolume = 0.7;
  double _sfxVolume = 0.85;

  SoundHandle? _musicHandle;
  AudioSource? _musicSource;
  String? _currentMusicPath;

  SoundHandle? _engineHandle;

  // Cached sound sources for zero-latency playback
  final Map<String, AudioSource> _cachedSources = {};

  bool get isAvailable => _available;
  bool get isInitialized => _initialized;

  /// Initializes the SoLoud audio engine.
  Future<bool> init() async {
    if (_initialized) return _available;
    _initialized = true;

    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init();
      }
      _available = soloud.isInitialized;
      return _available;
    } catch (e) {
      if (kDebugMode) {
        print(
          'AudioManager: Audio hardware not available ($e). Running in silent fallback mode.',
        );
      }
      _available = false;
      return false;
    }
  }

  /// Sets the master volumes.
  void setVolumes({double? music, double? sfx}) {
    if (music != null) {
      _musicVolume = music.clamp(0.0, 1.0);
      if (_available && _musicHandle != null) {
        try {
          SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
        } catch (_) {}
      }
    }
    if (sfx != null) {
      _sfxVolume = sfx.clamp(0.0, 1.0);
      if (_available && _engineHandle != null) {
        try {
          SoLoud.instance.setVolume(_engineHandle!, _sfxVolume * 0.75);
        } catch (_) {}
      }
    }
  }

  Future<AudioSource?> _loadSource(String assetPath) async {
    if (!_available) return null;
    if (_cachedSources.containsKey(assetPath)) {
      return _cachedSources[assetPath];
    }
    try {
      final source = await SoLoud.instance.loadAsset(assetPath);
      _cachedSources[assetPath] = source;
      return source;
    } catch (_) {
      return null;
    }
  }

  /// Plays a single one-shot sound effect.
  Future<SoundHandle?> playSfx(
    String assetPath, {
    double volumeScale = 1.0,
    double speed = 1.0,
  }) async {
    if (!_available || _sfxVolume <= 0) return null;
    try {
      final source = await _loadSource(assetPath);
      if (source == null) return null;
      final handle = SoLoud.instance.play(
        source,
        volume: (_sfxVolume * volumeScale).clamp(0.0, 1.0),
      );
      if (speed != 1.0) {
        SoLoud.instance.setRelativePlaySpeed(handle, speed);
      }
      return handle;
    } catch (_) {
      return null;
    }
  }

  // --- UI Sounds -------------------------------------------------------------

  Future<void> playUiTap() =>
      playSfx('assets/audio/sfx/ui/click1.ogg', volumeScale: 0.7);

  Future<void> playUiSelect() =>
      playSfx('assets/audio/sfx/ui/select_001.ogg', volumeScale: 0.8);

  Future<void> playUiBack() =>
      playSfx('assets/audio/sfx/ui/back_001.ogg', volumeScale: 0.7);

  Future<void> playUiConfirm() =>
      playSfx('assets/audio/sfx/ui/confirmation_001.ogg', volumeScale: 0.9);

  // --- Voice & Countdown -----------------------------------------------------

  Future<void> playCountdownVoice(int count) async {
    if (count == 3) {
      await playSfx('assets/audio/voice/3.ogg', volumeScale: 1.0);
    } else if (count == 2) {
      await playSfx('assets/audio/voice/2.ogg', volumeScale: 1.0);
    } else if (count == 1) {
      await playSfx('assets/audio/voice/1.ogg', volumeScale: 1.0);
    }
  }

  Future<void> playCountdownGo() async {
    await playSfx('assets/audio/voice/go.ogg', volumeScale: 1.0);
  }

  // --- Race SFX --------------------------------------------------------------

  Future<void> playBoostSfx() async {
    await playSfx(
      'assets/audio/sfx/scifi/spaceEngine_003.ogg',
      volumeScale: 1.0,
      speed: 1.2,
    );
  }

  Future<void> playItemPickup() async {
    await playSfx('assets/audio/sfx/digital/powerUp1.ogg', volumeScale: 0.85);
  }

  Future<void> playItemUse() async {
    await playSfx(
      'assets/audio/sfx/scifi/laserRetro_004.ogg',
      volumeScale: 0.9,
    );
  }

  Future<void> playVictoryFanfare() async {
    await playSfx(
      'assets/audio/music/jingles/jingles_HIT00.ogg',
      volumeScale: 1.0,
    );
    await playSfx('assets/audio/sfx/engine/crowd-cheer.mp3', volumeScale: 0.8);
  }

  // --- Engine Loop with Pitch Shifting ---------------------------------------

  Future<void> startEngineLoop({String? customLoop}) async {
    if (!_available) return;
    final loopPath = customLoop ?? 'assets/audio/sfx/engine/engine-idle-a.mp3';
    try {
      stopEngineLoop();
      final source = await _loadSource(loopPath);
      if (source == null) return;
      _engineHandle = SoLoud.instance.play(
        source,
        volume: (_sfxVolume * 0.6).clamp(0.0, 1.0),
        looping: true,
      );
      SoLoud.instance.setRelativePlaySpeed(_engineHandle!, 0.85);
    } catch (_) {}
  }

  /// Dynamically pitch shifts the engine loop according to normalized speed (0..1).
  void updateEnginePitch(double speedRatio, {bool boosting = false}) {
    if (!_available || _engineHandle == null) return;
    try {
      // Idle at 0.85x speed, top speed at 1.65x speed, boost at 2.1x speed.
      final pitch =
          0.85 + (speedRatio.clamp(0.0, 1.35) * 0.8) + (boosting ? 0.45 : 0.0);
      SoLoud.instance.setRelativePlaySpeed(_engineHandle!, pitch);
      final vol = (_sfxVolume * (0.5 + math.min(1.0, speedRatio) * 0.3)).clamp(
        0.0,
        1.0,
      );
      SoLoud.instance.setVolume(_engineHandle!, vol);
    } catch (_) {}
  }

  void stopEngineLoop() {
    if (!_available || _engineHandle == null) return;
    try {
      SoLoud.instance.stop(_engineHandle!);
      _engineHandle = null;
    } catch (_) {}
  }

  // --- Background Music (BGM) -----------------------------------------------

  Future<void> playMusic(String assetPath, {bool loop = true}) async {
    if (!_available) return;
    if (_currentMusicPath == assetPath && _musicHandle != null) return;

    try {
      await stopMusic();
      final source = await SoLoud.instance.loadAsset(assetPath);
      _musicSource = source;
      _currentMusicPath = assetPath;
      _musicHandle = SoLoud.instance.play(
        source,
        volume: _musicVolume,
        looping: loop,
      );
    } catch (_) {}
  }

  Future<void> playMenuMusic() =>
      playMusic('assets/audio/music/menu-racing.ogg');

  Future<void> playRaceMusic() =>
      playMusic('assets/audio/music/race-winning-the-race.ogg');

  Future<void> stopMusic() async {
    if (!_available) return;
    if (_musicHandle != null) {
      try {
        SoLoud.instance.stop(_musicHandle!);
      } catch (_) {}
      _musicHandle = null;
    }
    if (_musicSource != null) {
      try {
        await SoLoud.instance.disposeSource(_musicSource!);
      } catch (_) {}
      _musicSource = null;
    }
    _currentMusicPath = null;
  }

  /// Disposes all audio resources.
  Future<void> dispose() async {
    if (!_available) return;
    await stopMusic();
    stopEngineLoop();
    for (final source in _cachedSources.values) {
      try {
        await SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _cachedSources.clear();
  }
}
