import 'dart:math' as math;

import 'package:dashkart/data/kart_tuning.dart';
import 'package:dashkart/data/models.dart';
import 'package:dashkart/data/track_shape.dart';

/// A single racer's live state.
class RacerRun {
  RacerRun({
    required this.id,
    required this.name,
    required this.isPlayer,
    required this.tuning,
    this.skill = 1.0,
    this.progress = 0,
    this.lateralLane = 0,
  });

  final String id;

  /// Shown on the results board and the overtake callout.
  final String name;

  final bool isPlayer;

  /// The driving numbers this racer's kart runs on — the same derivation the
  /// player's own kart gets, so a bot in a faster kart is genuinely faster
  /// rather than assigned a faster number.
  final KartTuning tuning;

  /// Multiplies the pace this racer can actually extract from [tuning].
  /// Below 1 means a driver who is not getting everything out of the kart,
  /// which is how difficulty and per-bot variation are expressed without
  /// lying about the machinery.
  double skill;

  /// Total distance in laps. 2.4 means lap 3, 40% round.
  double progress;

  /// Offset across the road, in world units. Driven towards the inside of
  /// whatever corner the bot is in, so the field takes a racing line instead
  /// of holding a fixed lane round a hairpin; the local player has no lane of
  /// their own — their real position lives in the physics world. Mutable
  /// because a multiplayer opponent is steered too: `RaceController`
  /// overwrites this every tick from the network.
  double lateralLane;

  /// Current speed in world units per second. Only meaningful for bots —
  /// the player's own comes from physics.
  double speed = 0;

  /// When this racer crossed the finish line, on the race clock. Null while
  /// they are still racing. The finishing order is by this, not by distance:
  /// a racer who finished first and then rolled to a stop must still beat one
  /// who finished a moment later and coasted further.
  Duration? finishTime;

  /// Lap the racer is on, 1-based.
  int get lap => progress.floor() + 1;
}

/// Drives race state — lap and position bookkeeping, lap timing, and the AI
/// field — without being a renderer itself.
///
/// This is the model the HUD reads. The player's own progress and speed are
/// not computed here in a 3D race: `RaceScene` drives the player as a real
/// Rapier physics body and reports its projected lap progress plus speed back
/// in every physics tick via [applyPlayerTelemetry]. Where 3D is unavailable,
/// [advancePlayerKinematically] stands in, so the game is still playable
/// rather than a kart that never moves.
///
/// The bots are no longer a constant lap-per-second scalar. Each one drives
/// the circuit's real geometry — braking for the corner it is actually in,
/// running flat out where the road is straight — from the same [KartTuning]
/// the player's kart uses, which is what makes a race against them readable:
/// you catch them in the corners or on the straights depending on what you
/// are driving, instead of watching a number tick up at a fixed rate.
class RaceSimulation {
  RaceSimulation({
    required this.track,
    required this.playerKart,
    required String playerName,
    required List<Kart> rivals,
    List<String>? rivalNames,
    int seed = 0,
    this.networkOpponents = false,
  }) : _rivals = List.unmodifiable(rivals),
       _shape = TrackShape.forTrack(track.id) {
    _lapLength = _shape.lapLength();
    final rng = math.Random(seed == 0 ? track.index * 7919 : seed);
    _runs = [
      RacerRun(
        id: playerKart.id,
        name: playerName,
        isPlayer: true,
        tuning: KartTuning.of(playerKart),
      ),
      for (var i = 0; i < _rivals.length; i++)
        RacerRun(
          id: _rivals[i].id,
          name: rivalNames != null && i < rivalNames.length
              ? rivalNames[i]
              : _botNames[i % _botNames.length],
          isPlayer: false,
          tuning: KartTuning.of(_rivals[i]),
          // Difficulty sets the field's baseline competence; a small
          // deterministic spread on top of it stops the bots arriving at
          // every corner as one indistinguishable block.
          skill: _baseSkillFor(track.difficulty) + rng.nextDouble() * 0.09,
          progress: gridProgressFor(i, _rivals.length),
          lateralLane: laneFor(i),
        ),
    ];
  }

  /// The names the AI field races under. Deliberately short: they appear on
  /// the overtake callout mid-race, where there is no time to read more.
  static const _botNames = ['Nitro', 'Vex', 'Rook', 'Juno', 'Pike'];

  /// How much of their kart's potential the field extracts, per circuit
  /// difficulty. An easy circuit is where a new player learns the controls,
  /// so the field there is beatable while still finishing the race.
  static double _baseSkillFor(TrackDifficulty difficulty) =>
      switch (difficulty) {
        TrackDifficulty.easy => 0.82,
        TrackDifficulty.medium => 0.90,
        TrackDifficulty.hard => 0.96,
      };

  /// How far ahead or behind the player a bot has to be, in fractions of a
  /// lap, before catch-up starts nudging its pace — and the most it is ever
  /// nudged by. Kept small on purpose: a field that visibly rubber-bands to
  /// the player's bumper is more insulting than one that simply beats them.
  static const _catchUpThreshold = 0.06;
  static const _catchUpMax = 0.07;

  /// The lane a rival at roster index [i] starts in, alternating sides and
  /// stepping further out for each pair, so the field fans across the road.
  ///
  /// The lanes are wide on purpose. A kart is under two units across, and the
  /// old lanes (two units out, stepping 0.7) put the rivals' bumpers within a
  /// hand's width of the player's and of each other, so the start was a
  /// scrum. `RaceScene` places rival models at this offset, so this is the one
  /// definition both drawing and collision checks read from.
  static double laneFor(int i) => (i.isEven ? 1 : -1) * (3.4 + (i ~/ 2) * 2.0);

  /// How far up the road, in laps, rival [i] of [count] starts. A staggered
  /// grid: the player is on the line at the back, and each rival is a row
  /// further ahead, so no two karts share a spot however many are racing.
  /// Roughly two to three units per row on the circuits that ship.
  static double gridProgressFor(int i, int count) => 0.006 * (count - i);

  /// The lane each side of a live race starts in. Both karts used to spawn on
  /// the centre line at the same place, so a race began with them overlapping.
  static double multiplayerStartLane({required bool isHost}) =>
      isHost ? -2.5 : 2.5;

  /// Half the drivable road, in world units — how far from the centre-line a
  /// racing line may pull. Matches `RaceScene`'s own barrier placement.
  static const _laneLimit = 5.6;

  final Track track;

  /// True when the rivals are real players on other devices. They are not
  /// driven or judged here: the caller sets their progress from the network
  /// and reports their finish through [markFinished].
  final bool networkOpponents;
  final Kart playerKart;
  final List<Kart> _rivals;
  final TrackShape _shape;

  late final List<RacerRun> _runs;
  late final double _lapLength;

  double _speed = 0;
  double _boostRemaining = 0;
  Duration _elapsed = Duration.zero;
  Duration? _bestLap;
  Duration? _lastLap;
  Duration _lapStart = Duration.zero;
  bool _finished = false;

  /// Cached finishing order, invalidated whenever any progress changes. The
  /// HUD asks for the player's position several times a frame, and sorting a
  /// fresh copy of the field each time was allocating a list per call.
  List<RacerRun>? _order;

  List<RacerRun> get runs => _runs;
  RacerRun get player => _runs.first;
  Duration get elapsed => _elapsed;
  Duration? get bestLap => _bestLap;

  /// Time spent on the lap currently in progress.
  Duration get currentLap => _elapsed - _lapStart;

  bool get finished => _finished;
  bool get boosting => _boostRemaining > 0;

  /// 0..1 of the boost remaining, for the HUD's boost bar.
  double get boostFraction =>
      (_boostRemaining / KartTuning.boostDuration).clamp(0.0, 1.0);

  /// The player kart's driving numbers.
  KartTuning get tuning => player.tuning;

  /// Top speed in km/h, so the HUD readout is a real derived value — and now
  /// genuinely the speed the kart reaches, not a number it never sees.
  double get topSpeed => tuning.topSpeedKmh;

  double get speedKmh => _speed;

  /// Length of one lap of the centre-line, in world units.
  double get lapLength => _lapLength;

  /// Finishing order, best first.
  List<RacerRun> get order {
    final cached = _order;
    if (cached != null) return cached;
    final sorted = [..._runs]..sort(_byStanding);
    return _order = sorted;
  }

  /// Finished racers come first, in the order they finished; everyone still
  /// racing follows, furthest round first.
  static int _byStanding(RacerRun a, RacerRun b) {
    final fa = a.finishTime;
    final fb = b.finishTime;
    if (fa != null && fb != null) return fa.compareTo(fb);
    if (fa != null) return -1;
    if (fb != null) return 1;
    return b.progress.compareTo(a.progress);
  }

  /// 1-based, best first.
  int get position => order.indexWhere((r) => r.isPlayer) + 1;

  /// Starts a boost. [duration] lets a drift-earned mini-turbo be shorter
  /// than a collected turbo without a second timer to keep in step.
  void useBoost({double duration = KartTuning.boostDuration}) {
    // Refreshes rather than stacks: two turbos back to back extend the boost
    // instead of making the kart twice as fast.
    if (duration > _boostRemaining) _boostRemaining = duration;
  }

  /// Fraction of a kart's lateral grip a driver will actually use in a
  /// corner. The grip figure is the *limit* of the tyres, and the circuits
  /// here are gentle enough that `sqrt(grip * r)` at the limit exceeds every
  /// kart's top speed — a bot using all of it would never lift anywhere.
  /// Real drivers corner well inside the limit, and this is that margin.
  static const _comfortableGrip = 0.22;

  /// The speed a kart comfortably holds the corner at lap fraction [t]:
  /// `v = sqrt(a * r)` with `a` a fraction of the kart's grip, capped at its
  /// top speed. Tighter corners and thinner grip both lower it.
  double cornerSpeedLimit(double t, KartTuning kart) {
    final radius = _shape.curvatureRadiusAt(t);
    if (!radius.isFinite) return kart.topSpeed;
    return math.min(
      kart.topSpeed,
      math.sqrt(kart.grip * _comfortableGrip * radius),
    );
  }

  /// Integrates [dt] seconds of everything *except* the player: the AI field,
  /// the boost timer, elapsed time, and the finish check (against whatever
  /// `player.progress` was last set to). Call [applyPlayerTelemetry] or
  /// [advancePlayerKinematically] separately to drive the player's own half.
  void advance(double dt) {
    if (_finished) return;
    _elapsed += Duration(microseconds: (dt * 1e6).round());
    _order = null;

    if (_boostRemaining > 0) {
      _boostRemaining = math.max(0, _boostRemaining - dt);
    }

    if (!networkOpponents) {
      for (final run in _runs.skip(1)) {
        _advanceBot(run, dt);
      }
    }

    _checkFinish();
  }

  /// Records that [run] has finished — how a networked opponent's finish gets
  /// in, since nothing here drives them. Safe to call more than once.
  void markFinished(RacerRun run) {
    if (run.finishTime != null) return;
    run.finishTime = _elapsed;
    _order = null;
    _checkFinish();
  }

  /// Decides whether the race is over.
  ///
  /// It ends when the player finishes, *or* when every other racer already
  /// has. Before, only the player's own finish ended it: the bots never
  /// registered a finish at all and simply kept circling, and a multiplayer
  /// opponent's finish was sent over the network and never read — so a race
  /// whose other racers had all crossed the line carried on regardless.
  void _checkFinish() {
    if (player.progress >= track.laps) {
      player.finishTime ??= _elapsed;
      _order = null;
    }
    final others = _runs.skip(1);
    final everyoneElseDone =
        others.isNotEmpty && others.every((r) => r.finishTime != null);
    if (player.finishTime != null || everyoneElseDone) _finished = true;
  }

  /// One bot, one frame.
  ///
  /// It reads the corner it is in, works out the fastest it could hold that
  /// corner, and accelerates or brakes towards it — then drifts its lane
  /// towards the inside of the bend. Everything it knows comes from the same
  /// [KartTuning] and [TrackShape] the player drives against.
  void _advanceBot(RacerRun run, double dt) {
    final kart = run.tuning;
    final t = run.progress % 1.0;

    // Look a little way up the road rather than at the bumper, so a bot
    // brakes *before* the hairpin instead of in it. The distance scales with
    // speed, the way a real braking point does.
    final lookahead = (run.speed * 0.55 + 6.0) / _lapLength;
    final limit = math.min(
      cornerSpeedLimit(t, kart),
      cornerSpeedLimit((t + lookahead) % 1.0, kart),
    );

    // Catch-up, applied to skill rather than to speed directly, so it is
    // bounded by what the kart can actually do and can never produce a bot
    // travelling faster than its own top speed.
    final gap = player.progress - run.progress;
    final catchUp = gap.abs() <= _catchUpThreshold
        ? 0.0
        : (gap.sign *
                  math.min(_catchUpMax, (gap.abs() - _catchUpThreshold) * 0.25))
              .toDouble();
    // Once over the line a bot stops racing and rolls to a halt, instead of
    // carrying on round the circuit for ever.
    final target = run.finishTime != null
        ? 0.0
        : limit * (run.skill + catchUp).clamp(0.45, 1.0);

    if (run.speed < target) {
      run.speed = math.min(run.speed + kart.acceleration * dt, target);
    } else {
      run.speed = math.max(run.speed - kart.brakeDecel * dt, target);
    }

    run.progress += (run.speed * dt) / _lapLength;
    if (run.finishTime == null && run.progress >= track.laps) {
      run.finishTime = _elapsed;
    }

    // Racing line: pull towards the inside of the bend, holding the starting
    // lane as an offset so the field still fans out rather than converging
    // into one file through every corner.
    final bend = _shape.curvatureSignAt(t);
    final radius = _shape.curvatureRadiusAt(t);
    final commit = radius.isFinite
        ? (1.0 - (radius / 90).clamp(0.0, 1.0))
        : 0.0;
    final lane = laneFor(_runs.indexOf(run) - 1);
    final targetLane = (lane * (1 - commit * 0.25) - bend * commit * 3.2).clamp(
      -_laneLimit,
      _laneLimit,
    );
    // Eased rather than snapped: a bot that teleports across the road reads
    // as a rendering glitch, not as a line.
    run.lateralLane += (targetLane - run.lateralLane) * math.min(1.0, dt * 2.2);
  }

  /// Feeds in the player's real physics telemetry from `RaceScene` — its
  /// spline-projected lap progress and current speed — and does the lap
  /// bookkeeping.
  void applyPlayerTelemetry({
    required double progress,
    required double speedKmh,
  }) {
    if (_finished) return;
    _order = null;
    final before = player.lap;
    player.progress = progress;
    _speed = speedKmh;
    if (player.lap > before) {
      // Only a lap *gained* closes a lap time; reversing back over the line
      // and crossing it again must not record a second-long "lap".
      final lapTime = _elapsed - _lapStart;
      _lastLap = lapTime;
      if (_bestLap == null || lapTime < _bestLap!) _bestLap = lapTime;
      _lapStart = _elapsed;
    } else if (player.lap < before) {
      // Driven backwards over the line: the lap in progress is the one
      // being re-run, so its clock has to go back with it.
      _lapStart = _elapsed - (_lastLap ?? Duration.zero);
    }
    _checkFinish();
  }

  /// Drives the player without a physics world, for devices where Flutter GPU
  /// — and so the whole 3D scene — is unavailable.
  ///
  /// The game used to be unplayable there: the 2D stand-in track rendered,
  /// but the player's progress only ever arrived from physics telemetry, so
  /// the kart never moved and the race could never end. This is the same
  /// arcade model the real scene runs, integrated along the spline instead of
  /// in three dimensions, and it uses the same [KartTuning] — so the kart's
  /// stats still mean what the card says even in the fallback.
  void advancePlayerKinematically(
    double dt, {
    required double steer,
    required bool braking,
  }) {
    if (_finished || dt <= 0) return;
    _order = null;
    final kart = player.tuning;
    final t = player.progress % 1.0;

    // Cornering costs speed here too, but as a soft ceiling the player is
    // pushed back under rather than a wall, so a bad line scrubs speed
    // instead of stopping the kart dead.
    final corner = cornerSpeedLimit(t, kart);
    final ceiling =
        math.min(kart.topSpeed, corner) *
        (boosting ? KartTuning.boostMultiplier : 1.0);

    var speed = _speed / KartTuning.kmhPerWorldUnit;
    if (braking) {
      speed = math.max(0, speed - kart.brakeDecel * dt);
    } else if (speed < ceiling) {
      speed = math.min(ceiling, speed + kart.acceleration * dt);
    } else {
      speed = math.max(ceiling, speed - kart.brakeDecel * 0.5 * dt);
    }

    // Steering moves the kart across the road; running into the barrier
    // scrubs speed, which is what the walls do in the 3D scene.
    final lane =
        player.lateralLane + steer * kart.turnRate * 2.4 * dt * (speed / 6.0);
    if (lane.abs() > _laneLimit) {
      speed *= 0.97;
      player.lateralLane = lane.clamp(-_laneLimit, _laneLimit);
    } else {
      player.lateralLane = lane;
    }

    final before = player.lap;
    player.progress += (speed * dt) / _lapLength;
    _speed = speed * KartTuning.kmhPerWorldUnit;

    if (player.lap > before) {
      final lapTime = _elapsed - _lapStart;
      _lastLap = lapTime;
      if (_bestLap == null || lapTime < _bestLap!) _bestLap = lapTime;
      _lapStart = _elapsed;
    }
    _checkFinish();
  }
}
