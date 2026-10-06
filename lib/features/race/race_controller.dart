import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:dashkart/core/audio/audio_manager.dart';
import 'package:dashkart/data/catalog.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/player.dart';
import 'package:dashkart/features/race/scene/race_simulation.dart';
import 'package:dashkart/features/multiplayer/multiplayer_service.dart';
import 'package:dashkart/core/widgets/components.dart';
import 'package:dashkart/features/results/results_screen.dart';

enum RacePhase { countdown, racing, paused, results }

/// Everything about *running* a race: item-box timing, multiplayer
/// telemetry, and the audio side effects those trigger, plus the player's
/// steer/brake input state that `RaceScene` reads to drive a real physics
/// body each frame.
///
/// The simulation tick itself is split across two owners now: [tick] (this
/// class, driven by [RaceScreen]'s [Ticker]) still advances bots, timers,
/// and items, but the player's own movement and kart-vs-kart/kart-vs-wall
/// collisions are resolved by `RaceScene`'s Rapier physics world, which
/// reports back in via [reportPlayerTelemetry] and [onPlayerCollision].
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

  static const _botCount = 3;

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

  /// The player's signed offset from the track spline, in world units, as
  /// last reported by `RaceScene`'s physics projection — kept only to sync
  /// over the network in multiplayer; nothing local reads it any more since
  /// the player's actual position now lives in the physics world, not here.
  double _lateral = 0;

  ItemSlotState _itemState = ItemSlotState.empty;
  ItemSlotState get itemState => _itemState;
  RaceItem? _item;
  RaceItem? get item => _item;
  double _nextItemAt = 0.35;

  RaceResult? _result;
  RaceResult? get result => _result;

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

  /// Guards the delayed item-pickup callback below against firing — and
  /// calling [notifyListeners] — after [RaceScreen] has disposed this
  /// controller, the same way the old code checked `State.mounted`.
  bool _disposed = false;

  RaceSimulation _newSim() {
    final mp = multiplayer;
    if (mp != null) {
      // Exactly one rival — the human opponent — and no AI filler.
      return RaceSimulation(
        track: Catalog.trackById(mp.trackId),
        playerKart: player.kart,
        rivals: [Catalog.kartById(mp.opponent.kartId)],
      );
    }
    return RaceSimulation(
      track: player.track,
      playerKart: player.kart,
      // Cycles through the roster rather than filtering out the player's own
      // kart: with Catalog.karts currently down to one entry, excluding it
      // would leave zero bots. RaceSimulation already varies each bot's pace
      // with jitter, so sharing a kart with the field reads as fine as it
      // does in any kart racer with a small roster.
      rivals: List.generate(
        _botCount,
        (i) => Catalog.karts[i % Catalog.karts.length],
      ),
    );
  }

  /// Re-derives [sim] from the player's current kart/track — only while
  /// still on the countdown, before anything has actually raced, since
  /// [RaceScreen] re-reads [player] (an `InheritedNotifier`) on every
  /// dependency change and a race already under way must never be reset out
  /// from under the driver.
  void refreshSimIfIdle() {
    if (_phase != RacePhase.countdown) return;
    _sim = _newSim();
  }

  void setSteer(double value) => _steer = value;

  void setBraking(bool value) => _braking = value;

  void setDrifting(bool value) {
    _drifting = value;
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

  /// Integrates one frame of everything *except* the player's own movement:
  /// bots, the boost timer, elapsed time, items, and (in multiplayer) the
  /// throttled network push. Returns true once the race has finished, so
  /// [RaceScreen] knows to stop its [Ticker]. The player's real movement and
  /// collisions happen in `RaceScene`'s own physics tick, reported back via
  /// [reportPlayerTelemetry] and [onPlayerCollision] — which can also finish
  /// the race on its own, since physics ticks may land between two calls
  /// here.
  bool tick(Duration now) {
    final dt = _last == Duration.zero
        ? 0.0
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.25) return false;

    _sim.advance(dt);

    final mp = multiplayer;
    if (mp != null) {
      // The sim just advanced this run on its own AI pace above; overwrite it
      // with the real value so the scene reads the opponent's actual live
      // state.
      final opponent = _sim.runs[1];
      opponent.progress = mp.opponent.progress;
      opponent.lateralLane = mp.opponent.lateral;

      _mpWriteAccum += dt;
      if (_mpWriteAccum >= _mpWriteInterval) {
        _mpWriteAccum = 0;
        unawaited(
          mp.updateTelemetry(
            progress: _sim.player.progress,
            lateral: _lateral,
            finished: false,
          ),
        );
      }
    }

    AudioManager.instance.updateEnginePitch(
      _sim.speedKmh / _sim.topSpeed,
      boosting: _sim.boosting || _drifting,
    );

    // Item boxes are picked up at fixed points around the lap.
    if (_itemState == ItemSlotState.empty &&
        _sim.player.progress % 1 >= _nextItemAt) {
      _itemState = ItemSlotState.rolling;
      AudioManager.instance.playItemPickup();
      final gen = _gen;
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (_disposed || gen != _gen) return;
        _item = RaceItem.values[math.Random().nextInt(RaceItem.values.length)];
        _itemState = ItemSlotState.ready;
        notifyListeners();
      });
    }

    if (_sim.finished) {
      _finish();
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Feeds in this physics tick's telemetry from `RaceScene` — the player's
  /// spline-projected lap progress, lateral offset (kept only for the
  /// multiplayer network push above), and speed — and refreshes listeners
  /// immediately rather than waiting for the next outer [tick]. Runs on
  /// `RaceScene`'s own physics clock, not this class's [Ticker]-driven one,
  /// so it can also notice the finish line first; [_finish] is guarded
  /// against running twice for exactly that reason.
  void reportPlayerTelemetry({
    required double progress,
    required double lateral,
    required double speedKmh,
  }) {
    if (_phase != RacePhase.racing) return;
    _lateral = lateral;
    _sim.applyPlayerTelemetry(progress: progress, speedKmh: speedKmh);
    if (_sim.finished) {
      _finish();
      return;
    }
    notifyListeners();
  }

  /// The player's kart just registered a new contact — with a rival or a
  /// track barrier — reported by `RaceScene`'s Rapier collision listener,
  /// which only fires once per contact begin (no manual debouncing needed
  /// the way the old lane-based check required). The speed/velocity change
  /// itself is real physics now, not a scripted scrub; this only drives the
  /// feedback a player can feel.
  void onPlayerCollision() {
    if (_phase != RacePhase.racing) return;
    HapticFeedback.mediumImpact();
  }

  void _finish() {
    // Guards against double-invocation: RaceScene's physics tick and this
    // class's own Ticker-driven tick() can each notice the finish line
    // independently (see reportPlayerTelemetry's doc comment).
    if (_phase != RacePhase.racing) return;
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    AudioManager.instance.playVictoryFanfare();

    // Best-effort: let the opponent's device see the finish immediately
    // rather than waiting up to _mpWriteInterval for the next throttled push.
    final mp = multiplayer;
    if (mp != null) {
      unawaited(
        mp.updateTelemetry(
          progress: _sim.player.progress,
          lateral: _lateral,
          finished: true,
        ),
      );
    }

    final position = _sim.position;
    final best = _sim.bestLap ?? _sim.elapsed;
    // _sim.track, not player.track: in multiplayer the race runs on the
    // host's track, which the guest's own selection need not match.
    final previous = player.bestTime(_sim.track.id);

    player.recordResult(
      trackId: _sim.track.id,
      time: _sim.elapsed,
      position: position,
    );

    _phase = RacePhase.results;
    _result = RaceResult(
      position: position,
      totalRacers: _sim.runs.length,
      time: _sim.elapsed,
      bestLap: best,
      xp: 60 + (9 - position) * 15,
      newRecord: previous == null || _sim.elapsed < previous,
    );
    notifyListeners();
  }

  void pause() {
    if (_phase != RacePhase.racing) return;
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.playUiTap();
    _phase = RacePhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_phase != RacePhase.paused) return;
    AudioManager.instance.playUiConfirm();
    AudioManager.instance.startEngineLoop();
    _last = Duration.zero;
    _phase = RacePhase.racing;
    notifyListeners();
  }

  void restart() {
    AudioManager.instance.playUiConfirm();
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    _gen++;
    _sim = _newSim();
    _braking = false;
    _drifting = false;
    _steer = 0;
    _lateral = 0;
    _itemState = ItemSlotState.empty;
    _item = null;
    _nextItemAt = 0.35;
    _last = Duration.zero;
    _phase = RacePhase.countdown;
    notifyListeners();
  }

  void quit() {
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    AudioManager.instance.playUiBack();
  }

  void useItem() {
    if (_itemState != ItemSlotState.ready) return;
    if (_item == RaceItem.turboCell || _item == RaceItem.warpDash) {
      _sim.useBoost();
      AudioManager.instance.playBoostSfx();
    } else {
      AudioManager.instance.playItemUse();
    }
    HapticFeedback.mediumImpact();
    _itemState = ItemSlotState.empty;
    _item = null;
    _nextItemAt = 0.2 + math.Random().nextDouble() * 0.6;
    notifyListeners();
  }

  @override
  void dispose() {
    AudioManager.instance.stopEngineLoop();
    AudioManager.instance.stopMusic();
    // Whichever way the race is left — pause-menu Quit, or any of the
    // results screen's buttons — the session's lifetime ends here, exactly
    // once, since [RaceScreen] disposes this controller on every exit path.
    multiplayer?.leave();
    multiplayer?.dispose();
    _disposed = true;
    super.dispose();
  }
}
