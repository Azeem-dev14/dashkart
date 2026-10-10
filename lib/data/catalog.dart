import 'package:dashkart/data/models.dart';

/// The DashKart content catalogue.
///
/// One kart — Dash — and three circuits. The kart roster is a
/// deliberate choice, not a gap: [KartTuning] and the unlock rules already
/// support more, so adding one is a catalogue entry and nothing else.
abstract final class Catalog {
  // --- Karts ---------------------------------------------------------------
  static const karts = <Kart>[
    Kart(
      id: 'dash',
      name: 'Dash',
      tagline: 'Flutter\'s mascot, kitted for the grid',
      model: 'dashkart',
      unlock: Starter(),
      stats: {
        KartStat.speed: 6,
        KartStat.acceleration: 7,
        KartStat.handling: 7,
        KartStat.drift: 6,
        KartStat.weight: 6,
      },
    ),
  ];

  // --- Levels --------------------------------------------------------------
  // Three circuits, easy to hard, each a distinct biome. The unlock
  // thresholds are solved against the reward curve in `PlayerState` — see
  // `progression_test.dart`, which checks the ladder is reachable and that
  // nothing is gated behind an unreasonable grind.
  static const tracks = <Track>[
    Track(
      id: 'dash-valley',
      index: 1,
      name: 'Dash Valley',
      environment: 'Grassland',
      difficulty: TrackDifficulty.easy,
      laps: 3,
      unlock: Starter(),
    ),
    Track(
      id: 'desert-rush',
      index: 2,
      name: 'Desert Rush',
      environment: 'Desert canyon',
      difficulty: TrackDifficulty.medium,
      laps: 3,
      unlock: TrophyCount(6),
    ),
    Track(
      id: 'frozen-peak',
      index: 3,
      name: 'Frozen Peak',
      environment: 'Snow and ice',
      difficulty: TrackDifficulty.hard,
      laps: 3,
      unlock: TrophyCount(14),
    ),
  ];

  /// The kart with [id], or the starter kart if nothing matches — a saved
  /// selection naming content that no longer exists must not crash the game
  /// on launch, which `firstWhere` without an `orElse` would.
  static Kart kartById(String id) =>
      karts.firstWhere((k) => k.id == id, orElse: () => karts.first);

  static Track trackById(String id) =>
      tracks.firstWhere((t) => t.id == id, orElse: () => tracks.first);

  /// The circuit after [track] in running order, wrapping back to the first —
  /// what the results screen's NEXT RACE advances to.
  static Track nextTrack(Track track) {
    final i = tracks.indexWhere((t) => t.id == track.id);
    if (i < 0) return tracks.first;
    return tracks[(i + 1) % tracks.length];
  }
}
