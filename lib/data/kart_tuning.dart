import 'package:dashkart/data/models.dart';

/// The driving numbers a kart actually races on.
///
/// Every stat on a [Kart] card used to be decoration: the race scene drove
/// one set of hard-coded constants no matter which kart was selected, so two
/// karts with a three-point speed difference between them drove identically,
/// and the HUD's own "top speed" readout was a number the kart could never
/// reach. A stat the player can read and compare has to be a stat the kart is
/// driven by, so the conversion happens exactly once, here, and the race
/// scene, the bot pace, the HUD readout and `track_shape_test` all read the
/// same instance.
///
/// Units are the race scene's: world units per second, per second squared, or
/// radians per second. [kmhPerWorldUnit] converts the first to the figure the
/// HUD shows.
class KartTuning {
  const KartTuning({
    required this.topSpeed,
    required this.acceleration,
    required this.turnRate,
    required this.grip,
    required this.driftGrip,
    required this.driftTurnBonus,
    required this.mass,
    required this.brakeDecel,
    required this.highSpeedTurnLoss,
  });

  /// Flat out, before any boost, in world units per second.
  final double topSpeed;

  /// How hard it pulls away from a standing start, in units/s².
  final double acceleration;

  /// Peak yaw rate at full lock, radians per second.
  final double turnRate;

  /// Sideways grip in units/s² — how fast the tyres cancel a slide. The
  /// single most important number for how a kart holds a line.
  final double grip;

  /// Grip while drifting. Deliberately a fraction of [grip]: a drift is a
  /// controlled slide, so the back end has to let go.
  final double driftGrip;

  /// Extra yaw rate a drift buys, as a multiplier on [turnRate].
  final double driftTurnBonus;

  /// Rigid-body mass. A heavier kart shoves a lighter one aside in a bump
  /// and is itself barely moved.
  final double mass;

  /// Braking deceleration, units/s².
  final double brakeDecel;

  /// Fraction of [turnRate] traded away at full speed, keeping a kart calm
  /// flat out instead of twitchy. Heavier, faster karts give up more.
  final double highSpeedTurnLoss;

  /// Multiplies [topSpeed] while a turbo burns. Constant across karts so a
  /// boost always feels like the same event.
  static const boostMultiplier = 1.45;

  /// Seconds a collected turbo lasts.
  static const boostDuration = 2.2;

  /// Seconds a drift-charged mini-turbo lasts. Shorter than a pickup's, since
  /// it is earned every corner rather than found.
  static const miniTurboDuration = 1.3;

  /// World units per second → km/h for the HUD readout. Chosen so a
  /// mid-field kart reads a little under 200 km/h flat out, which is the
  /// register an arcade racer's dial is expected to sit in. Cosmetic: it
  /// scales the number on screen, never how the kart drives.
  static const kmhPerWorldUnit = 11.0;

  /// Top speed as the HUD reports it.
  double get topSpeedKmh => topSpeed * kmhPerWorldUnit;

  /// The tightest circle this kart can hold at full lock, flat out, in world
  /// units. A corner tighter than this cannot be got round at all, which is
  /// what makes it the figure `track_shape_test` holds every circuit above.
  double get minimumTurnRadius =>
      topSpeed / (turnRate * (1 - highSpeedTurnLoss));

  /// The same while a turbo is burning — a corner tighter than this has to be
  /// taken off boost.
  double get boostingTurnRadius =>
      (topSpeed * boostMultiplier) / (turnRate * (1 - highSpeedTurnLoss));

  /// Derives the driving numbers from a kart's card.
  ///
  /// Each stat is 1-10 and maps to its own range, so the five axes on the
  /// card are five genuinely different things to feel:
  ///
  /// * **speed** sets how fast the kart runs out of acceleration.
  /// * **acceleration** sets how quickly it gets there, and how well it
  ///   recovers from a crash.
  /// * **handling** sets yaw rate — how sharply it can be pointed.
  /// * **drift** sets how much extra rotation a drift buys and how little
  ///   grip it gives up, so a drift-heavy kart carries speed through a
  ///   corner a stiff one has to brake for.
  /// * **weight** sets mass, braking, and how much steering is given up at
  ///   speed: a heavy kart wins every bump and pays for it in the corners.
  factory KartTuning.of(Kart kart) {
    double stat(KartStat s) => kart.stat(s).toDouble().clamp(1.0, 10.0);

    final speed = stat(KartStat.speed);
    final accel = stat(KartStat.acceleration);
    final handling = stat(KartStat.handling);
    final drift = stat(KartStat.drift);
    final weight = stat(KartStat.weight);

    // 0..1 position within the 1-10 stat range.
    double norm(double v) => (v - 1) / 9;

    return KartTuning(
      // 14.6 .. 19.4 u/s — about 160 to 215 km/h on the HUD.
      topSpeed: 14.6 + norm(speed) * 4.8,
      // 7.5 .. 15.5 u/s²: a standing start to top speed in ~2.4s at the top
      // of the range, ~1.3s slower at the bottom.
      acceleration: 7.5 + norm(accel) * 8.0,
      // 1.85 .. 2.65 rad/s at full lock.
      turnRate: 1.85 + norm(handling) * 0.8,
      // 34 .. 50 u/s² of lateral bite.
      grip: 34.0 + norm(handling) * 16.0,
      // A drift lets go of between 55% and 80% of the tyres' hold; a
      // drift-specialist keeps more of it, so its slide stays catchable.
      driftGrip: (34.0 + norm(handling) * 16.0) * (0.20 + norm(drift) * 0.25),
      // 1.25x .. 1.70x yaw while drifting.
      driftTurnBonus: 1.25 + norm(drift) * 0.45,
      // 0.85 .. 1.45 — multiplies Rapier's own density-derived mass.
      mass: 0.85 + norm(weight) * 0.6,
      // 26 .. 18 u/s²: heavier stops worse.
      brakeDecel: 26.0 - norm(weight) * 8.0,
      // 0.34 .. 0.52 of the turn rate given up flat out.
      highSpeedTurnLoss: 0.34 + norm(weight) * 0.18,
    );
  }
}
