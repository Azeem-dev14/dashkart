import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/core/feedback/haptics.dart';
import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/features/race/race_telemetry.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';
import 'package:dashkart/features/results/results_screen.dart';

enum RacePhase { countdown, racing, paused, results }

/// Everything about *running* a race: the AI field's clock, item and drift
/// timing, multiplayer telemetry, the audio side effects those trigger, and
/// the player's steer/brake/drift input state that `RaceScene` reads to drive
/// a real physics body each frame.
///
/// The simulation tick is split across two owners: [tick] (this class, driven
/// by [RaceScreen]'s [Ticker]) advances bots, timers and items, while the
/// player's own movement and collisions are resolved by `RaceScene`'s Rapier
/// physics world, which reports back in via [reportTelemetry] and
/// [onPlayerCollision]. Where 3D is unavailable the split collapses: [tick]
/// drives the player too, through
/// [RaceSimulation.advancePlayerKinematically], so the race is still a race.
///
/// [RaceScreen] owns only the [Ticker] (that needs a `vsync`, which is
/// inherently a widget concern) and forwards frames to [tick]; everything
/// else here is plain state a widget can listen to and drive, with no
/// `BuildContext` or widget dependency of its own.
class RaceController extends ChangeNotifier {
  RaceController({required this.player, required this.multiplayer}) {
    _sim = _newSim();
  }

  final PlayerState player;

  /// Non-null for a live 1v1 race — the sole rival becomes the human
  /// opponent instead of AI, mirrored from the network every tick instead of
  /// advancing on its own pace.
  final MultiplayerSession? multiplayer;

  bool get isMultiplayer => multiplayer != null;

  /// Rivals in a solo race: with the player, a field of three.
  static const _botCount = 2;

  /// Seconds since the opponent's telemetry was last pushed to the network —
  /// pushed at ~10Hz rather than every frame, since a room only needs to be
  /// current enough to look live, not frame-perfect.
  static const _mpWriteInterval = 0.1;

  late RaceSimulation _sim;
  RaceSimulation get sim => _sim;

  RacePhase _phase = RacePhase.countdown;
  RacePhase get phase => _phase;

  Duration _last = Duration.zero;

  bool _braking = false;
  bool get braking => _braking;
  bool _drifting = false;
  bool get drifting => _drifting;
  double _steer = 0;
  double get steer => _steer;

  /// Live telemetry from `RaceScene`'s physics body — drift charge, wrong-way
  /// state and the rest, forwarded to the HUD as-is.
  RaceTelemetry _telemetry = RaceTelemetry.zero;
  RaceTelemetry get telemetry => _telemetry;

  /// True once the 3D scene has reported it cannot build, at which point
  /// [tick] takes over driving the player itself. Until then the controller
  /// deliberately does *not* move the kart, because the physics world is
  /// about to.
  bool _kinematicFallback = false;

  ItemSlotState _itemState = ItemSlotState.empty;
  ItemSlotState get itemState => _itemState;

  RaceResult? _result;
  RaceResult? get result => _result;

  /// The last overtake or place lost, for the HUD's callout. Cleared once it
  /// has been on screen long enough to read.
  String? _flash;
  String? get flash => _flash;

  /// Bumped on every restart so a stray delayed item-pickup callback from the
  /// race being restarted over can't clobber the new run's state. Also used
  /// by [RaceScreen] as `RaceScene`'s key: the physics world and the kart's
  /// live position live inside that widget's `State`, which Flutter would
  /// otherwise keep across a restart rebuild — leaving the kart wherever it
  /// physically ended up on the last attempt instead of back at the start
  /// line. Changing the key forces a clean remount.
  int get generation => _gen;
  int _gen = 0;

  double _mpWriteAccum = 0;
  double _flashRemaining = 0;

  RaceSimulation _newSim() {
    final mp = multiplayer;
    if (mp != null) {
      // Exactly one rival — the human opponent — and no AI filler.
      final sim = RaceSimulation(
        track: Catalog.trackById(mp.trackId),
        playerKart: player.kart,
        playerName: player.name,
        rivals: [Catalog.kartById(mp.opponent.kartId)],
        rivalNames: [mp.opponent.name],
        networkOpponents: true,
      );
      // Start the opponent in the lane opposite ours, where their kart will
      // actually be, rather than on top of us until their first update lands.
      final opponent = sim.runs[1];
      opponent.progress = 0;
      opponent.lateralLane = RaceSimulation.multiplayerStartLane(
        isHost: mp.role != MultiplayerRole.host,
      );
      return sim;
    }
    // The field is drawn from the karts the player has *not* selected, so a
    // race is against different machinery rather than three copies of the
    // player's own kart. With a roster this size there are always enough;
    // the modulo is what keeps it correct if the roster ever shrinks.
    final field = Catalog.karts.where((k) => k.id != player.kart.id).toList();
    final roster = field.isEmpty ? Catalog.karts : field;
    return RaceSimulation(
      track: player.track,
      playerKart: player.kart,
      playerName: player.name,
      rivals: List.generate(_botCount, (i) => roster[i % roster.length]),
    );
  }

  /// Re-derives [sim] from the player's current kart/track — only while
  /// still on the countdown, before anything has actually raced, since
  /// [RaceScreen] re-reads [player] on every dependency change and a race
  /// already under way must never be reset out from under the driver.
  void refreshSimIfIdle() {
    if (_phase != RacePhase.countdown) return;
    _sim = _newSim();
  }

  void setSteer(double value) => _steer = value;

  void setBraking(bool value) => _braking = value;

  void setDrifting(bool value) {
    if (_drifting == value) return;
    _drifting = value;
    notifyListeners();
  }

  /// Switches to driving the player here instead of waiting on physics
  /// telemetry that is never going to arrive. Called by [RaceScreen] when
  /// `RaceScene` reports it could not build — no Flutter GPU, or a scene
  /// that failed to load.
  void useKinematicFallback() {
    if (_kinematicFallback) return;
    _kinematicFallback = true;
    notifyListeners();
  }

  void onCountdownBeat(int beat) {
    if (beat >= 0 && beat <= 2) {
      AudioManager.instance.playCountdownVoice(3 - beat);
    }
  }

  void startRacing() {
    AudioManager.instance.playCountdownGo();
    AudioManager.instance.startEngineLoop();
    AudioManager.instance.playRaceMusic();
    _last = Duration.zero;
    _phase = RacePhase.racing;
    notifyListeners();
  }

  /// Integrates one frame. Returns true once the race has finished, so
  /// [RaceScreen] knows to stop its [Ticker].
  bool tick(Duration now) {
    final dt = _last == Duration.zero
        ? 0.0
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    // A frame this long means the app was suspended or the device stalled.
    // Integrating it would teleport the whole field; dropping it costs one
    // frame of motion.
    if (dt <= 0 || dt > 0.25) return false;

    _sim.advance(dt);

    // Without a physics world there is nothing else to move the player, so
    // this is where they are driven from.
    if (_kinematicFallback) {
      _sim.advancePlayerKinematically(dt, steer: _steer, braking: _braking);
      _telemetry = RaceTelemetry(
        progress: _sim.player.progress,
        lateral: _sim.player.lateralLane,
        speedKmh: _sim.speedKmh,
        driftCharge: 0,
        drifting: false,
        wrongWay: false,
      );
    }

    final mp = multiplayer;
    if (mp != null) {
      // The sim just advanced this run on its own AI pace above; overwrite it
      // with the real value so the scene reads the opponent's actual live
      // state.
      final opponent = _sim.runs[1];
      opponent.progress = mp.opponent.progress;
      opponent.lateralLane = mp.opponent.lateral;
      // Their device says when they have crossed the line. If that leaves
      // nobody still racing, the race is over for us too.
      if (mp.opponent.finished) _sim.markFinished(opponent);

      _mpWriteAccum += dt;
      if (_mpWriteAccum >= _mpWriteInterval) {
        // Subtracted rather than zeroed, so the push rate does not drift
        // with the frame time.
        _mpWriteAccum -= _mpWriteInterval;
        unawaited(
          mp.updateTelemetry(
            progress: _sim.player.progress,
            lateral: _telemetry.lateral,
            finished: false,
          ),
        );
      }
    }

    AudioManager.instance.updateEnginePitch(
      _sim.speedKmh / _sim.topSpeed,
      boosting: _sim.boosting,
    );

    _updateFlash(dt);

    if (_sim.finished) {
      _finish();
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Expires the transient callout once it has been up long enough to read.
  /// (Only the mini-turbo shows one now; overtakes and lost places are not
  /// announced.)
  void _updateFlash(double dt) {
    if (_flashRemaining <= 0) return;
    _flashRemaining -= dt;
    if (_flashRemaining <= 0) _flash = null;
  }

  /// Feeds in this physics tick's telemetry from `RaceScene`. Runs on
  /// `RaceScene`'s own physics clock, so it can notice the finish line first;
  /// [_finish] is guarded against running twice for exactly that reason.
  void reportTelemetry(RaceTelemetry telemetry) {
    if (_phase != RacePhase.racing) return;
    _telemetry = telemetry;
    _sim.applyPlayerTelemetry(
      progress: telemetry.progress,
      speedKmh: telemetry.speedKmh,
    );
    if (_sim.finished) {
      _finish();
      return;
    }
    // No notifyListeners here: [tick] runs every frame the race is live and
    // notifies once itself. Notifying from the physics callback as well
    // rebuilt the whole race screen twice a frame for no fresher picture.
  }

  /// The player's kart just registered a new contact — with a rival or a
  /// track barrier — reported by `RaceScene`'s Rapier collision listener,
  /// which only fires once per contact begin. The speed change itself is real
  /// physics, not a scripted scrub; this only drives the feedback a player
  /// can feel.
  void onPlayerCollision() {
    if (_phase != RacePhase.racing) return;
    Haptics.medium();
    AudioManager.instance.playImpact();
  }

  /// A drift held to full charge and released. The one boost in the game the
  /// player earns through driving rather than finds on the road, which is why
  /// it is shorter than a collected turbo.
  void onDriftBoost() {
    if (_phase != RacePhase.racing) return;
    _sim.useBoost(duration: KartTuning.miniTurboDuration);
    AudioManager.instance.playDriftBoost();
    Haptics.light();
    _flash = 'MINI TURBO';
    _flashRemaining = 1.0;
    notifyListeners();
  }

  void _finish() {
    // Guards against double-invocation: RaceScene's physics tick and this
    // class's own Ticker-driven tick() can each notice the finish line
    // independently (see reportTelemetry's doc comment).
    if (_phase != RacePhase.racing) return;
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();

    final position = _sim.position;
    final best = _sim.bestLap ?? _sim.elapsed;

    // The race can end around the player: once every other racer has
    // finished it is over, whether or not they have. They are then placed
    // behind everyone who did finish, by how far they got.
    final playerFinished = _sim.player.finishTime != null;
    final lapsDone = _sim.player.progress.floor().clamp(0, _sim.track.laps);

    if (position == 1) {
      AudioManager.instance.playVictoryFanfare();
    } else {
      AudioManager.instance.playRaceOver();
    }

    // Best-effort: let the opponent's device see the finish immediately
    // rather than waiting up to _mpWriteInterval for the next throttled push.
    final mp = multiplayer;
    if (mp != null) {
      unawaited(
        mp.updateTelemetry(
          progress: _sim.player.progress,
          lateral: _telemetry.lateral,
          finished: playerFinished,
        ),
      );
    }

    // _sim.track, not player.track: in multiplayer the race runs on the
    // host's track, which the guest's own selection need not match.
    final reward = player.recordResult(
      trackId: _sim.track.id,
      time: _sim.elapsed,
      position: position,
      // Laps actually completed, so a race that ended early pays only for
      // the distance driven.
      laps: lapsDone,
      completed: playerFinished,
      // A 1v1 against a friend is not the single-player ladder; paying
      // trophies for it would make the unlock schedule trivially farmable.
      ranked: !isMultiplayer,
    );

    _phase = RacePhase.results;
    _result = RaceResult(
      position: position,
      totalRacers: _sim.runs.length,
      time: _sim.elapsed,
      bestLap: best,
      trophies: reward.trophies,
      xp: reward.xp,
      level: reward.level,
      levelledUp: reward.levelledUp,
      unlocked: reward.unlocked,
      newRecord: reward.newRecord,
      trackName: _sim.track.name,
      didFinish: playerFinished,
      standings: [
        for (final run in _sim.order)
          RaceStanding(
            name: run.name,
            isPlayer: run.isPlayer,
            laps: run.progress.clamp(0, _sim.track.laps.toDouble()),
          ),
      ],
    );
    notifyListeners();
  }

  void pause() {
    if (_phase != RacePhase.racing) return;
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.duckMusic(true);
    AudioManager.instance.playUiTap();
    // A paused race must not keep the throttle held: resuming with a button
    // the player long since let go of is the classic pause-menu bug.
    _braking = false;
    _drifting = false;
    _steer = 0;
    _phase = RacePhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_phase != RacePhase.paused) return;
    AudioManager.instance.playUiConfirm();
    AudioManager.instance.duckMusic(false);
    AudioManager.instance.startEngineLoop();
    _last = Duration.zero;
    _phase = RacePhase.racing;
    notifyListeners();
  }

  /// Restarts on the same circuit. [track] re-targets it, which is what the
  /// results screen's NEXT RACE uses to roll straight into the next circuit
  /// without a trip back through the menus.
  void restart({Track? track}) {
    AudioManager.instance.playUiConfirm();
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    AudioManager.instance.duckMusic(false);
    if (track != null) player.selectTrack(track);
    _gen++;
    _sim = _newSim();
    _braking = false;
    _drifting = false;
    _steer = 0;
    _telemetry = RaceTelemetry.zero;
    _itemState = ItemSlotState.empty;
    _result = null;
    _flash = null;
    _flashRemaining = 0;
    _last = Duration.zero;
    _mpWriteAccum = 0;
    _phase = RacePhase.countdown;
    notifyListeners();
  }

  void quit() {
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    AudioManager.instance.duckMusic(false);
    AudioManager.instance.playUiBack();
  }

  /// The player's kart drove through a turbo pickup on the track. Holds one
  /// turbo at a time — a second orb while one is already stored is ignored.
  void collectTurbo() {
    if (_phase != RacePhase.racing || _itemState != ItemSlotState.empty) return;
    _itemState = ItemSlotState.ready;
    AudioManager.instance.playItemPickup();
    Haptics.light();
    notifyListeners();
  }

  void useItem() {
    if (_phase != RacePhase.racing || _itemState != ItemSlotState.ready) return;
    _sim.useBoost();
    AudioManager.instance.playBoostSfx();
    Haptics.medium();
    _itemState = ItemSlotState.empty;
    notifyListeners();
  }

  /// Fraction of the way to a mini-turbo, 0..1 — the HUD's drift meter.
  double get driftCharge => _telemetry.driftCharge;

  @override
  void dispose() {
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    AudioManager.instance.duckMusic(false);
    // Whichever way the race is left — pause-menu Quit, or any of the
    // results screen's buttons — the session's lifetime ends here, exactly
    // once, since [RaceScreen] disposes this controller on every exit path.
    multiplayer?.leave();
    multiplayer?.dispose();
    super.dispose();
  }
}
