/// The render budget the race scene is built and drawn to.
///
/// This used to be a label and a sentence of prose with nothing behind it:
/// the setting persisted, the description promised render scales and particle
/// counts, and the scene drew at one hard-coded quality regardless. Every
/// field here is now read by `RaceScene`, so the three tiers are three
/// genuinely different frame costs.
///
/// Lives in its own file rather than beside the settings screen so the race
/// scene can depend on the tier without depending on a screen.
enum GraphicsTier {
  low(
    label: 'Low',
    renderScale: 0.6,
    shadows: false,
    shadowCascades: 1,
    bloom: false,
    roadSegments: 64,
    propStride: 8,
    pickupCount: 3,
    speedLines: false,
    fogDensity: 0.004,
  ),
  medium(
    label: 'Medium',
    renderScale: 0.78,
    shadows: true,
    shadowCascades: 2,
    bloom: true,
    roadSegments: 96,
    propStride: 4,
    pickupCount: 4,
    speedLines: true,
    fogDensity: 0.006,
  ),
  high(
    label: 'High',
    renderScale: 1.0,
    shadows: true,
    shadowCascades: 3,
    bloom: true,
    roadSegments: 128,
    propStride: 3,
    pickupCount: 5,
    speedLines: true,
    fogDensity: 0.006,
  );

  const GraphicsTier({
    required this.label,
    required this.renderScale,
    required this.shadows,
    required this.shadowCascades,
    required this.bloom,
    required this.roadSegments,
    required this.propStride,
    required this.pickupCount,
    required this.speedLines,
    required this.fogDensity,
  });

  final String label;

  /// Fraction of the device's real resolution the 3D view is rasterised at.
  /// Phones render at 2.5-3.5x device pixel ratio and the raster thread is
  /// what janks first, so this is the single biggest lever available.
  final double renderScale;

  final bool shadows;

  /// Cascades in the shadow map. More means crisper shadows further out, at
  /// the cost of a shadow pass per cascade.
  final int shadowCascades;

  final bool bloom;

  /// Road pieces laid round the lap. Fewer means a visibly more faceted
  /// circuit, so this only drops on the low tier.
  final int roadSegments;

  /// Place a scenery prop every this many road segments. Higher is sparser.
  final int propStride;

  /// Turbo orbs on the circuit. Kept near-constant because it is a gameplay
  /// quantity as much as a visual one.
  final int pickupCount;

  /// Whether the screen-space speed streaks are drawn over the scene.
  final bool speedLines;

  final double fogDensity;

  /// Shown under the quality picker, generated from the real numbers above so
  /// the description cannot drift away from what the tier actually does.
  String get detail {
    final parts = <String>[
      'Render ${(renderScale * 100).round()}%',
      shadows ? 'shadows ($shadowCascades cascades)' : 'no shadows',
      if (bloom) 'bloom',
      '$roadSegments road segments',
      if (speedLines) 'speed streaks',
    ];
    return parts.join(' · ');
  }
}
