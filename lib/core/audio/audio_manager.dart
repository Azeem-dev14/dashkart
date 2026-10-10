import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Centralized audio for DashKart, over `flutter_soloud`.
///
/// Low-latency one-shots, an engine loop pitched by RPM, streamed music with
/// ducking, and the whole thing silenced while the app is in the background.
///
/// Every cue is built from the sounds that actually ship in `assets/audio/`.
/// That set is small and deliberately pruned, so where a distinct cue was
/// needed and no file existed for it, the cue is an existing sample played at
/// a different rate — a low, slow `click` is a crash thump, a fast `powerUp`
/// is an overtake chime. That is a real technique rather than a shortcut, and
/// it is why [playSfx] takes a [speed].
///
/// Every public method is safe to call when audio is unavailable (no
/// hardware, a widget test, a failed init): each one returns early, so no
/// caller has to guard.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool _initialized = false;
  bool _available = false;

  double _musicVolume = 0.7;
  double _sfxVolume = 0.85;

  /// Music is pulled down rather than stopped while the pause menu is up, so
  /// resuming does not restart the track from the top.
  static const _duckFactor = 0.25;
  bool _ducked = false;

  SoundHandle? _musicHandle;
  AudioSource? _musicSource;
  String? _currentMusicPath;

  SoundHandle? _engineHandle;

  /// True while the app is backgrounded. Everything is paused rather than
  /// stopped, so returning to the app resumes mid-lap exactly where it was.
  bool _suspended = false;

  // Cached sound sources for zero-latency playback.
  final Map<String, AudioSource> _cachedSources = {};

  /// In-flight loads, so two near-simultaneous plays of the same cue share
  /// one decode instead of racing to populate the cache twice.
  final Map<String, Future<AudioSource?>> _pendingLoads = {};

  // --- Asset paths ---------------------------------------------------------
  // Named rather than inlined at the call sites, so `audio_test.dart` can
  // check every one of them resolves to a file that actually ships.

  static const uiTap = 'assets/audio/sfx/ui/click1.ogg';
  static const uiSelect = 'assets/audio/sfx/ui/select_001.ogg';
  static const uiBack = 'assets/audio/sfx/ui/back_001.ogg';
  static const uiConfirm = 'assets/audio/sfx/ui/confirmation_001.ogg';
  static const voiceOne = 'assets/audio/voice/1.ogg';
  static const voiceTwo = 'assets/audio/voice/2.ogg';
  static const voiceThree = 'assets/audio/voice/3.ogg';
  static const voiceGo = 'assets/audio/voice/go.ogg';
  static const sfxEngineWhoosh = 'assets/audio/sfx/scifi/spaceEngine_003.ogg';
  static const sfxPowerUp = 'assets/audio/sfx/digital/powerUp1.ogg';
  static const sfxJingle = 'assets/audio/music/jingles/jingles_HIT00.ogg';
  static const sfxCrowd = 'assets/audio/sfx/engine/crowd-cheer.mp3';
  static const engineLoop = 'assets/audio/sfx/engine/engine-idle-a.mp3';
  static const musicMenu = 'assets/audio/music/menu-racing.ogg';
  static const musicRace = 'assets/audio/music/race-winning-the-race.ogg';

  /// Every asset this manager can ask for — what the audio test iterates.
  static const allAssets = <String>[
    uiTap,
    uiSelect,
    uiBack,
    uiConfirm,
    voiceOne,
    voiceTwo,
    voiceThree,
    voiceGo,
    sfxEngineWhoosh,
    sfxPowerUp,
    sfxJingle,
    sfxCrowd,
    engineLoop,
    musicMenu,
    musicRace,
  ];

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
        debugPrint(
          'AudioManager: audio hardware not available ($e). '
          'Running in silent fallback mode.',
        );
      }
      _available = false;
      return false;
    }
  }

  /// Sets the master volumes.
  void setVolumes({double? music, double? sfx}) {
    if (music != null) _musicVolume = music.clamp(0.0, 1.0);
    if (sfx != null) _sfxVolume = sfx.clamp(0.0, 1.0);
    if (!_available) return;
    _apply(_musicHandle, _effectiveMusicVolume);
    _apply(_engineHandle, _sfxVolume * 0.6);
  }

  double get _effectiveMusicVolume =>
      _musicVolume * (_ducked ? _duckFactor : 1.0);

  void _apply(SoundHandle? handle, double volume) {
    if (handle == null) return;
    try {
      SoLoud.instance.setVolume(handle, volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<AudioSource?> _loadSource(String assetPath) {
    final cached = _cachedSources[assetPath];
    if (cached != null) return Future.value(cached);
    return _pendingLoads.putIfAbsent(assetPath, () async {
      try {
        final source = await SoLoud.instance.loadAsset(assetPath);
        _cachedSources[assetPath] = source;
        return source;
      } catch (_) {
        return null;
      } finally {
        _pendingLoads.remove(assetPath);
      }
    });
  }

  /// Plays a single one-shot sound effect.
  ///
  /// [speed] is a playback-rate multiplier, which shifts pitch with it — how
  /// several of the cues below are made distinct from the same sample.
  Future<SoundHandle?> playSfx(
    String assetPath, {
    double volumeScale = 1.0,
    double speed = 1.0,
  }) async {
    if (!_available || _suspended || _sfxVolume <= 0) return null;
    try {
      final source = await _loadSource(assetPath);
      // The await above can outlive a suspend, so re-check rather than
      // firing a sound into a backgrounded app.
      if (source == null || _suspended) return null;
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

  // --- UI ------------------------------------------------------------------

  Future<void> playUiTap() => playSfx(uiTap, volumeScale: 0.7);

  Future<void> playUiBack() => playSfx(uiBack, volumeScale: 0.7);

  Future<void> playUiConfirm() => playSfx(uiConfirm, volumeScale: 0.9);

  // --- Countdown -----------------------------------------------------------

  Future<void> playCountdownVoice(int count) => switch (count) {
    3 => playSfx(voiceThree),
    2 => playSfx(voiceTwo),
    1 => playSfx(voiceOne),
    _ => Future<void>.value(),
  };

  Future<void> playCountdownGo() => playSfx(voiceGo);

  // --- Race ----------------------------------------------------------------

  Future<void> playBoostSfx() =>
      playSfx(sfxEngineWhoosh, volumeScale: 1.0, speed: 1.2);

  /// The mini-turbo a drift pays out. Shorter and brighter than a collected
  /// turbo's, so the two are tellable apart with the engine loud.
  Future<void> playDriftBoost() =>
      playSfx(sfxEngineWhoosh, volumeScale: 0.8, speed: 1.65);

  Future<void> playItemPickup() => playSfx(sfxPowerUp, volumeScale: 0.85);

  /// Clipping a barrier or another kart. A low, slow click reads as a thump,
  /// which is the one impact sound the shipped set has no sample for.
  Future<void> playImpact() => playSfx(uiTap, volumeScale: 1.0, speed: 0.42);

  /// Crossing the line onto a new lap.
  Future<void> playLapComplete() =>
      playSfx(uiSelect, volumeScale: 0.7, speed: 1.25);

  /// Starting the last lap — the same cue a place lower and slower, so it
  /// lands as an announcement rather than as another lap.
  Future<void> playFinalLap() =>
      playSfx(sfxPowerUp, volumeScale: 0.9, speed: 0.78);

  /// Won the race.
  Future<void> playVictoryFanfare() async {
    await playSfx(sfxJingle);
    await playSfx(sfxCrowd, volumeScale: 0.8);
  }

  /// Finished, but not first. The same jingle pitched down, which is a
  /// result rather than a celebration.
  Future<void> playRaceOver() =>
      playSfx(sfxJingle, volumeScale: 0.8, speed: 0.72);

  // --- Engine loop ---------------------------------------------------------

  Future<void> startEngineLoop({String? customLoop}) async {
    if (!_available || _suspended) return;
    final loopPath = customLoop ?? engineLoop;
    try {
      stopEngineLoop();
      final source = await _loadSource(loopPath);
      if (source == null || _suspended) return;
      final handle = _engineHandle = SoLoud.instance.play(
        source,
        volume: (_sfxVolume * 0.6).clamp(0.0, 1.0),
        looping: true,
      );
      SoLoud.instance.setRelativePlaySpeed(handle, _idlePitch);
    } catch (_) {}
  }

  static const _idlePitch = 0.85;

  /// Pitch shifts the engine loop by normalized speed (0..1).
  void updateEnginePitch(double speedRatio, {bool boosting = false}) {
    final handle = _engineHandle;
    if (!_available || handle == null || _suspended) return;
    // A zero or non-finite ratio arrives whenever top speed has not been
    // established yet; treat it as idle rather than letting a NaN reach the
    // engine, which silences the voice for the rest of the race.
    final ratio = speedRatio.isFinite ? speedRatio.clamp(0.0, 1.35) : 0.0;
    try {
      // Idle at 0.85x, top speed at 1.65x, boost adds 0.45x on top.
      final pitch = _idlePitch + ratio * 0.8 + (boosting ? 0.45 : 0.0);
      SoLoud.instance.setRelativePlaySpeed(handle, pitch);
      _apply(handle, _sfxVolume * (0.5 + math.min(1.0, ratio) * 0.3));
    } catch (_) {}
  }

  void stopEngineLoop() {
    final handle = _engineHandle;
    if (!_available || handle == null) return;
    _engineHandle = null;
    try {
      SoLoud.instance.stop(handle);
    } catch (_) {}
  }

  // --- Music ---------------------------------------------------------------

  Future<void> playMusic(String assetPath, {bool loop = true}) async {
    if (!_available || _suspended) return;
    if (_currentMusicPath == assetPath && _musicHandle != null) return;

    try {
      await stopMusic();
      // Streamed from disk rather than decoded whole into memory: these are
      // minutes-long tracks, and only one plays at a time.
      final source = await SoLoud.instance.loadAsset(
        assetPath,
        mode: LoadMode.disk,
      );
      if (_suspended) {
        await SoLoud.instance.disposeSource(source);
        return;
      }
      _musicSource = source;
      _currentMusicPath = assetPath;
      _musicHandle = SoLoud.instance.play(
        source,
        volume: _effectiveMusicVolume,
        looping: loop,
      );
    } catch (_) {
      _currentMusicPath = null;
    }
  }

  Future<void> playMenuMusic() => playMusic(musicMenu);

  Future<void> playRaceMusic() => playMusic(musicRace);

  /// Pulls the music down without stopping it — for the pause menu, where
  /// restarting the track on every resume would be worse than silence.
  void duckMusic(bool ducked) {
    if (_ducked == ducked) return;
    _ducked = ducked;
    _apply(_musicHandle, _effectiveMusicVolume);
  }

  Future<void> stopMusic() async {
    final handle = _musicHandle;
    final source = _musicSource;
    _musicHandle = null;
    _musicSource = null;
    _currentMusicPath = null;
    if (!_available) return;
    if (handle != null) {
      try {
        SoLoud.instance.stop(handle);
      } catch (_) {}
    }
    if (source != null) {
      try {
        await SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
  }

  // --- App lifecycle -------------------------------------------------------

  /// Silences everything while the app is in the background and brings it
  /// back on return.
  ///
  /// Without this, backgrounding the app during a race left the music and the
  /// engine loop playing over whatever the player switched to — which on
  /// mobile is the single most common complaint a game with audio gets.
  void setSuspended(bool suspended) {
    if (_suspended == suspended) return;
    _suspended = suspended;
    if (!_available) return;
    for (final handle in [_musicHandle, _engineHandle]) {
      if (handle == null) continue;
      try {
        SoLoud.instance.setPause(handle, suspended);
      } catch (_) {}
    }
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
