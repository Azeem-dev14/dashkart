import 'dart:math' as math;

/// Whether a kart moving at ([vx], [vz]) is driving *against* the circuit, on
/// a stretch of road whose direction of travel is [heading] — the bearing of
/// the spline in the direction laps are counted, as `TrackShape.headingAt`
/// reports it.
///
/// Laps run in the direction of increasing spline position, and the grid
/// faces that way, so driving correctly means the velocity points along the
/// heading. It is the wrong way only when the velocity points clearly
/// *against* it, and only while actually moving: a kart spun round and
/// nearly stationary after a crash is pointing the wrong way but is not yet
/// going that way.
///
/// The first version of this check had the sign backwards and warned a player
/// who was driving correctly, while staying silent if they reversed.
bool isGoingWrongWay({
  required double heading,
  required double vx,
  required double vz,
  double minSpeed = 3.0,
  double threshold = 0.35,
}) {
  final speed = math.sqrt(vx * vx + vz * vz);
  if (speed <= minSpeed) return false;
  final alongTrack = (vx * math.sin(heading) + vz * math.cos(heading)) / speed;
  return alongTrack < -threshold;
}

/// One physics tick's worth of the player's state, as measured from the live
/// rigid body.
///
/// This used to be three positional doubles on a callback, which meant every
/// new thing the HUD wanted to show — a drift charge, a wrong-way warning —
/// either widened that signature at four call sites or got smuggled in
/// through a second callback. Grouping it keeps the race scene the single
/// authority on what is physically happening and lets the controller forward
/// it wholesale.
class RaceTelemetry {
  const RaceTelemetry({
    required this.progress,
    required this.lateral,
    required this.speedKmh,
    required this.driftCharge,
    required this.drifting,
    required this.wrongWay,
  });

  /// Total distance in fractional laps — 2.4 means lap 3, 40% round.
  final double progress;

  /// Signed offset from the track spline in world units, kept for the
  /// multiplayer telemetry push.
  final double lateral;

  final double speedKmh;

  /// 0..1 of the way to a mini-turbo. Reaches 1 only while [drifting].
  final double driftCharge;

  /// The kart is actually sliding, not merely holding the drift button — a
  /// drift needs speed and steering angle, so the button alone charges
  /// nothing.
  final bool drifting;

  /// The kart is pointed back down the circuit.
  final bool wrongWay;

  static const zero = RaceTelemetry(
    progress: 0,
    lateral: 0,
    speedKmh: 0,
    driftCharge: 0,
    drifting: false,
    wrongWay: false,
  );
}
