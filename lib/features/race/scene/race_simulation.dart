import 'package:dashkart/data/models.dart';

/// A single racer's live state.
class RacerRun {
  RacerRun({
    required this.id,
    required this.isPlayer,
    required this.pace,
    this.lateralLane = 0,
  });

  final String id;
  final bool isPlayer;

  /// Baseline laps-per-second, derived from kart stats.
  final double pace;

  /// Total distance in laps. 2.4 means lap 3, 40% round.
  double progress = 0;

  /// Offset across the road, in world units. Fixed per AI rival so the field
  /// spreads across the open road instead of driving in a single file; the
  /// local player has no lane of their own — [RaceSimulation] reads their
  /// live lateral position from the widget layer instead, since it (unlike
  /// an AI rival's) moves with steering input. Mutable because a multiplayer
  /// opponent is steered too — [RaceScreen] overwrites this every tick from
  /// the network instead of leaving it at its constructor value.
  double lateralLane;

  int get lap => progress.floor() + 1;
}

/// Drives race state — lap/position bookkeeping and bot pace — without
/// being a renderer itself.
///
/// This is the model the HUD reads. The player's own progress and speed are
/// no longer computed here: `RaceScene` drives the player as a real Rapier
/// physics body and reports its projected lap progress + speed back in
/// every physics tick via [applyPlayerTelemetry]. Bots stay exactly as
/// before — a plain pace-per-second formula, unrelated to physics — since
/// they're placed as kinematic obstacles the player's dynamic body collides
/// with, not simulated themselves.
class RaceSimulation {
  RaceSimulation({
    required this.track,
    required this.playerKart,
    required List<Kart> rivals,
  }) : _rivals = List.unmodifiable(rivals) {
    _runs = [
      RacerRun(id: playerKart.id, isPlayer: true, pace: _paceFor(playerKart)),
      for (var i = 0; i < _rivals.length; i++)
        RacerRun(
          id: _rivals[i].id,
          isPlayer: false,
          // Same formula as the player's own pace — every bot on the same
          // kart moves at exactly the same speed as the others, and the
          // fixed lane from laneFor is what keeps the field spread out
          // instead of stacking, not a speed difference.
          pace: _paceFor(_rivals[i]),
          lateralLane: laneFor(i),
        ),
    ];
  }

  /// The fixed lane a rival at roster index [i] drives in, alternating sides
  /// and stepping further out each time so the field fans across the open
  /// road instead of stacking in one line. `RaceScene` places rival models at
  /// this same offset, so this is the one definition both drawing and
  /// collision checks read from.
  static double laneFor(int i) => (i.isEven ? 1 : -1) * (2.0 + i * 0.7);

  final Track track;
  final Kart playerKart;
  final List<Kart> _rivals;

  late final List<RacerRun> _runs;

  double _speed = 0;
  double _boostRemaining = 0;
  Duration _elapsed = Duration.zero;
  Duration? _bestLap;
  Duration _lapStart = Duration.zero;
  bool _finished = false;

  List<RacerRun> get runs => _runs;
  RacerRun get player => _runs.first;
  Duration get elapsed => _elapsed;
  Duration? get bestLap => _bestLap;
  bool get finished => _finished;
  bool get boosting => _boostRemaining > 0;

  /// Top speed in km/h, so the HUD readout is a real derived value.
  double get topSpeed => 120 + playerKart.stat(KartStat.speed) * 9.0;

  double get speedKmh => _speed;

  /// 1-based, best first.
  int get position {
    final sorted = [..._runs]..sort((a, b) => b.progress.compareTo(a.progress));
    return sorted.indexWhere((r) => r.isPlayer) + 1;
  }

  static double _paceFor(Kart kart) {
    final speed = kart.stat(KartStat.speed).toDouble();
    final handling = kart.stat(KartStat.handling).toDouble();
    // Laps per second: a fast kart rounds a lap in roughly 30s.
    return (speed * 0.6 + handling * 0.4) / 220;
  }

  void useBoost() {
    if (_boostRemaining <= 0) _boostRemaining = 2.2;
  }

  /// Integrates [dt] seconds of everything *except* the player: bot pace
  /// advancement, the boost timer, elapsed time, and the finish check
  /// (against whatever `player.progress` was last set to). Call
  /// [applyPlayerTelemetry] separately once per physics tick to drive the
  /// player's own half of this.
  void advance(double dt) {
    if (_finished) return;
    _elapsed += Duration(microseconds: (dt * 1e6).round());

    if (_boostRemaining > 0) _boostRemaining -= dt;

    for (final run in _runs.skip(1)) {
      // No jitter: every bot holds its own constant pace, so bots on the
      // same kart move at exactly the same speed as each other.
      run.progress += run.pace * dt;
    }

    if (player.progress >= track.laps) _finished = true;
  }

  /// Feeds in the player's real physics telemetry from `RaceScene` — its
  /// spline-projected lap progress and current speed — and does the same
  /// lap-crossing bookkeeping [advance] used to do inline before the player
  /// was driven by real physics instead of a scalar formula.
  void applyPlayerTelemetry({
    required double progress,
    required double speedKmh,
  }) {
    if (_finished) return;
    final before = player.lap;
    player.progress = progress;
    _speed = speedKmh;
    if (player.lap != before) {
      final lapTime = _elapsed - _lapStart;
      if (_bestLap == null || lapTime < _bestLap!) _bestLap = lapTime;
      _lapStart = _elapsed;
    }
    if (player.progress >= track.laps) _finished = true;
  }
}
