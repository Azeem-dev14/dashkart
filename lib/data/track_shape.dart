import 'dart:math' as math;

/// The plan view of a circuit's centre-line.
///
/// Every track used to share one hard-coded loop, so the five circuits
/// differed only in colour — the same corners in the same order, which is
/// what made them read as one track wearing five skins. Each one now has its
/// own geometry: a different size, a different number of corners, and a
/// different tightest corner, so they drive differently as well as look
/// different.
///
/// The centre-line is a radius that varies with the angle round the lap:
///
/// ```
/// r(a) = radius * (1 + lobe*sin(lobes*a) + detail*sin(detailLobes*a + phase))
/// ```
///
/// [lobes] sets how many corners the lap has and [lobe] how hard they bite;
/// the optional second harmonic adds kinks along the straights. Because the
/// radius is a single value per angle, the loop can never cross itself.
///
/// The amplitudes are not free-hand numbers. Curvature grows roughly with
/// `lobe * lobes^2`, so a characterful-looking lap is very easily tighter
/// than the kart can physically turn — at which point the player simply
/// cannot get round. Each [lobe] below was solved for a target tightest
/// corner, checked against the driving model's own full-lock turn radius
/// (about 13.4 world units at top speed and 19.5 while boosting), and
/// `track_shape_test.dart` holds every circuit to that.
class TrackShape {
  const TrackShape({
    required this.radius,
    required this.lobe,
    required this.lobes,
    this.detail = 0,
    this.detailLobes = 0,
    this.detailPhase = 0,
  });

  /// Mean distance of the centre-line from the circuit's centre, in world
  /// units. Sets how long a lap is.
  final double radius;

  /// How far the lap deforms from a plain circle, as a fraction of [radius].
  final double lobe;

  /// Corners per lap.
  final int lobes;

  /// An optional faster ripple, for circuits that want kinks rather than
  /// clean sweeps. Zero [detailLobes] turns it off.
  final double detail;
  final int detailLobes;
  final double detailPhase;

  /// The centre-line at lap fraction [t], as world `(x, z)`.
  (double, double) pointAt(double t) {
    final a = t * math.pi * 2;
    var scale = 1 + lobe * math.sin(lobes * a);
    if (detailLobes != 0) {
      scale += detail * math.sin(detailLobes * a + detailPhase);
    }
    final r = radius * scale;
    return (r * math.cos(a), r * math.sin(a));
  }

  /// Forward bearing along the centre-line at [t], for orienting road pieces
  /// and karts.
  double headingAt(double t) {
    const eps = 0.002;
    final (ax, az) = pointAt(t - eps);
    final (bx, bz) = pointAt(t + eps);
    return math.atan2(bx - ax, bz - az);
  }

  /// The furthest the centre-line ever gets from the centre — what the ground
  /// plane and the minimap frame have to cover.
  double get maxRadius => radius * (1 + lobe + detail.abs());

  /// Radius of the circle the centre-line locally traces at lap fraction [t],
  /// in world units — the radius of the corner the kart is in right now.
  /// Infinite on a dead straight.
  ///
  /// This is what lets the AI drive the circuit rather than a lap counter: the
  /// fastest a kart can hold a corner of radius `r` with lateral grip `a` is
  /// `sqrt(a * r)`, so a bot that reads this slows for the hairpins and runs
  /// flat out down the straights, exactly as the player has to.
  double curvatureRadiusAt(double t) {
    const h = 1e-4;
    final (x0, z0) = pointAt(t - h);
    final (x1, z1) = pointAt(t);
    final (x2, z2) = pointAt(t + h);
    final dx = (x2 - x0) / (2 * h);
    final dz = (z2 - z0) / (2 * h);
    final ddx = (x2 - 2 * x1 + x0) / (h * h);
    final ddz = (z2 - 2 * z1 + z0) / (h * h);
    final denominator = (dx * ddz - dz * ddx).abs();
    if (denominator <= 1e-9) return double.infinity;
    return (math.pow(dx * dx + dz * dz, 1.5) / denominator).toDouble();
  }

  /// Which way the centre-line bends at [t]: +1 turning one way, -1 the
  /// other, 0 on a straight. The sign of the cross product of the first and
  /// second derivatives, which is what tells a bot which side of the road the
  /// inside of the corner is on.
  double curvatureSignAt(double t) {
    const h = 1e-4;
    final (x0, z0) = pointAt(t - h);
    final (x1, z1) = pointAt(t);
    final (x2, z2) = pointAt(t + h);
    final dx = (x2 - x0) / (2 * h);
    final dz = (z2 - z0) / (2 * h);
    final ddx = (x2 - 2 * x1 + x0) / (h * h);
    final ddz = (z2 - 2 * z1 + z0) / (h * h);
    final cross = dx * ddz - dz * ddx;
    if (cross.abs() <= 1e-9) return 0;
    return cross.sign;
  }

  /// Radius of the tightest corner on the lap, in world units. The kart
  /// cannot get round anything tighter than its own full-lock turn radius,
  /// so this is the number that decides whether a circuit is drivable.
  double tightestCornerRadius({int samples = 1500}) {
    var tightest = double.infinity;
    for (var i = 0; i < samples; i++) {
      final r = curvatureRadiusAt(i / samples);
      if (r < tightest) tightest = r;
    }
    return tightest;
  }

  /// Length of one lap of the centre-line, in world units.
  double lapLength({int samples = 3000}) {
    var total = 0.0;
    var (px, pz) = pointAt(0);
    for (var i = 1; i <= samples; i++) {
      final (x, z) = pointAt(i / samples);
      total += math.sqrt((x - px) * (x - px) + (z - pz) * (z - pz));
      px = x;
      pz = z;
    }
    return total;
  }

  /// One entry per [Catalog.tracks] id. Ordered easy to hard, and the
  /// geometry follows: the early circuits are wide and flat out, the later
  /// ones are tighter and longer.
  static const _shapes = <String, TrackShape>{
    // Wide, flowing, two long sweeps — nothing here needs braking.
    'dash-valley': TrackShape(radius: 46, lobe: 0.171, lobes: 2),
    // The long one: two big hairpins, with kinks down the straights between.
    'desert-rush': TrackShape(
      radius: 50,
      lobe: 0.318,
      lobes: 2,
      detail: 0.05,
      detailLobes: 4,
    ),
    // Longest lap, and the hardest: broad, fast, sweeping bends, with
    // corners tight enough that a kart on boost has to lift for them.
    'frozen-peak': TrackShape(
      radius: 56,
      lobe: 0.207,
      lobes: 3,
      detail: 0.03,
      detailLobes: 5,
      detailPhase: 1,
    ),
  };

  static const fallback = TrackShape(radius: 46, lobe: 0.171, lobes: 2);

  static TrackShape forTrack(String trackId) => _shapes[trackId] ?? fallback;

  static Iterable<MapEntry<String, TrackShape>> get all => _shapes.entries;
}
